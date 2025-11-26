---
layout: post
title: Learning OCaml by Parsing JSON
date: 2025-11-23 19:00:00
categories: languages
---

Two weeks ago, I started on a journey to learn how to design programming
languages. After thorough research, I decided to learn and use OCaml for this.

For starters, it's very important to me that the programming languages I create
are supported by formal mathematics and type theory. The Coq proof assistant
(which now prefers to be called Rocq) enables logicians to write their compiler
alongside a proof of the language's interesting properties. More on this in a
future post. Rocq extracts to OCaml. It extracts to other languages, as well,
like Haskell, but since the official installation instructions reference
`opam`, I thought that I would have a better time learning and using OCaml than
fighting with the Rocq compiler to extract to workable Haskell. I'll probably
never learn whether that hypothesis holds water.

The other books I've selected for my journey also make heavy use of OCaml.
Besides this, I haven't yet been able to claim an ML dialect as one of my
competencies, so I thought this would be an opportunity check that box.

I selected the book _Real World OCaml_ to teach myself the language. The second
edition is available for free online from Cambridge, but I like to touch paper,
so I ordered a used paperback on Thriftbooks. I read Part I from start to
finish, only skimming the chapters on objects and classes, and picked a
smattering of content from Part II--the chapters on testing, command line
arguments and parsing. I skipped Part III altogether.

# Reflections on the module system

So far, I've been pleasantly impressed with the language. Features like named
parameters and the module system are unique from other mainstream languages.
For a file `foo.ml` containing this definition:

```ocaml
type t = int
```

We can name this type in client modules with `Foo.t`, where `Foo` is the name
that OCaml assigns to the module from its filename. If I prefer to nest
modules, I might make `Foo` a submodule in `bar.ml`, where the name of `t`
would be `Bar.Foo.t`:

```
module Foo = struct
  type t = int
end
```

The rules for forming the name of a definition are clear and predictable. This
is something I miss when going back to C++, where `namespaces` are completely
orthogonal to file structure. A C++ development team has to discuss and align
on a set of rules, and then somehow enforce and maintain them, either with
tools or code inspection[^1]. 

Coming from non-ML languages, however, I find it a little strange that modules
are _the_ mechanism for constructing types. OCaml does not have type classes,
interfaces, traits or templates. In place of these, it has only modules.

## Monads in Haskell and OCaml

Let's consider the definition of `Monad` in Haskell:

```haskell
class Applicative m => Monad (m :: Type -> Type) where
  (>>=) :: m a -> (a -> m b) -> m b
  (>>) :: m a -> m b -> m b
  return :: a -> m a
```

This is clearly a type. We can export it from a module, and import it:

```haskell
-- In Monad.hs
module Control.Monad (Monad) where

-- In MyApp.hs
import Control.Monad (Monad)
```

Here, the module system is clearly separate from the type system, and it's an
organizational structure--not a logical one. Let's compare this to the
definition of `Monad` in OCaml:

```ocaml
module type Monad = sig
  type 'a t
  val return : 'a -> 'a t
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
end
```

There are some obvious and superficial syntactic differences. For example, the
type parameters appear here on the left side of the type constructor, whereas
in Haskell they appear on the right. This type, however, is inextricably
connected to the filesystem. The language facility for scoping lexical names
_is the same as the one used to construct a higher order type abstraction_.

## Implementing Monads

We're going to take this two steps further. To implement `Monad` for your type
in Haskell, you declare it as an `instance`:

```haskell
instance Monad Maybe where
  (Just x) >>= k = k x
  Nothing  >>= _ = Nothing

  (>>) = (*>)
```

This is copied directly from [the source in `Base`][2]. If the monad laws are
upheld, `return` is definitionally equal to `pure` from the `Applicative`
typeclass, and the right sequence operator is equivalent to the same operator
in `Applicative`.

To implement `Monad` in OCaml, you _could_ create a module that satisfies the
`Monad` module signature:

