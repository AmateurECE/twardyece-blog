---
layout: post
title: "Dependency Injection for redfish-codegen, Part 2"
date: 2023-06-04 14:16:00 -0500
categories: redfish
---

# Recent Updates

When we left last time, we were looking for a solution to the problem that all
hypermedia applications must handle: Locating resources in handlers without
coupling them to the mountpoint of the service. We speculated that the solution
would end up utilizing the hierarchical archiecture popularized by the `tower`
crate.

I played with multiple solutions:

* Receiving a `tower::Layer` as `State` in the wrapping handler to provide
  resources to the user handler.
* Creating a new extractor, `Context`, to pass resources to the user handler.
* Creating a new trait, `FromContextParts`, to extend the suite of Axum
  extractors with some additional behavior, and use this new trait to implement
  an additional "class" of extractor that could pass resources to user handlers.

In the end, I decided not to re-invent the wheel, and discovered that Axum
Middleware could be used to solve the problem at the user's discretion. To
facilitate this, components never have to have a generic member--this allows us
to remove all the trait annotations of the generic types. Let's take a look at
the `ComputerSystem` now:

```rust
#[derive(Default)]
pub struct ComputerSystem(MethodRouter);

impl ComputerSystem {
    pub fn replace<Fn, Fut, P, B, Res>(self, handler: Fn) -> Self
    where
        Fn: FnOnce(P, B) -> Fut + Clone + Send + 'static,
        Fut: Future<Output = Res> + Send,
        P: FromRequestParts<()> + Send,
        B: FromRequest<(), Body> + Send,
        Res: IntoResponse,
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

    pub fn into_router(self) -> Router {
        Router::new().route("/", self.0)
    }
}
```

The use of `into_router` prevents requiring noisy type annotations at the call
site. Now that we've delegated resource location to application implementer, we
can utilize this component like so:

```rust
ComputerSystem::default()
    .replace(
        |Extension(id): Extension<u32>, Json(system): Json<System>| async move {
            event!(
                Level::INFO,
                "id={}, body={}",
                id,
                &serde_json::to_string(&system).map_err(redfish_map_err)?
            );
            Ok::<_, (StatusCode, Json<redfish::Error>)>(Json(system))
        },
    )
    .into_router()
    .route_layer(middleware::from_fn(
        |request: Request<Body>, next: Next<Body>| async {
            let (mut parts, body) = request.into_parts();
            let parameters =
                Path::<HashMap<String, String>>::from_request_parts(
                    &mut parts,
                    &(),
                )
                .await
                .map_err(|rejection| rejection.into_response())
                .and_then(|parameters| {
                    parameters
                        .get("computer_system_id")
                        .ok_or(
                            (
                                StatusCode::BAD_REQUEST,
                                Json("Missing 'computer_system_id' parameter"),
                            )
                                .into_response(),
                        )
                        .and_then(|id| {
                            u32::from_str_radix(id, 10).map_err(|error| {
                                (
                                    StatusCode::BAD_REQUEST,
                                    Json(error.to_string()),
                                )
                                    .into_response()
                            })
                        })
                });
            let id = match parameters {
                Ok(value) => value,
                Err(rejection) => return rejection,
            };

            let mut request = Request::<Body>::from_parts(parts, body);
            request.extensions_mut().insert(id);
            let response = next.run(request).await;
            response
        },
    )),
```

The middleware will add an Extension to the request that the handler can
extract. Since our wrapping handlers aren't doing anything anymore, let's
replace them with simple functions that take a generic handler and dispatch to
functions on `MethodRouter` or `Router`:

```rust
pub fn put<H, T>(self, handler: H) -> Self
where
    H: Handler<T, (), Body>,
    T: 'static,
{
    Self(self.0.put(handler))
}
```

Now, the primary benefit of this entire layer is that the composition of
handlers into `Router`s is automated via semantic components. I also created
the struct `ResourceLocator` to simplify the creation of middleware for resource
location. In `main`, by handling all of the request mutation:

```rust
ComputerSystem::default()
    // Handler setup...
    .into_router()
    .route_layer(ResourceLocator::new(
        "computer_system_id".to_string(),
        service_fn(|id: String| async move {
            u32::from_str_radix(&id, 10).map_err(redfish_map_err)
        }),
    )),
```

The `ResourceLocator` constructs `tower::Service`s (concrete type is
`ResourceLocatorService`) that wrap the Service its constructed with.

Just to make sure this is as scalable as we want it to be, let's create another
collection of resources that can be subordinate to the `ComputerSystem`. Let's
define a `Certificates` collection.

