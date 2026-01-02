---
title: |
  Functional Programming Enforces the Good Practices of Object-Oriented Design
---

# Object-Oriented Designs as Layered Architectures

Object-oriented designs often demonstrate layers of abstraction. High level
components are composed of lower level components, and there are often a set of
pure fabrications at the top that express the abstractions of the layer below
it, etc.

> Can all object-oriented designs can be described this way?

For example, I don't know how to work with a machine that provides only
memory-mapped registers. If I build a set of peripheral abstractions, however,
I can add a layer of abstraction that turns this into a machine that exposes a
UART, a PCI bus, an I2C bus, etc. This is more meaningful, but if my goal is to
let people access their healthcare records, this is still not expressive
enough. [A GPIO line is not normally a useful user-facing abstraction][1]. On
top of this, I can build a layer that provides a network interface, and that's
something I can work with. Or, if I were designing a municipal sewer
infrastructure, I might need something that represents the concept of a pump,
which may rely on a PWM and a set of GPIO under the hood. A Pump is something
that I can express.

It's really hard to reason about this kind of a design, however. Every mutation
is done through side effects. How do I know if my design is safe for
concurrency?

Every Functional Reactive design can be translated into an object-oriented
design that follows best practices.

[1]: https://www.kernel.org/doc/html/v6.15-rc2/driver-api/gpio/using-gpio.html#using-gpio-lines-in-linux
