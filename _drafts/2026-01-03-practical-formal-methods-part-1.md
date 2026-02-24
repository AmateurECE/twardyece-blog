---
layout: post
title: "Practical Formal Methods with Rust: A Testing Discipline"
---

# Tools

[x] Prusti
[ ] Kani
[ ] Creusot
[ ] Hax(?)
[ ] F* (Pulse)?
[ ] Aeneas

# Outline

1. Testing
 1. Goal:
  1. Introduce everyone to some new terms and tools they might not have heard of before
  2. Illustrate that there are people on this team with interest in formal methods.
  3. Bust some common myths about formal methods (hard, not valuable, etc.).
 1. Roadmap: Testing, into first-order automatic reasoning, and then higher-order automated reasoning.
 2. Framework from Amann/Ofutt book (four coverage criterion).
 1. Skip the built-in test framework
 2. Fuzz testing with afl.rs and cargo-fuzz. Applications of fuzz testing.
 3. Property-based testing with proptest. Applications of property-based testing, how to identify algebraic properties. Representation invariants. Proving, for example, that a structure is a Monoid.

2. Model Checking
 1. Overview of the terms: SAT, SMT, Kripke structures
 2. Overview of the ecosystem: Prusti, Creusot, Kani

3. Theorem Proving

# Assertions

1. Testing can show the presence of bugs, but verification can show the absence
   of bugs.
2. There are lots of great verification tools out there. AADL is one that I'm
   particularly interested in. However, for this presentation, we will stick to
   tools that work on Rust code directly.

# Notes

1. Much of testing is concerned with thinking of new corner cases that need to
   be covered. With automated verification tools, all the corner cases are
   covered from the start, and the new concern is narrowing down the scope to
   something manageable for the verifier.
1. From my layman's perspective, the big difference between proof assistants
   and BMC is the level of effort on the behalf of the programmer to specify
   the software. While there is a fundamental technical limitation
   (specifications for BMC must be expressible in first-order, or in some
   cases, second-order logic), the benefit that interactive proof assistants
   provide in this area is seldom realized, because higher-order theorems are
   comparatively rarer in the discipline of software verification.
1. Prusti seems to be totally maintained. There hasn't been a commit in 2
   years, and the latest release targets Rust 1.73, so can't be used on code
   with the 2024 edition.
1. In the context of the Amann/Offut book, I _think_ there's a relationship
   between the tested property and the desired form of graph coverage (node,
   prime path, etc.)
1. What coverage criterion in the Amann/Offut compares to MC/DC?

# Prusti Notes

Prusti is based on the Viper project, which is a system that performs deductive
verification.[3]

1. Prusti performs _function modular specification_, so it only uses a
   function's specification whenever it encounters a function call. The only
   exceptions are pure functions, where Prusti also takes the function body
   into account.
1. Con of using Prusti-style verification: you might notice bugs in the
   specification as soon as you write code that uses the functions. For this,
   Prusti team recommends writing some tests for public-facing library
   functions.
1. Prusti does not currently support function bodies that contain lambdas,
   which makes this impossible to verify:
```rust
pub fn try_pop(&mut self) -> Option<T> {
  mem::replace(&mut self.head, None).map(|node| {
    self.head = node.next;
    node.elem
  })
}
```
1. Prusti also does not support structures that contain references, so we
   cannot verify `fn peek(&self) -> Option<&T>`.
1. Have Prusti generate counterexamples with `counterexample = true` in the
   configuration file.

# Kani Notes

1. With no other effort on the part of the verification engineer, kani will
   look for a suite of software failures including causes of undefined behavior
   and panics.
2. Use [concrete playback][4] to get a test case. I noticed that sometimes,
   test cases generated using this feature don't actually trigger the U.B. This
   could be why the feature is still "experimental".
3. Strictly speaking, Kani is checking whether our proof harness is a model of
   the safety property "does not panic". We can use the power of `any()` and
   `assume()` to cause a panic if the output from `latest_block` and
   `find_latest_block` are not equal, for all valid values of the input
   context. In this way, we are able to use Kani to establish a bisimulation
   between the specification and the code under test (i.e. the specification
   and the implementation are bisimilar). Bisimulation is a really important
   tactic for proving program correctness.

# Ideas for examples

Model checking:

* Jet engine control system from the paper
* Mutex implementation?
* Check if something panics
* VirtIO handler?
* Slab allocator?
* YMODEM implementation?
* Linked Lists (from the Prusti tutorial)

Interactive Theorem Provers:

* RTOS scheduler, using CLZ instruction for "count leading zeroes"

# Introduction

This is part one of a three part series on using formal methods for
verification of Rust programs. The focus in this series will be _pragmatism_.
We won't discuss the details of SAT solvers or dependent type theory more than
necessary--there's lots of great literature on these topics at length, which
I'll link to at every opportunity. Instead, we'll focus on the tools that
currently exist: how best to use them, and their limitations.

# Evaluating The Tools

If we're going to use these new tools, they should provide some benefit over
our current tools. We need a _testing discipline_, a process that we can
implement to obtain high-quality tests. We'll compare each new tool to the
experience of applying our test discipline.

Some readers may already have criteria for a test discipline in mind--maybe
it's the test development process you use at work. In our case, this will
involve three elements:

1. _Specification_: Tests check that an implementation refines a specification.
   What form do my requirements need to take in order to be useful?
2. _Synthesis_
3. _Coverage Criterion_

# References

* [A good overview of the verification landscape in Rust][1]
* [Differences between contracts and dependent typing][2]

[1]: https://aws.amazon.com/blogs/opensource/verify-the-safety-of-the-rust-standard-library/
[2]: https://cstheory.stackexchange.com/questions/5228/relationship-between-contracts-and-dependent-typing
[3]: https://viper.ethz.ch/tutorial/
[4]: https://model-checking.github.io/kani/reference/experimental/concrete-playback.html
