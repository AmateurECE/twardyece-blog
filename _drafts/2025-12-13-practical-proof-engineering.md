---
layout: post
title: Practical Proof Engineering
date: 2025-12-13 19:00:00
categories: languages
---

# Links

[Princeton verified software toolchain](https://vst.cs.princeton.edu/)
[Software Foundations: Verifiable C](https://softwarefoundations.cis.upenn.edu/vc-current/toc.html)
Aeneas for extracting Lean from Rust
Pulse allows extracting Rust

The Introduction to Theorem Proving in Lean4 does a pretty good job of
explaining the ecosystem and the uses. Except for the part where it talks about
model checkers and SMT solvers. "These systems can have bugs." This is a weak
argument for dependent type theory, in my opinion. The Lean4 kernel can also
have bugs. In my opinion, the primary motivation for interactive theorem
proving is transparency of the proof. Automated search methods can obscure
details of the proof. Surely, there are also proofs that an interactive proof
assistant can find, but a model checker can't. I just haven't encountered those
yet.

```lean
variable (men : Type) (barber : men)
variable (shaves : men → men → Prop)

example (h : ∀ x : men, shaves barber x ↔ ¬ shaves x x) : False :=
  have hnsbb : ¬shaves barber barber :=
    fun hsbb : shaves barber barber =>
      have hnsbb : ¬shaves barber barber := (h barber).mp hsbb
      show False from hnsbb hsbb
  have hsbb : shaves barber barber :=
    (h barber).mpr hnsbb
  show False from hnsbb hsbb
```
