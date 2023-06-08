---
layout: post
title: "Implementing Dependency Injection for the redfish-codegen Project"
date: 2023-05-24 17:06:00 -0500
categories: redfish
---

# The redfish-codegen project

At the beginning of this year, I started the [redfish-codegen project][1]. The
aim of this project is to provide a framework for writing [Redfish][2] compliant
services. So far, I have written a code generator in Java, based on
[Swagger][3]. This application generates about 100k lines of Rust, which contain
definitions of traits and structs that are described in the Redfish standard and
associated specifications. All of this compiles to a single Rust crate, called
redfish-codegen. Downstream of this, there is a crate called Seuss, which
provides some components that most (if not all) Redfish services will
need--infrastructure for authentication/authorization, etc.

At first, the interface exposed by redfish-codegen was remarkably simple. Struct
definitions are provided to fulfill the Redfish data model. Take, for example,
the definition of the ComputerSystem.v1_20_0.ComputerSystem entity:

```rust
pub struct ComputerSystem {
    pub odata_id: Id,
    pub actions: Option<Actions>,
    pub asset_tag: Option<String>,
    pub host_name: Option<String>,
    pub uuid: Option<UUID>,
    // ...Other parameters...
}
```

That's it! Operations on this entity are exposed, in a Redfish service, at the
`/redfish/v1/Systems/:id` endpoint, which supports GET, PUT, DELETE and PATCH
operations. The redfish-codegen crate provides a trait to implement these
operations:

```rust
pub trait ComputerSystemDetail {
    // Required methods
    fn get(&self, computer_system_id: String) -> ComputerSystemDetailGetResponse;
    fn put(
        &mut self,
        computer_system_id: String,
        body: ComputerSystem
    ) -> ComputerSystemDetailPutResponse;
    fn delete(
        &mut self,
        computer_system_id: String
    ) -> ComputerSystemDetailDeleteResponse;
    fn patch(
        &mut self,
        computer_system_id: String,
        body: Value
    ) -> ComputerSystemDetailPatchResponse;
}
```

The response data types are all simple enums to indicate the status of the
response:

```rust
pub enum ComputerSystemDetailGetResponse {
    Ok(ComputerSystem),
    Default(Error),
}
```

Some basic parts of the standard, like the presence and validation of the
`OData-Version` header, and authentication and authorization, are called by a
layer of glue code that connects these traits to Routers in `axum-rs`.

This is simple, and that's one of its greatest strengths. But it's also highly
inflexible. What if, as a consumer of this framework, I want to develop an
implementation that needs to know the identity of the authenticated user? This
could be necessary, for example, If I'm proxying this request to an upstream
Redfish service.

This problem is often solved in API design, and in the Rust community, we have a
shining example of a highly flexible solution: the web framework, Axum! Axum
solves this problem by exposing a type-generic interface that supports a
variable number of arguments (zero to sixteen). An abstraction layer wraps the
actual interface of the consumer in a trait, `Handler`, which provides a smooth,
consistent interface for implementing Routers and the other logic that Axum
provides. This is essentially a complicated form of dependency injection.

Axum isn't the only place we've seen this design. It's also in use in the
popular game design engine, Bevy, and a few other places. I even used a tutorial
provided by a game designer to help me understand
[how this works under the hood][4].

## Bringing this design to redfish-codegen

What I want is an interface very similar to the interface of Axum's `Router`.
The user can tack on additional handlers with an interface set by the caller. I
decided I'd start trying to implement this interface:

```rust
let app = Router::new()
    .nest("/redfish/v1/Systems", ComputerSystemCollection::default()
        .read(|| async {
            let model = Model::default();
            QueryResponse::<Model>::from(model)
        })
        .into()
    )
```

This handler doesn't do anything interesting, but it demonstrates the intent. A
`ComputerSystemCollection` object would allow the consumer to tack on a `read`
handler (which translates to the GET request on this object) that returns a
`QueryResponse<Model>`. In this case, `Model` would be an instance of a
`ComputerSystemCollection` component from the Redfish data model, and the
`QueryResponse` wrapper allows the consumer to communicate additional context
about the response to the library, such as the status code of the response. For
now, the handler has no arguments. Here's what I came up with:

