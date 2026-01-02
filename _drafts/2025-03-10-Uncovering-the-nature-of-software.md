# Why am I studying this junk?

I think I've come to my own conclusion about the difference between Software
Architecture and Software Design. Others will come to their own conclusions
that reflect their context--languages, experiences, industries and so
forth--but this one is mine.

In my eyes, the difference comes down to goals.

_Software Architecture_ is a set of structures and processes that enable the
desired qualitative attributes of a system.

_Software Design_ is a purely human endeavor. It's a set of processes and
structures that enable a team to communicate intensional aspects of their
system that can't be afforded by their language, deliver increments of product,
and constrains (in a good way) the forms that a system may evolve into over
time.

In my definition of software design, there are two tools for achieving
increment of product--process, and collateral. The first is related to
development frameworks like Agile Scrum. How does the team communicate and
interact to complete work? The second is purely mechanical. What tools are
available in my language's standard library? What libraries are at my disposal
that can augment my work and increase my efficiency? Naturally, the domain of
software architecture is very interested in these areas as well, but for
different reasons.

To communicate intensional aspects of and constrain the evolution of our
system, we have other tools:

Related to _Reasoning Power_:

1. Encapsulation
2. Decomposition (esp. purity and immutability, see _Compositional Reasoning_)

All patterns and idioms afford one of these, often at the expense of the other.
Software design, then, is the act of applying patterns to deliver product
increments within an architecture.
