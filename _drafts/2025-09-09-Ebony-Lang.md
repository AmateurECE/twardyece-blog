# Things I Definitely Want to Have

1. Proof by tactic

# Problems I want to fix

1. In Rust derive proc-macros are great, until you want to derive a trait on a
   type defined in another crate.
2. In Yampa, loops cannot be detected at compile time.

# Things I Like About Other Languages

1. Lean supports semicolons and curly braces as well as newlines and
   indentation in `do` actions. OCaml also supports semicolons for joining
   expressions in imperative code.
2. I like that Lean function definition syntax allows names to be inline with
   the function definition. Folks coming from languages with ALGOL-based syntax
   will find this very intuitive.
3. Proof of list indexing:
   * By proposition: `def foo (xs : List a) (ok : xs.length > 2) : a := xs[2]`
   * By `have`-expressions
   * Functions that panic at runtime `a[i]!`
   * Functions that return `Option`, e.g. `a[i]?`
   * By `a[i]'h` syntax

# Notes

1. Lean's `partial` keyword indicates partial functions. This is interesting.
   Haskell has no such thing. This is different from the `!` never type in
   Rust. Functions annotated to return the `never` type _must_ have an infinite
   loop or a panic (must not return). A function marked `partial` is _allowed_
   not to return. A function that calls a partial function must be a partial
   function.
2. Lean has _subtype syntax_, which seems to be a very succinct form for
   defining new types on larger types with predicates.