```rust
#[derive(Default)]
pub struct Certificates {
    router: MethodRouter,
    certificates: Option<Router>,
}

impl Certificates {
    pub fn get<H, T>(self, handler: H) -> Self
    where
        H: Handler<T, (), Body>,
        T: 'static,
    {
        let Self {
            router,
            certificates,
        } = self;
        Self {
            router: router.get(handler),
            certificates,
        }
    }

    pub fn certificates(self, certificates: Router) -> Self {
        let Self { router, .. } = self;
        Self {
            router,
            certificates: Some(certificates),
        }
    }

    pub fn into_router(self) -> Router {
        let Self {
            router,
            certificates,
        } = self;
        certificates
            .map_or(Router::default(), |certificates: Router| {
                Router::new().nest("/:certificate_id", certificates)
            })
            .route(
                "/",
                router.fallback(|| async {
                    (
                        StatusCode::METHOD_NOT_ALLOWED,
                        Json(redfish_error::one_message(Base::OperationNotAllowed.into())),
                    )
                }),
            )
    }
}

#[derive(Default)]
pub struct Certificate(MethodRouter);

impl Certificate {
    pub fn get<H, T>(self, handler: H) -> Self
    where
        H: Handler<T, (), Body>,
        T: 'static,
    {
        Self(self.0.get(handler))
    }

    pub fn into_router(self) -> Router {
        Router::new().route("/", self.0)
    }
}
```

To glue these together, we'll of course add a `certificates` member to the
`ComputerSystem` struct, and a corresponding method.

```rust
pub fn certificates(self, router: Router) -> Self {
    Self {
        router: self.router,
        certificates: Some(router),
    }
}
```

## Fixing ResourceLocators

Now, let's update `ResourceLocator` to be ergonomic for composable middleware.
Instead of taking a `Service`, let's just take an asynchronous function. We'll
accept two signatures:

1. `FnOnce(T) -> R, where T: FromStr`
2. `FnOnce(T1, T2) ->, where T1: FromRequestParts<()>, T2: FromStr`

The `T: FromStr` argument allows us to inject a more ergonomic type into the
callback, instead of just `String`. The second option allows us to use
extensions from parent middleware for locating subordinate resources.

