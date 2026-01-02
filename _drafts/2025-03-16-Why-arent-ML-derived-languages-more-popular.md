Lack of an ecosystem is definitely one thing. People definitely want to be able
to do something meaningful in their language, and they can only do so when
building blocks exist at the level of abstraction that they want to work in.

# Emergent Qualitative Attributes

Some claim that qualitative attributes like performance are emergent in these
languages, and that makes them difficult to reason about, when compared to
languages like C.

For a functional language used in product development, where the target
platforms are bare-metal environments and real-time operating systems running
on mid-range 32-bit ARM cores, I need to be able to reason about:

* When copies occur
* Time and space complexity of a section of code (in isolation)
* When time-unbound operations are required (blocking)
* Where I/O occurs
* When heap allocations are performed

It matters whether the reasoning includes when something _may_ happen vs. when
something _definitely_ happens; when optimizing _may_ occur vs. when a copy
_definitely_ occurs.

# Tools

We need a debugger. Even if we never need to use it, we have to have it. This
may also require support for a common debug symbol specification, such as
DWARF.

We need a build system that requires no extraordinary effort to accommodate the
vast majority of use cases.

We need a package manager, which allows distribution and reuse of code, which
integrates into the build system.

If performance is emergent, then we need tools to understand it and monitor it.

We need a language server.

Compiler errors must be clear and actionable.

If we make incompatible changes to the language, projects must opt-in to the
breaking changes and retain compatibility with abandonware.

# Copying

How can programmers reason about copying? One way is reference types. A
reference is a request to the compiler to reuse an existing value, preventing
copying. It's often possible to optimize away copies, but what if we had a
different way? What if we could instruct the compiler to error if a copy
_cannot_ be optimized away?

...I will have to think about this.

# (Arrowized) FRP?
