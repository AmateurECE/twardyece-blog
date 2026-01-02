---
layout: post
title: A Hypothetical Programming Language
date: 2025-10-09 07:00:00
---

The programming language I want doesn't exist yet.

* Dependent Types.
* Linear Types (example?)
* Arbitrary effect analysis: Proving that a program does not use dynamic memory
  allocation, or that it doesn't use it after reaching a certain state.
* Writing driver code that's polymorphic in effects: Write the driver code
  once, and it enables non-blocking semantics through buffering and an
  interrupt handler, blocking semantics through busy-waiting, or asynchronous
  behavior through Futures.
