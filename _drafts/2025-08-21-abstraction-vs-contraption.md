---
layout: post
title: Abstraction vs. Contraption
date: 2025-04-05 08:00:00
---

Many amp hours have been spent discussing principles of software design. Today,
I would like to discuss two patterns for creating fragile or vacuous software.
In my experience, we often criticize both of these patterns, but those who
decry one repeatedly commit the other. The both of them should be avoided. Of
course, I'm not above having opinions, only I hope my preference isn't clearly
present in this discussion.

Concretion should be our normal modus operandi in software design. The best
code I've read usually exhibits both of these qualities:

1. Mutable state resides high in the call stack, where it passes through
   stateless behavior. In contrast, mutability is often relegated to low-level,
   stateful objects.
2. The flow of logic can be traced through direct function call. In contrast,
   highly abstract code often relies on virtual dispatch or dispatch on generic
   type parameters.

Inevitably, we fall prey to the two forces of software design--encapsulation
and decomposition--and we start to think in terms of abstractions. Abstraction
invariably requires us to sacrifice one of these qualities. Object-oriented
programmers may craft wild causal machines, woven from concepts with
increasingly obscure stateful behavior. They have decided to delegate
mutability. In contrast, functional programmers often raise towers of
meaningless abstraction, whose types bear no resemblance to the problem domain.
They have decided to break the flow of logic with polymorphism.

I work among OOP designers, and I often hear complaints about taxonomies of
abstraction. I recall the time I introduced a coworker to [`tower`][1] with the
`Service` trait.

> "What's a _Service_, though? That name is so abstract, I'm not sure what it
> means."

He's right, to be fair. You have to read the `tower` documentation, and then
write one and use it with the ecosystem in order to develop a mental model for
the term. Even then, there doesn't exist any terminology which can concisely
communicate the semantics of `tower::Service` to someone who isn't already
familiar. The mental model, in this case, is an ontology--the classification of
things, and the kinds of relationships between them.

These abstractions often build upon each other, so that a solid foundational
understanding is necessary to communicate effectively about the design. "A
`Router` is a `Service` that switches requests between multiple `Services`."

On the other hand, I've encountered systems built by developers who took OOP
principles too far. This code looks something like this:

```
crew.checkTelltales();
skipper.hikeMainSheet();
skipper.adjustTiller();
```

The domain is clear. Googling these terms indicates the domain is sailing
related, and it's obvious that the `crew` and `skipper` objects are intended to
represent the roles of the sailors. But in real sailing, the crew needs to tell
the skipper how to adjust the tiller based on the telltales. In turn, the
skipper will adjust the main sheet to keep the heading he wants. How do the
skipper and the crew communicate in this code? Do these methods perform I/O?
What happens if the `skipper` hikes the main sheet before the `crew` checks the
telltales? These are good function names. The problem is that they take no
arguments, and they return no values, so the flow of logic is totally obscured.

It must be the case that state is mutated by side effect from these methods,
but it's impossible to reason about how that's done from reading the code. The
mental model, in this case, is a dynamic one, which represents behavior and
sequence at runtime. Here, I'm obligated to reference Dijkstra's _Go To
Statement Considered Harmful_:

> [...] Our powers to visualize processes evolving in time are relatively
> poorly developed.

This is a _contraption_. One action changes the behavior of another action, or
causes a third action to occur, like in a Rube Goldberg machine.

# Don't Fall Into the Trap

We often use one or the other of these patterns to achieve a high-level of
abstraction. Unfortunately, this is sometimes because we are trying to achieve
some ideological goal: the `Service` and the `skipper` are open to extension,
but closed to modification (OCP).

Please don't mistake my intent--there are appropriate times to write mutable
objects, and there are appropriate times to have highly abstract types. These
work well at architectural boundaries, which is often where we want to achieve
this level of abstraction. Care should be taken not to allow these patterns to
proliferate the code.

Where possible, use patterns that your team is familiar with. Some teams know
the GoF patterns extremely well, and can effectively communicate using these
terms. Other teams may be well-versed in the established patterns of some
framework or open-source software, and they should be encouraged to communicate
abstractions in these terms instead. If you know `axum` and `tower`, the terms
`Service` and `Router` have (at least one) precise meaning.

Most importantly, one of these strategies for abstraction is not inherently
better than another. We need everyone on the team to be able to craft these
kinds of abstractions, and to grok them. It's the job of the team to keep each
of us accountable to our abstractions. Design responsibly.

[1]: https://docs.rs/tower/
