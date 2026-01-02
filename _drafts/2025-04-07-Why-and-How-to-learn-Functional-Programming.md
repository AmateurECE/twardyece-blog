# Presentation Workflow

## Notes

1. Keep irrelevant information out of the presentation. It just weakens the
   point.

### Why

1. Functional programming languages enables greater reasoning power--it's much
   easier to reason about what the code _isn't_ doing.
1. Functional programming languages reject some designs that are valid in other
   languages--race conditions (memory safety), side effects (compositional
   reasoning), but every design that's valid in a functional programming
   language is valid in a lower level language.
1. This is a tool that we need to have in our toolbox. It's not a replacement
   for functional programming. We should use it when it makes sense.

## 1. The Blub Paradox

As we move up the ladder, our software begins to look less like code, and more
like a specification of behavior or logic.

It's not hard to convince ourselves that this hierarchy exists, in some form.

**Show Activation Switch in ARM Assembly**

What does this code do? It's hard to tell.

**Show Activation Switch in C**

C enabled structured programming, which enforces structure around control
flow--if/else statements and function calls. It also allows creating software
that's oblivious to platform and architecture.

**Show Activation Switch in C++ (or Rust?)**

C++ enables object-oriented programming, which enforces structure around
virtual dispatch. To some extent, it also enforces structure around dynamic
memory usage. I think we would all agree that using `new` and `delete` is an
anti-pattern in C++, and we have better tools now.

Rust enforces structure around ownership--all references are always valid, and
all data has at most one owner. I think we would all agree that that's a good
thing.

**Show Activation Switch in Haskell**

Haskell enables functional programming, which enforces structure around side
effects. There is no such thing as global data in Haskell, and Haskell programs
cannot perform I/O. Instead, programs compose I/O _actions_ that are executed
at runtime.

Haskell enforces separation of code that does I/O from code that handles data.
Yet another thing that I think we can all agree is good.

## 2. But I Will Never Use Haskell at Plexus!

That's not because our customers would forbid it, however. Haskell requires a
full general purpose operating system.

We're still trying to use Rust.

**Show a snippet of code from the kernel that uses object-orientation**

"Why don't they just use C++"? Because they can't. For political reasons,
instead of technical reasons, but those are still valid. There are no technical
reasons for us not to use Rust--only political ones. Maybe we will some day.

Functional Programming has been all over CppCon. Bloomberg is using Monads to
speed up Fin-tech. We're getting more monad types in the C++ Standard Library.

Functional Programming is already here at Plexus. Both the Rainbow and VPU
projects are applying concepts from FP.

Functional programming helps you turn runtime errors into compile-time errors.

Doing FP will teach you how to design for Rust.

## 3. How do I learn FP?

There are three common features among modern functional-programming languages
that make them different from C++. It's not that we _can't_ do these things,
it's just that we're getting them right now, while other languages have had
them for as long as 30 years!

### 1. Start with Higher-Ordered Functions (HOFs) and Algebraic Types

You can write HOFs in Scheme or Clojure.

In C++, HOFs are functions that take or return a lambda. Product types are
`std::pair`, `std::tuple`, classes and structs. Use `std::variant` to represent
co-product types.

### 2. Categorical Constructions

You _cannot_ work with these in Lisp-based languages.

Functors, Monoids and Monads, Oh my!

These are abstractions over programming "shapes". You can use them to abstract
pure code away from cross-cutting concerns.

In C++: `std::optional`, `std::expected`, `std::promise`, coroutines.

### 3. Type-level Programming

* Higher-kinded types in Haskell
* Indexed types (a form of dependent types, in Agda)
* Type-generic programming

In C++, we have templates and template meta-programming, which can be enabled
through Concepts and Constraints.
