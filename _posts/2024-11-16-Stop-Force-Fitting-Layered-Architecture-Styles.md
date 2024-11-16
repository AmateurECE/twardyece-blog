---
layout: post
title: Stop Force-Fitting Layered Architecture Styles!
date: 2024-11-16
categories: design
---

# Stop Force-Fitting Layered Architecture Styles!

I design medical devices for a living. These are products with a fantastic
amount of technical and regulatory complexity, and over the last decade, my
company has been responsible for increasingly large and complex systems. There
are two books that are highly influential for those with architectural
influence on our team: Robert Martin's _Clean Architecture_ and Eric Evan's
_Domain-Driven Design_. I want it to be clear that I _love_ these books.
There's a reason they're ubiquitous, and they describe incredibly powerful ways
to manage complexity in scalable software systems.

However, I think we're doing a disservice by not also promoting _other_ books
within the team. These two architecture styles generate layered software
systems that encourage teams towards extracting rich domain interactions and
abstracting them away from the details of the implementation. These are very
powerful and important tools.

Unfortunately, the software in many of the products we design simply _does not
exhibit rich interactions between domain concepts_. That's not to say the
product itself doesn't have knowledge of the concepts from the domain (though
sometimes they don't). Often, however, the "interesting bits" are implemented
in hardware, because in the eyes of the FDA, the software is guaranteed to fail
during the lifespan of the product.

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

I caught myself slipping into the trap of applying the Clean Architecture right
out of the gate. When I modeled this behavior, however, it was obvious that a
layered software architecture is a poor fit for this application. There isn't
any "pure business logic" to abstract away from the implementation. If we were
to draw out the module viewtype of the product architecture at a system level,
all of the software would be implemented in the lowest layer. As of today,
however, the systems engineers haven't communicated a layered architecture
style for the system.

That's not a problem--the software should implement an architecture style that
is a _best fit_ for the product. However, I'm experiencing political forces
from multiple sides that are trying to push me towards a layered architecture
style. Unfortunately, I fear that the Clean Architecture is a hammer; but not
_every_ product is a nail. Even the most tenured engineers are limited by the
diversity of their experiences (and their reading).

All this to say: read books! Architecture processes are not always evident in
the code, and open source applications that subscribe to the UNIX philosophy
are not representative of the population of architecture styles. Because our
work is so politicized by intellectual property rights, it's very difficult to
discover new ideas, and we have to actively seek them out.