```rust
pub struct QueryResponse<T> {
    status: StatusCode,
    value: T,
}

impl<T> From<T> for QueryResponse<T> {
    fn from(value: T) -> Self {
        Self {
            status: StatusCode::OK,
            value,
        }
    }
}

#[derive(Default)]
pub struct ComputerSystemCollection(MethodRouter);

impl ComputerSystemCollection {
    pub fn read<Fn, Fut>(self, handler: Fn) -> Self
    where Fn: FnOnce() -> Fut + Clone + Send + 'static,
    Fut: Future<Output = QueryResponse<Model>> + Send,
    {
        Self(self.0.get(|| async move {
            let handler = handler.clone();
            let response = handler().await;
            (response.status, Json(response.value))
        }))
    }
}

impl Into<Router> for ComputerSystemCollection {
    fn into(self) -> Router {
        Router::new()
            .route("/", self.0.fallback(|| async {
                (StatusCode::METHOD_NOT_ALLOWED,
                Json(redfish_error::one_message(Base::QueryNotSupported.into())))
            }))
    }
}
```

This feels like a pretty fine start. Internally, our `ComputerSystemCollection`
object is responsible for building up a `Router` with user-supplied callbacks,
which we can then tack onto our main application Router with a call to `nest`.
This struct performs impedance matching between the ergonomic interface required
by the user-supplied handlers and the `Handler` trait in Axum--essentially
consuming a semantic interface to expose an HTTP server.

Let's move slowly so as not to become wrapped up in esoteric compiler errors.
First, let's create a new method on our ComputerSystemCollection that will
handle the POST operation:

```rust
pub fn create<Fn, Fut>(self, handler: Fn) -> Self
where Fn: FnOnce(Model) -> Fut + Clone + Send + 'static,
Fut: Future<Output = QueryResponse<Model>> + Send,
{
    Self(self.0.post(|request: Request<Body>| async move {
        let handler = handler.clone();
        let Json(body): Json<Model> = request.extract().await?;
        let response = handler(body).await;
        Ok::<_, JsonRejection>((response.status, Json(response.value)))
    }))
}
```

This isn't _really_ how we want to handle this method. The POST method on this
component should actually receive and return a new ComputerSystem instance, but
we gloss over that detail to prevent unnecessary complexity while we continue to
develop our framework. We'll call this in main like so:

```rust
let app = Router::new()
    .nest("/redfish/v1/Systems", ComputerSystemCollection::default()
        .read(|| async {
            let model = Model::default();
            QueryResponse::<Model>::from(model)
        })
        .create(|model: Model| async {
            event!(Level::INFO, "{}", &serde_json::to_string(&model).unwrap());
            QueryResponse::<Model>::from(model)
        })
        .into()
    )
```

Note the use of `unwrap()`. Let's address that right now, by specifying that the
return type of the user callback must return a `T where T: IntoResponse`. This
is a little bit restricting, but we'll address that in a future blog post. This
is ultimately the most flexible, but it is not the most convenient.

Now that our `create()` emitter takes an argument, let's make it take a
_generic_ argument.

```patch
-    pub fn create<Fn, Fut, R>(self, handler: Fn) -> Self
-    where Fn: FnOnce(Model) -> Fut + Clone + Send + 'static,
+    pub fn create<Fn, Fut, B, R>(self, handler: Fn) -> Self
+    where Fn: FnOnce(B) -> Fut + Clone + Send + 'static,
     Fut: Future<Output = R> + Send,
+    B: FromRequest<(), Body> + Send,
     R: IntoResponse + Send,
     {
         Self(self.0.post(|request: Request<Body>| async move {
             let handler = handler.clone();
-            let Json(body): Json<Model> = request.extract().await?;
-            Ok::<_, JsonRejection>(handler(body).await)
+            let body = match B::from_request(request, &()).await {
+                Ok(value) => value,
+                Err(rejection) => return rejection.into_response(),
+            };
+            handler(body).await.into_response()
         }))
     }
```

