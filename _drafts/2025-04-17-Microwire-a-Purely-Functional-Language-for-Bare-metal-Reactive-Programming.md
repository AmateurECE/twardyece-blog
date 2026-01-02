---
title: Microwire: A Functional Language for Bare-metal Reactive Programming
---

A _reactive application_ is required to _react_ to user input. These are
usually long-lived, and required to interact with the physical world through
some hardware devices (motors, touchscreens, etc.). Most of my career has so
far been developing these kind of applications. They are distinguished from
_transformational applications_, which are short-lived programs that transform
some input to some output (e.g. a compiler).

In purely functional languages like Haskell, there are two primary avenues for
developing reactive applications. The first utilizes a combination of the
[State Monad][1] and the [IO Monad][2]. The second relies on (arrowized)
functional reactive programming, using a library such as [Yampa][3].

I've been thinking lately about designing a language that can be used for
bare-metal functional reactive programming (FRP). I find FRP to be a really
desirable goal because it allows the composition of reactive applications from
small, reusable "signal functions". Just the name alone invokes images of the
kind of engineering that preoccupies our hardware-oriented friends.

ML-based languages like Haskell are also well-suited for this kind of work.
They allow the developer to express logic in terms that read like a pure
specification of behavior. However, they are not well suited to embedded
development, which brings a suite of additional considerations.

# Recursion in Embedded Systems

Embedded developers have long been allergic to recursive algorithms. The MISRA
specification expressly forbids it, as do many organizations working in the
safety critical space, like NASA's JPL. The oft cited reason is stack overflow,
because the C programming language makes no guarantee about tail call
elimination. In recent times, compilers like [Clang have gained extensions that
can provide stronger guarantees on tail-call elimination][4]. But using these
makes C and C++ code non-portable.

> ...

I'm not interested in a language that provides escape hatches to writing dirty,
highly-optimized imperative code. I'm interested in a tool that can provide
global guarantees about performance and safety. If these are not enough to meet
the performance requirements of a particular application, that developer should
write those performance sensitive parts in a different language, like Rust.

The initial release of Microwire will transpile to Rust. This will make Rust
interoperability seamless.

[1]: https://wiki.haskell.org/State_Monad
[2]: https://en.wikibooks.org/wiki/Haskell/Understanding_monads/IO
[3]: https://wiki.haskell.org/Yampa
[4]: https://clang.llvm.org/docs/AttributeReference.html#musttail
