---
layout: post
title: "LibreIdP: Plugin Architecture"
date: 2022-08-16 17:22:52 -0500
categories: server
---

Now that I've clearly defined the mission statement of the LibreIdP project,
I'd like to take an initial stab at architecting one potential solution to
fulfill the requirements of the "trivial use case" from my
[previous post]({{site.baseurl}}{{page.previous.url}}).

## Micro-features

We're doing to do architecture by "micro-feature." I'm not sure whether that's
a term used by anyone other than myself, so I'll define it here:

> _micro-feature_: A logical interaction with an application that may form only
> a part of a use case, and is externally visible. Typically, smaller and
> easier to implement than a User Story.

It might not be totally clear based on the definition I've provided, so let's
start with the first example.

We expect that the following requirement will be met in the final design:

> Where LibreIdP has been configured with the NGINX_HTTP_AUTH FRONTEND, when an
> HTTP REQUEST is received, if a valid authorization header is not provided,
> LibreIdP shall indicate an HTTP 401 Unauthorized RESPONSE with a
> WWW-Authenticate header that points to a user authentication form.

This is a big requirement, but it should be easy to imagine some architecture
that meets this requirement.

Keeping in mind our plugin architecture, where this is really a requirement on
the _plugin_, and not on LibreIdP itself, we can begin assembling some
interfaces.

{% plantuml %}
package "libreidp-runtime" {
    struct IdpConfig {
        auth_form_path: String
        auth_form_uri: String
        plugins: String[]
    }

    enum IdpHttpRouterError {
        NO_ERROR
        URL_UNAVAILABLE
        to_string() -> String
    }

    class IdpHttpRouter {
        register_url(url: String) -> IdpHttpRouterError
    }

    class IdpHttpRequest

    class IdpHttpResponse {
        set_header(name: String, value: String)
    }

    interface IdpHttpRouteHandler_v1 {
        handle(request: IdpHttpRequest) -> IdpHttpResponse
    }

    interface IdpHttpFrontend_v1 {
        new() -> IdpHttpFrontend_v1
        free(frontend: IdpHttpFrontend_v1)
        route(router: &mut IdpHttpRouter) -> IdpHttpRouterError
    }

    struct IdpPlugin_v1 {
        interfaces: IdpInterface[]
    }

    struct IdpFrontendPlugin_v1 {
        frontend_interface: IdpFrontendInterface
    }

    enum IdpInterface {
        IDP_FRONTEND
    }

    enum IdpFrontendInterface {
        IDP_HTTP_FRONTEND_V1
    }
}

package "libreidp-plugin-nginx-http-auth" {
    class NginxHttpAuthService {
        + interface: IdpInterface = IDP_FRONTEND
        + frontend_interface: IdpFrontendInterface = IDP_HTTP_FRONTEND_V1
    }

    class NginxHttpAuthHandler
}

NginxHttpAuthHandler --|> IdpHttpRouteHandler_v1
NginxHttpAuthService --|> IdpHttpFrontend_v1
NginxHttpAuthService ..> NginxHttpAuthHandler
NginxHttpAuthService --|> IdpPlugin_v1
NginxHttpAuthService --|> IdpFrontendPlugin_v1
{% endplantuml %}

There's a few things to note here. First, since we're implementing plugins as
dynamic libraries, we need a way to configure them at load time. Eventually,
this will be provided by a parameter in a configuration file. But for now, it's
sufficient to say that we have a `struct IdpConfig`, which contains a list of
plugins to load. Perhaps these are just the plugin names, and we can infer the
path to the dynamic library at runtime based on some compile-time
configuration.

When we load the config, we look for a symbol that is perhaps called
`idp_plugin_v1`, which is of type `IdpPlugin_v1`.