And then in `main.rs`:

```patch
-            .create(|model: Model| async {
+            .create(|Json(model): Json<Model>| async {
                 event!(Level::INFO, "{}", &serde_json::to_string(&model).map_err(redfish_map_err)?);
                 Ok::<_, (StatusCode, Json<redfish::Error>)>(Json(model))
             })
```

Note, this _is_ a little bit more verbose. But again, the goal is not
convenience, it's flexibility. We're reducing the overall complexity of
implementation by providing a semantic interface based around reusable entities
that map directly to components in the Redfish data model.

Also note that we explicitly set the `S` and `B` type parameters of
`FromRequest` in the where clause. We can do this, in this case, because we are
in control of the instantiation of the `Router` through our implementation of
`Into<Router> for ComputerSystemCollection`.

For my next trick, I'll turn these into handlers that can take a variable number
of generic arguments! But in order to test that we've done it right, we need one
more handler for proof by induction. Let's use this opportunity to trial the
other feature we're looking to implement here--arbitrary composure of
sub-components. We want our ComputerSystemCollection to also *own* a proxy
object that exposes our ComputerSystem(s):

```patch
diff --git a/di-service/src/computer_system_collection.rs b/di-service/src/computer_system_collection.rs
index b108fb8..f98b6ab 100644
--- a/di-service/src/computer_system_collection.rs
+++ b/di-service/src/computer_system_collection.rs
@@ -29,7 +29,20 @@ where E: std::fmt::Display,
 }
 
 #[derive(Default)]
-pub struct ComputerSystemCollection(MethodRouter);
+pub struct ComputerSystem(MethodRouter);
+
+impl Into<Router> for ComputerSystem {
+    fn into(self) -> Router {
+        Router::new()
+            .route("/", self.0)
+    }
+}
+
+#[derive(Default)]
+pub struct ComputerSystemCollection {
+    collection: MethodRouter,
+    systems: ComputerSystem,
+}
 
 impl ComputerSystemCollection {
     pub fn read<Fn, Fut, R>(self, handler: Fn) -> Self
@@ -37,10 +50,14 @@ impl ComputerSystemCollection {
     Fut: Future<Output = R> + Send,
     R: IntoResponse + Send,
     {
-        Self(self.0.get(|| async move {
-            let handler = handler.clone();
-            handler().await
-        }))
+        let Self { collection, systems } = self;
+        Self {
+            collection: collection.get(|| async move {
+                let handler = handler.clone();
+                handler().await
+            }),
+            systems,
+        }
     }
 
     pub fn create<Fn, Fut, B, R>(self, handler: Fn) -> Self
@@ -49,22 +66,34 @@ impl ComputerSystemCollection {
     B: FromRequest<(), Body> + Send,
     R: IntoResponse + Send,
     {
-        Self(self.0.post(|request: Request<Body>| async move {
-            let handler = handler.clone();
-            let body = match B::from_request(request, &()).await {
-                Ok(value) => value,
-                Err(rejection) => return rejection.into_response(),
-            };
-            handler(body).await.into_response()
-        }))
+        let Self { collection, systems } = self;
+        Self {
+            collection: collection.post(|request: Request<Body>| async move {
+                let handler = handler.clone();
+                let body = match B::from_request(request, &()).await {
+                    Ok(value) => value,
+                    Err(rejection) => return rejection.into_response(),
+                };
+                handler(body).await.into_response()
+            }),
+            systems,
+        }
+    }
+
+    pub fn systems(self, systems: ComputerSystem) -> Self {
+        Self {
+            collection: self.collection,
+            systems,
+        }
     }
 }
 
 impl Into<Router> for ComputerSystemCollection {
     fn into(self) -> Router {
         Router::new()
-            .route("/", self.0.fallback(|| async {
+            .route("/", self.collection.fallback(|| async {
                 (StatusCode::METHOD_NOT_ALLOWED, Json(redfish_error::one_message(Base::OperationNotAllowed.into())))
             }))
+            .nest("/:computer_system", self.systems.into())
     }
 }
\ No newline at end of file
diff --git a/di-service/src/main.rs b/di-service/src/main.rs
index 60895e3..44d9e38 100644
--- a/di-service/src/main.rs
+++ b/di-service/src/main.rs
@@ -23,7 +23,7 @@ use redfish_codegen::models::{computer_system_collection::ComputerSystemCollecti
 
 mod computer_system_collection;
 
-use computer_system_collection::ComputerSystemCollection;
+use computer_system_collection::{ComputerSystemCollection, ComputerSystem};
 use tower_http::trace::TraceLayer;
 use tracing::{event, Level};
 
@@ -59,6 +59,7 @@ async fn main() -> anyhow::Result<()> {
                 event!(Level::INFO, "{}", &serde_json::to_string(&model).map_err(redfish_map_err)?);
                 Ok::<_, (StatusCode, Json<redfish::Error>)>(Json(model))
             })
+            .systems(ComputerSystem::default())
             .into()
         )
         .layer(TraceLayer::new_for_http());
```

