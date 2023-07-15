---
layout: post
title: "Dependency Injection for redfish-codegen, Part 4"
date: 2023-06-09 14:16:00 -0500
categories: redfish
---

# Recap

Up until now in this series, we've been working on a prototype series of the
`redfish-codegen` project, a project that aims at empowering developers to
create Redfish compliant services by composing ergonomic components. We looked
at the existing framework, discussed its pros and cons, and we implemented a new
framework that leverages the dependency injection magic provided by Axum. Now,
it's time to leverage our existing code generation tool to provide this
new framework in the next release of the project.

The first thing I'm going to do is move all of the component-generic
infrastructure into a new crate, `redfish-core`. This will allow me to keep all
of the authored code out of the `redfish-codegen` crate. Unfortunately, the
`RedfishAuth` extractor depends on the `registries` module of the
`redfish-codegen` crate. To handle this, we'll have to update the code generator
to produce our new components in a separate crate, which we'll call
`redfish-axum`.