First, we define a `trait ResourceHandler`. Concrete types will implement this
trait to expose a uniform interface to the `ResourceLocatorService` (the Service
that's composed by the `ResourceLocator`):

```rust
#[async_trait]
pub trait ResourceHandler {
    async fn call(
        self,
        request: Request<Body>,
        parameter_name: String,
    ) -> Result<Request<Body>, Response>;
}
```

Now, we create a "proxy object" that we can implement this trait on. Later,
we'll provide a mechanism to construct these objects from closures:

```rust
#[derive(Clone)]
pub struct FunctionResourceHandler<Input, F> {
    f: F,
    marker: PhantomData<fn() -> Input>,
}
```

Using `fn() -> Input` will allow us not to require that `Input: Send` later.
Now, let's implement this trait for our two signatures:

```rust
async fn get_request_parameter<T>(
    mut parts: &mut Parts,
    parameter_name: &String,
) -> Result<T, Response>
where
    T: FromStr,
{
    Path::<HashMap<String, String>>::from_request_parts(&mut parts, &())
        .await
        .map_err(|rejection| rejection.into_response())
        .and_then(|parameters| {
            parameters
                .get(parameter_name)
                .ok_or(redfish_map_err(
                    "Missing '".to_string() + parameter_name + "' parameter",
                ))
                .map(|parameter| parameter.clone())
        })
        .and_then(|value| T::from_str(&value).map_err(redfish_map_err_no_log))
}

#[async_trait]
impl<T1, T2, Fn, Fut, R> ResourceHandler for FunctionResourceHandler<(T1, T2), Fn>
where
    T1: FromRequestParts<()> + Send,
    T2: FromStr + Send,
    Fn: FnOnce(T1, T2) -> Fut + Send,
    Fut: Future<Output = Result<R, Response>> + Send,
    R: Send + Sync + 'static,
{
    async fn call(
        self,
        request: Request<Body>,
        parameter_name: String,
    ) -> Result<Request<Body>, Response> {
        let (mut parts, body) = request.into_parts();
        let extractor = T1::from_request_parts(&mut parts, &())
            .await
            .map_err(|rejection| rejection.into_response())?;
        let parameter = get_request_parameter::<T2>(&mut parts, &parameter_name)
            .await
            .and_then(|value| Ok((self.f)(extractor, value)))?
            .await?;

        let mut request = Request::<Body>::from_parts(parts, body);
        request.extensions_mut().insert(parameter);
        Ok(request)
    }
}

#[async_trait]
impl<T, Fn, Fut, R> ResourceHandler for FunctionResourceHandler<(T,), Fn>
where
    T: FromStr + Send,
    Fn: FnOnce(T) -> Fut + Send,
    Fut: Future<Output = Result<R, Response>> + Send,
    R: Send + Sync + 'static,
{
    async fn call(
        self,
        request: Request<Body>,
        parameter_name: String,
    ) -> Result<Request<Body>, Response> {
        let (mut parts, body) = request.into_parts();
        let parameter = get_request_parameter(&mut parts, &parameter_name)
            .await
            .and_then(|value| Ok((self.f)(value)))?
            .await?;

        let mut request = Request::<Body>::from_parts(parts, body);
        request.extensions_mut().insert(parameter);
        Ok(request)
    }
}
```

These implementations pull the path parameters from the request, isolate the one
parameter named by `request_name`, and then call the user-provided function to
construct an object of type `R` from the parameter. Then we insert that object
into the requests extensions, and return the request!

To utilize this in our middleware, we'll add a trait that allows us to convert
select matching closures to a `FunctionResourceHandler`:

```rust
pub trait IntoResourceHandler<Input> {
    type ResourceHandler;
    fn into_resource_handler(self) -> Self::ResourceHandler;
}

impl<T1, T2, F, R> IntoResourceHandler<(T1, T2)> for F
where
    T1: FromRequestParts<()>,
    T2: FromStr,
    F: FnOnce(T1, T2) -> R,
{
    type ResourceHandler = FunctionResourceHandler<(T1, T2), F>;

    fn into_resource_handler(self) -> Self::ResourceHandler {
        Self::ResourceHandler {
            f: self,
            marker: PhantomData::default(),
        }
    }
}

impl<T, F, R> IntoResourceHandler<(T,)> for F
where
    T: FromStr,
    F: FnOnce(T) -> R,
{
    type ResourceHandler = FunctionResourceHandler<(T,), F>;

    fn into_resource_handler(self) -> Self::ResourceHandler {
        Self::ResourceHandler {
            f: self,
            marker: PhantomData::default(),
        }
    }
}
```

I love this trick. By specifying the generic type `Input` for our trait, we can
get around the orphan rule to effectively provide "more than one" blanket
implementation.

We just want the user to pass in a closure, so let's update our
`ResourceLocator` and `ResourceLocatorService` to accept these:

```rust
#[derive(Clone)]
pub struct ResourceLocator<R>
where
    R: ResourceHandler + Clone,
{
    parameter_name: String,
    handler: R,
}

impl<R> ResourceLocator<R>
where
    R: ResourceHandler + Clone,
{
    pub fn new<I>(
        parameter_name: String,
        handler: impl IntoResourceHandler<I, ResourceHandler = R>,
    ) -> Self {
        Self {
            parameter_name,
            handler: handler.into_resource_handler(),
        }
    }
}

impl<R> tower::Layer<Route> for ResourceLocator<R>
where
    R: ResourceHandler + Clone,
{
    type Service = ResourceLocatorService<R>;

    fn layer(&self, inner: Route) -> Self::Service {
        ResourceLocatorService {
            inner,
            handler: self.handler.clone(),
            parameter_name: self.parameter_name.clone(),
        }
    }
}

#[derive(Clone)]
pub struct ResourceLocatorService<R>
where
    R: ResourceHandler,
{
    inner: Route,
    handler: R,
    parameter_name: String,
}

impl<R> tower::Service<Request<Body>> for ResourceLocatorService<R>
where
    R: ResourceHandler + Send + Sync + Clone + 'static,
{
    type Response = Response;

    type Error = Infallible;

    type Future = Pin<Box<dyn Future<Output = Result<Self::Response, Self::Error>> + Send>>;

    fn poll_ready(
        &mut self,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, request: Request<Body>) -> Self::Future {
        let mut inner = self.inner.clone();
        let parameter_name = self.parameter_name.clone();
        let handler = self.handler.clone();
        let handler = async move {
            let request = match handler.call(request, parameter_name).await {
                Ok(value) => value,
                Err(rejection) => return Ok::<_, Infallible>(rejection),
            };
            let response = inner.call(request).await;
            response
        };
        Box::pin(handler)
    }
}
```

Finished! And in `main`:

```rust
ComputerSystem::default()
    .certificates(
        Certificates::default()
            .get(|| async { Json(CertificateCollection::default()) })
            .certificates(
                Certificate::default()
                    .get(|Extension(system): Extension<u32>, Extension(id): Extension<String>| async move {
                        event!(Level::INFO, "computer_system_id={}, certificate_id={}", system, id);
                    })
                    .into_router()
                    .route_layer(ResourceLocator::new(
                        "certificate_id".to_string(),
                        |Extension(system): Extension<u32>, id: String| async move {
                            event!(Level::INFO, "in middleware, system is {}", system);
                            Ok::<_, Response>(id)
                        }
                    )),
            )
            .into_router(),
    )
    .into_router()
    .route_layer(ResourceLocator::new(
        "computer_system_id".to_string(),
        |id: u32| async move { Ok::<_, Response>(id) },
    )),
```

Now, when I run
`curl -k https://localhost:3001/redfish/v1/Systems/1/Certificates/2`, we see
that both our middleware and our handler have access to the resource created by
the parent middleware!

```
2023-06-08T11:51:13.032272Z  INFO request{method=GET uri=https://localhost:3001/redfish/v1/Systems/1/Certificates/2 version=HTTP/2.0}: di_service: in middleware, system is 1
2023-06-08T11:51:13.032304Z  INFO request{method=GET uri=https://localhost:3001/redfish/v1/Systems/1/Certificates/2 version=HTTP/2.0}: di_service: computer_system_id=1, certificate_id=2
```

Success! In the next part of this series, we'll explore the last problem that
needs solving before we can write the code generation: handling authentication.