That's better. This will allow us to get really fancy with our construction
logic, like being able to separate out large groups of components into factory
functions, and injecting other factories into them to construct dependencies.
When this paradigm is in place throughout redfish-codegen, we will be able to
construct arbitrarily complex services while keeping our functions nice and
small.

Let's quickly add a handler to our new ComputerSystem object to demonstrate a
handler that _should_ require two arguments for the consumer:

```rust
impl ComputerSystem {
    pub fn replace<Fn, Fut, P, B, R>(self, handler: Fn) -> Self
    where Fn: FnOnce(P, B) -> Fut + Clone + Send + 'static,
    Fut: Future<Output = R> + Send,
    P: FromRequestParts<()> + Send,
    B: FromRequest<(), Body> + Send,
    R: IntoResponse,
    {
        Self(self.0.put(|request: Request<Body>| async move {
            let handler = handler.clone();
            let (mut parts, body) = request.into_parts();
            let param = match P::from_request_parts(&mut parts, &()).await {
                Ok(value) => value,
                Err(rejection) => return rejection.into_response(),
            };
            let request = Request::from_parts(parts, body);
            let body = match B::from_request(request, &()).await {
                Ok(value) => value,
                Err(rejection) => return rejection.into_response(),
            };
            handler(param, body).await.into_response()
        }))
    }
}
```

The `replace()` emitter is called on a PUT request, and it should replace the
identified ComputerSystem instance with the provided one. We call it like so:

```rust
.systems(
    ComputerSystem::default().replace(|Path(computer_system): Path<u32>, Json(system): Json<System>| async move {
        event!(Level::INFO, "{}: {}", computer_system, &serde_json::to_string(&system).map_err(redfish_map_err)?);
        Ok::<_, (StatusCode, Json<redfish::Error>)>(Json(system))
    })
)
```

This has identified something we need to remember to be careful about: generic
types that implement `FromRequest` require special treatment, separate from
generic types that implement `FromRequestParts`. That's what makes this a good
example.

There's something annoying about this, though. This handler is responsible for
utilizing _all_ of the path parameters. Unfortunately, that means that
collections like `Certificates` have to know whether they're mounted under a
`Manager`, or a `System`, or whatever else. I think we can do better.
Collections _know_ that they collect subordinate resources, and resources that
can be mounted under a collection _know_ that about themselves.

What if we provided a layered mechanism for handlers to uniquely identify
subordinate resources transparently of the mountpoint?

[1]: https://github.com/AmateurECE/redfish-codegen/
[2]: https://www.dmtf.org/standards/redfish
[3]: https://swagger.io/docs/specification/2-0/what-is-swagger/
[4]: https://promethia-27.github.io/dependency_injection_like_bevy_from_scratch/introductions.html
