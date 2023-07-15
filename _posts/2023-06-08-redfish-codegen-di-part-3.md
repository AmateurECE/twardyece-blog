---
layout: post
title: "Dependency Injection for redfish-codegen, Part 3"
date: 2023-06-04 14:16:00 -0500
categories: redfish
---

# Redfish Authentication

As a reminder, the `seuss` crate (part of the `redfish-codegen` project)
provides the `RedfishAuth` extractor, which allows you to specify the required
privilege for completing the request, and provides an abstraction layer for
plugging in different authentication mechanisms. The only one that's currently
implemented is authentication via Linux-PAM.

This extractor is currently used by the routing layer, which--as you recall from
Part 1--connects the generated traits in the `redfish-codegen` crate to the
Axum handlers in the routing layer. This relies on the `Router`'s state type, to
implement `AsRef<dyn AuthenticateRequest>`, where the `AuthenticateRequest`
trait will actually go out and perform the authentication and authorization,
using whatever means were provided at construction time--basic, session,
Linux-PAM, whatever.

We want to keep all of this. As you may recall, in our last post, our components
became simple dispatch layers to compose `Router`s. We are going to revert back
to the "wrapping handler" mode of operation, so that we can perform the authxn
without requiring the user to specify a `RedfishAuth` extractor in their
handler. This is also going to require us to handle the problem of `Router`
state, which has been totally unsupported up until this point.

We require the state generic type parameter on each component to be the same for
all sub-components. I don't think it would be possible to do it any other way,
but this is also consistent with Axum, and flexible enough--the caller can
choose to assign state at a per-component level, or at the top level of the
service.

```rust
#[derive(Default)]
pub struct Certificate<S>(MethodRouter<S>)
where
    S: Clone;

impl<S> Certificate<S>
where
    S: AsRef<dyn AuthenticateRequest> + Clone + Send + Sync + 'static,
{
    pub fn get<H, T>(self, handler: H) -> Self
    where
        H: Handler<T, S, Body>,
        T: 'static,
    {
        Self(self.0.get(
            |auth: RedfishAuth<ConfigureComponents>,
             State(state): State<S>,
             mut request: Request<Body>| async {
                request.extensions_mut().insert(auth.user);
                handler.call(request, state).await
            },
        ))
    }
}
```

We specify the required privilege there, `ConfigureComponents`. This is a
standard privilege called out in the Redfish data model. This route on this
component requires this privilege, per the data model's privilege mapping,
version 1.3.1. In the future, we can expand to accommodate OEM privileges.

This also triggered the _only_ change I've had to make to the existing
infrastructure in the `seuss` crate. Previously, there was no way to get the
identity of the authenticated user from the `RedfishAuth` extractor. As of
commit [#f6ac857779f9][1], this extractor contains an
`Option<AuthenticatedUser>`, which contains the identity of the authenticated
user except in cases where the service does not require authentication. We pass
this to the user handler via an extension.

Let's add a new type to implement the NoAuth policy--that is, every request is
accepted, and no credentials are authenticated:

```rust
#[derive(Clone, Default)]
pub struct NoAuth;

impl AuthenticateRequest for NoAuth {
    fn authenticate_request(
        &self,
        _parts: &mut Parts,
    ) -> Result<Option<seuss::auth::AuthenticatedUser>, Response> {
        Ok(None)
    }

    fn challenge(&self) -> Vec<&'static str> {
        // Should never be called, because authenticate_request always returns Ok
        unimplemented!()
    }
}

impl<'a> AsRef<dyn AuthenticateRequest + 'a> for NoAuth {
    fn as_ref(&self) -> &(dyn AuthenticateRequest + 'a) {
        self
    }
}
```

A small annoyance--we have to manually implement `AsRef`, so that a user can
provide an instance of `NoAuth` if they require no additional state. We use this
in our main:

```rust
    let app = Router::new()
        .nest(
            "/redfish/v1/Systems",
            ComputerSystemCollection::default()
                // ...Handler assignment omitted for brevity...
                .into_router()
                .with_state(NoAuth),
        )
        .layer(TraceLayer::new_for_http());
```

And that's it! This feature branch is complete. In the last part of the series,
we'll discover the path to implement this in our code generator!

[1]: https://github.com/AmateurECE/redfish-codegen/commit/f6ac857779f921303ed32239bc2e4fd9098c0df9
