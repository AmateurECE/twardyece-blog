---
layout: post
title: Architecture in Hypermedia, Part 1
date: 2023-11-27
categories: design
---

If one is to research the definition of the term "Hypermedia," they may find a
number of cryptic statements, such as "[Hypermedia is the matter of which the
World Wide Web is made][1]." It takes a lot of reading to get an accurate grasp
on a simple concept: If the internet can be viewed as a medium for the exchange
of information, then "hypermedia" is a characteristic of _the information_.
For example, a service may expose a document (perhaps an HTML document), which
has embedded video streams, images, and links to other documents. This is,
essentially, what hypermedia describes: that the information exposed by a
particular service on the web is linked to the information exposed by another
service, and that its information is not contained in a single medium (text,
video, or other).

In API design, however, this term has some specific meanings. The REST
application architecture (if it can be called that) specifies that APIs shall
rely on "Hypermedia as the engine of application state" (a constraint
abbreviated as HATEOAS). Stated another way, a client application needs little
or no understanding of how to interact with an application service beyond a
generic understanding of hypermedia. This still doesn't paint a vivid picture
of what the term _means_, however.

If we ponder this statement over a beer or your favorite contemplative
beverage, we may happen upon the realization that client applications with a
knowledge of hypermedia shouldn't need to have any domain knowledge in order to
use an application service effectively--that is, the client is totally
decoupled from the problem domain and the use cases. Considering Clean
Architecture, we can take this thought experiment further to assert that a
client application is therefore entirely contained in the Infrastructure layer
of our architecture, and that the use cases supported by our application can be
almost entirely implemented in the service itself.

In practice, this is hardly ever the case. Frontend applications are usually
coupled to their back-end services through the domain concepts and
cross-cutting concerns such as form validation. The recent popularization of
specifications like OpenAPI provide a mechanism to finally break this coupling
and implement this utopian architecture.

In this series, we'll implement a hypermedia-powered application using these
tools and demonstrate the ways in which intentional software architecture can
enable rapid change for modern applications. We will develop an application
with business logic, craft web and native clients for multiple platforms, scale
our services up and down, and implement additional use cases to exercise our
architecture and observe how readily it lends to different kinds of changes.

I present the following roadmap for this series:

1. In this installment, we'll introduce the application and use cases.
2. In part 2, we'll model our solution and write an OpenAPI document that
   encapsulates our domain concepts and enables our use cases.
3. In part 3, we'll write a tool to generate our models from our OpenAPI
   document. 
4. In part 4, we'll implement our backend service.
5. In part 5, we'll implement a web frontend.
6. In part 6, we'll implement a mobile frontend.
7. In part 7, we'll implement a desktop frontend.
8. In part 8, we'll scale our development up and down, and observe how the
   clients are affected.
9. In part 9, we'll introduce a new use case and observe how all three of our
   clients are forced to change.

This will be a long series, but stick with me and lets see what we can learn!
All the code for this series will be hosted [here][2].

# The Application

For this exercise, I'm going to shamelessly steal a highly unrealistic example
from Martin Fowler's blog. All credit for this contrived application, of
course, goes to him, and you can find the post that introduces some of these
concepts and this application [here][3].

Imagine that in Wisconsin, where I live, there is a government program that
monitors the amount of ice cream particulate in the atmosphere. If the
concentration is too low, this indicates that we aren't eating enough ice
cream--which poses a serious risk to our economy and public order.

To monitor our ice cream health, the government has set up monitoring stations
in many towns throughout the state. Using complex atmospheric modeling, the
department sets a target for each monitoring station. Every so often, staffers
go out on an assessment where they go to various stations and note the actual
ice cream particulate concentrations. This application allows them to select a
station, and enter the date and actual value. The system then calculates and
displays the variance from the target. The system highlights the variance in
red when it is 10% or more below the target, or in green when 5% or more above
the target.

I modeled our single use case using [Gaphor][4]:

![IceCream Use Cases](/blog/assets/images/IceCreamGov-UseCases.svg)

And we can derive three requirements from the problem statement above:

![IceCreamGov Requirements](/blog/assets/images/IceCreamGov-Requirements.svg)

Note that I'm using UPPERCASE to denote terms in the domain space. When we
speak to the domain experts about the application, these terms form a common
language that are understood by our stakeholders, regardless of their technical
background.

In the next part, we'll model a portion of the solution and use that model to
develop an OpenAPI document that expresses our model in terms that
hypermedia-aware applications can understand.

[1]: https://smartbear.com/learn/api-design/what-is-hypermedia/
[2]: https://github.com/AmateurECE/hypermedia-architecture/
[3]: https://martinfowler.com/eaaDev/uiArchs.html
[4]: https://gaphor.org/
