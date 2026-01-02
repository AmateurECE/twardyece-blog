What if we only allowed side effects at the top-level of our software? At the
level of architecture, we can reason about abstract machines that have stateful
interactions. But within the details of our programs, we want to eschew
stateful operations as much as possible.

We can reason about our types as representing one of a few kinds of things:
* Abstract machines with states and operations (Bertrand Meyer, Verilog
  modules, Functional Reactive Programming)
* Values, objects in a category
* Computations (e.g. IO & State Monads, \[partially applied\] functions,
  closures, lambdas)

RECAWR
Imperative Shell, Functional Core
eval/apply

Using Comonads?

Futures are state machines, but we can also use them to represent partially
applied functions. Is that because futures are special, or is that because all
state-machine capable abstractions can be used to represent partially applied
functions?

Is compositional reasoning orthogonal to these concepts? How much overlap is
there here? Are these just different ways of conceptualizing types, and that's
all?

There is one state--the system state.

In Haskell, if we want to leverage _program_ state to model an abstract
machine, we have to use the state monad. Sometimes, the system state is stored
outside of our program--our program transforms the state of the database from
state S\_1 to S\_2, or we perform a set of computations on a TCP connection, or
we take input from a file and write output to a different file. If we can write
our program so that it's lifespan is _bounded_ (imagine a command line utility
that does its work and exits), we can model our program merely as a
computation. This is _awesome_. Most of the time, though, our programs have an
effectively unbounded lifespan, and our behavior must be stateful--we have to
keep a connection to a database open, or track user sessions, etc. Even in
these cases, we can choose to view our program as a computation over a language
with a start symbol (when we begin executing), a stop symbol (when we stop
running) and any number of other intermediate symbols that represent inputs
from outside actors, however it's not always valuable for us to view our
software this way.

* Boost.Hana?
* https://github.com/graninas/cpp_functional_programming
