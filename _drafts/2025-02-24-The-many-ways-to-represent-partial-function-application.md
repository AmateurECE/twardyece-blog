- Promises
- std::bind
- Types

This is a pattern for product development. Our product must often calculate the
output of a function of two or more variables, where each variable is one of
two kinds:
- Available at runtime: measured continuously or provided by a user or an
  external actor.
- Available while the product is in some state: powered on (e.g. in the case of
  persistent variables), connected or disconnected, etc.
In this case, we want to partially apply the function.