```ocaml
module MOption : Monad = struct
  type 'a t = 'a option
  let return x = Some x
  let ( >>= ) m f = Option.bind m f
end
```

I should point out another syntactic difference: OCaml does not support terse
function definitions like Haskell, so this expression is ill-typed: `let return
= Some`.

In practice, however, no one writes OCaml this way. There is no abstraction for
monads. The interface is enforced for common monads in `Base` by convention.

## Programming With Monads

To program using monads in Haskell, we often don't use the typeclass functions
directly. Instead, we use `do` notation, which allows us to write code that
reads like an imperative program:

```haskell
maybeSum :: Maybe Int -> Maybe Int -> Maybe Int
maybeSum a b = do
  a' <- a
  b' <- b
  return $ a' + b'
```

GHC transforms this into an equivalent expression that uses the typeclass
functions during compilation:

```haskell
maybeSum a b =
  a >>= \a' ->
    b >>= \b' ->
      return $ a' + b'
```

OCaml has two solutions that provide similar ergonomics. The most mature and
common tool is `ppx_let` (a Jane Street invention), but OCaml 4.08 introduced
_binding operators_ which might someday provide the same level of convenience
for common monads. This example writes our `maybeSum` function using `ppx_let`:

```ocaml
open Base

let maybe_sum a b =
  let open Option.Let_syntax in
  let%bind a' = a in
  let%bind b' = b in
  Some (a' + b')
```

Both `ppx_let` and `do`-notation are syntax extensions--they are transformed
into equivalent monadic code before compilation. These functions are both
written directly in terms of the `Maybe` monad.

Monads are, of course, very powerful, and we can express all sorts of
interesting logic on them. The functional reactive programming library Yampa in
Haskell provides `reactimate`, a function for running an arrow function on a
monad given a pair of "input sensing" and "actuation" monadic actions:

```haskell
reactimate
  :: Monad m
  => m a                            -- Initializing action
  -> (Bool -> m (DTime, Maybe a))   -- Input sensing action
  -> (Bool -> b -> m Bool)          -- Actuation (output) action
  -> SF a b                         -- The arrow function
  -> m ()
```

In practice, this is often run on a side-effect-producing monadic action, like
`IO`. However, it's polymorphic in the monad `m`, so it could just as easily be
run on an `Either` or a `Maybe`.

As far as I'm aware, there's no easy way to write this function in OCaml. If we
were to create a `Monad` module, like above, we could implement this as an
OCaml functor (a function on modules). However, that module does not exist in
the standard library, so any solution would be inconsistent with the rest of
the ecosystem. I'm interested to hear if I'm missing something.

# Parsing JSON

I only completed one of the exercises in the book--the [JSON parser][2]
exercise built using OCamllex and Menhir. This was the one I thought would be
directly applicable to developing compilers.

Since the book is available online for free, I won't reproduce the code for the
parser here. Instead, I just want to point out a couple of interesting experiences I encountered while developing it.

## Testing

I wanted to try `ppx_expect`, so I pulled it in and wrote an expect test for the parser:

```ocaml
let%expect_test _ =
  let lexbuf = Lexing.from_string {|{"obj":"\"foo\""}|} in
  let result = Option.get (Json_parser.parse_with_error lexbuf) in
  Json_parser.output_value stdout result;
  [%expect {| |}];
```

I followed the advice of the book and established a "test only" library, separate from my parser library. Supposedly, this prevents code bloat. It does require me to deviate from the Dune project template a little, so here's my `test/dune` file:

```
(library
 (name test_json)
 (inline_tests)
 (preprocess (pps ppx_inline_test ppx_expect))
 (libraries json_parser))
```

This test is written to expect empty output, so we fully expect it to fail, and
it does. But expect tests produce a diff in the output that, if accepted, would
cause the test to pass:

