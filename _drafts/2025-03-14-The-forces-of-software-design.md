Coupling and Cohesion, Decomposition and Encapsulation.

These are forces. Recall, a force in physics is a vector--it has a direction
and a magnitude. So to, do these.

Consider this C++ design:

```c++
class IThermostat {
public:
  virtual ~IThermostat() = default;
  virtual enableHeater() = 0;
  virtual disableHeater() = 0;
};

class HeatController {
public:
  HeatController(std::unique_ptr<IThermostat> thermostat)
    : thermostat_(thermostat) {};

private:
  std::unique_ptr<IThermostat> thermostat_;
};
```

Is `IThermostat` a meaningful abstraction? It all depends on context. In Clean
Architecture (which I am _not categorically_ a supporter of), _Entities_
and _Use Cases_ are those design elements which you want to be the most stable
in your system. If `HeatController` is a use case in my design, then
`IThermostat` is probably a meaningful abstraction.

But what if the `HeatController` is not meant to be particularly stable? What
if it's a small part of the system?

Is `IThermostat` really an abstraction? A thermostat control wire is just
that--it doesn't have very many incarnations. Does the `HeatController` know
about the implementation of `IThermostat` already, because it knows that it's a
thermostat control wire? If so, it's likely the case that there will only ever
be one implementation of `IThermostat`.
