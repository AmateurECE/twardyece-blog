---
layout: post
title: Non-Layered Architecture Styles
date: 2024-11-16
categories: design
---

# Non-Layered Architecture Styles

I design medical devices for a living. These are products with a fantastic
amount of technical and regulatory complexity, and over the last decade, my
company has been responsible for increasingly large and complex systems. There
are two books that are highly influential for those with architectural
influence on our team: Robert Martin's _Clean Architecture_ and Eric Evan's
_Domain-Driven Design_.

I want it to be clear that I _love_ these books. There's a reason they're
ubiquitous, and they describe incredibly powerful ways to manage complexity in
scalable software systems. These two architecture styles generate layered
systems and encourage teams to extract rich domain interactions and abstract
them away from the details of the implementation. These are very powerful and
important tools.

However, I think we're doing a disservice by not also promoting _other_ books
within the team. Unfortunately, the software in many of the products we design
simply _does not exhibit rich domain behavior_. That's not to say the product
itself doesn't have knowledge of the concepts from the domain (though sometimes
they don't). Often, however, the "interesting bits" are implemented in
hardware. This is often an intentional mitigation, because in the eyes of the
FDA, the software is guaranteed to fail during the lifespan of the product.

For example, in my current product, there is a laparoscopic instrument that
exposes a lighting element and a camera feed to the system. My product
interacts with these ports to allow a surgeon to see what's going on inside the
body at the site where the therapy is delivered. As you might imagine, there is
some interesting logic that knows how to control the lighting element based on
the measured illumination level of each frame coming from the camera feed.
_This_ is business logic, and it makes sense to abstract this away from the
details of _how_ we communicate with the instrument. However, this feature is
entirely implemented in hardware. The responsibility of software in this use
case is to tell the hardware what the desired illumination level is based on
the user interface--the software doesn't contain any of the business logic!

I caught myself slipping into the trap of applying The Clean Architecture right
out of the gate. When I modeled this behavior, however, it became obvious that
there's very little "pure business logic". If we were to draw out the module
viewtype of the product architecture using a layered style at the system level,
all of the software would be implemented in the lowest layer--where details
about the user interface usually live.

Since we don't have very much business logic, extracting the business logic
isn't critical to the success of this product. We don't get a lot of value from
hoisting this guarantee into the architecture. On the other hand, modeling this
use case showed some complicated interactions between components in our
system--the "safe" parts, that talk to the hardware, and the "unsafe" parts
that control the GUI. For this use case in particular, it's also clear that the
"illumination changed" information has "event" properties. This event traces a
thread between isolated components. Based on this view of the architecture, it
looks easy to accidentally create tight coupling between components. We may
also experience issues assigning coherent responsibilities to components. These
sound like important guarantees to hoist into the architecture. So, I will be
recommending a "pipe and filter" style, where responsibilities are
intentionally designed into components, and components communicate using
_Ports_, which abstract away the details of the communication mechanism, and
provide a simple interface for full duplex event sourcing.

Architecture processes are often not evident in the code, and open source
applications that subscribe to the UNIX philosophy are not representative of
the population of architecture styles. Because our work is so politicized by
intellectual property rights, it's very difficult to discover new ideas, and we
have to actively seek them out.

December Update: My mentors ended up pushing me towards an architecture style
that's not only layered, but also not event-driven. It applies the layers from
_Clean Architecture_, and a pattern that I'll refer to as the _PLC pattern_.
I'll do a write-up on this pattern in the near future. Likewise, I'll discuss
the cited motivations for layered architecture styles. To my surprise, the
books appear to be wildly over-constraining this style.