```
[json_parser]$ opam exec -- dune runtest
File "test/test_json.ml", line 1, characters 0-0:
diff --git a/_build/default/test/test_json.ml b/_build/.sandbox/713d6c9a80082f32d86b6de371e3845a/default/test/test_json.ml.corrected
index 435e144..884c113 100644
--- a/_build/default/test/test_json.ml
+++ b/_build/.sandbox/713d6c9a80082f32d86b6de371e3845a/default/test/test_json.ml.corrected
@@ -3,4 +3,4 @@ let%expect_test _ =
   let lexbuf = Lexing.from_string {|{"obj":"\"foo\""}|} in
   let result = Option.get (Json_parser.parse_with_error lexbuf) in
   Json_parser.output_value stdout result;
-  [%expect {| |}];
+  [%expect {| {"obj":"\"foo\""} |}];
```

This is called _Exploratory Programming_, and I'm very excited to use it when writing my compiler.

## Escaping Quotes in String Literals

The authors wrote a function for printing a `Json.t` back to a string, which is
not rendered in the output. I copied it from the [book sources on GitHub][3],
but changed mine to output "minified" JSON, without whitespace between. I
figured this would be easier to write expect tests against.

When given a string literal that contains escaped quotes, the parser fails with
a syntax error. This turns out to be because the lexer in the book is missing a
rule for escaped double quotes in string literals. Here's my updated definition
of the `read_string` rule:

```ocaml
and read_string buf =
  parse
  | '"'       { STRING (Buffer.contents buf) }
  | '\\' '/'  { Buffer.add_char buf '/'; read_string buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf }
  | '\\' 'b'  { Buffer.add_char buf '\b'; read_string buf lexbuf }
  | '\\' 'f'  { Buffer.add_char buf '\012'; read_string buf lexbuf }
  | '\\' 'n'  { Buffer.add_char buf '\n'; read_string buf lexbuf }
  | '\\' 'r'  { Buffer.add_char buf '\r'; read_string buf lexbuf }
  | '\\' 't'  { Buffer.add_char buf '\t'; read_string buf lexbuf }
  | '\\' '"'  { Buffer.add_char buf '"'; read_string buf lexbuf }
  | [^ '"' '\\']+
    { Buffer.add_string buf (Lexing.lexeme lexbuf);
      read_string buf lexbuf
    }
  | _ { raise (SyntaxError ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
  | eof { raise (SyntaxError ("String is not terminated")) }
```

I also had to change the `output_value` function to escape double-quote
characters when serializing string literals. Here's that fragment. The rest is
the same:

```ocaml
let rec output_value outc = function
  | `Assoc obj -> print_assoc outc obj
  | `List l -> print_list outc l
  | `String s -> print_string outc s
  | `Int i -> printf "%d" i
  | `Float x -> printf "%f" x
  | `Bool true -> Out_channel.output_string outc "true"
  | `Bool false -> Out_channel.output_string outc "false"
  | `Null -> Out_channel.output_string outc "null"

and print_string outc s =
  let escaped = CCString.replace ~sub:"\"" ~by:"\\\"" s in
  Out_channel.output_string outc ("\"" ^ escaped ^ "\"")
```

# What's Next?

I have so far enjoyed programming in OCaml, even though it seems that OCaml has
less support for categorical abstractions than Haskell does. I'm now moving on
to reading _Types and Programming Languages_, by Benjamin C. Pierce, which
develops type checking algorithms in OCaml. My next post is likely to include
the results of experimenting with these.

---

[^1]: Of course, C++ is mostly alone in these troubles--modern languages like
    Rust also have clear and predictable rules for paths of types and
    definitions, which are derived from the file structure.

[1]: https://hackage.haskell.org/package/ghc-internal-9.1201.0/docs/src/GHC.Internal.Base.html#line-1574
[2]: https://dev.realworldocaml.org/parsing-with-ocamllex-and-menhir.html
[3]: https://github.com/realworldocaml/book/blob/master/book/parsing-with-ocamllex-and-menhir/examples/correct/parsing-test/json.ml#L15
