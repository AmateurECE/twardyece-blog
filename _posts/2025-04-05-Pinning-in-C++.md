---
layout: post
title: Pinned Places in C++
date: 2025-04-05 08:00:00
---

Sometimes, I need to work in heapless environments. One really unfortunate
thing about the language C++, is that move semantics become very difficult to
express and constrain when the heap is unavailable.

## Storage Durations

As a brief reminder, all variables in C++ have a storage duration, and there
are [four storage duration classes][1]: automatic, static, thread and dynamic.
Memory with dynamic storage duration is allocated on the heap, of course.
All non-global variables have automatic storage duration, unless they are
declared `static`, `extern`, or `thread_local`.

## The Problem

Imagine, for example, that I have a class that represents a SPI bus, and that
I'm writing a driver for a specific ADC device that's connected to my SPI bus.
So far, that may look something like this:

```
enum class SpiError { /* Enumeration Literals... */ }

class Spi {
public:
  // Destructor _may_ actually do something interesting.
  ~Spi();

  std::expected<std::monostate, SpiError> write(
    const std::span<uint8_t> data,
    uint8_t chip_select);

  // Delete the copy constructor
  Spi(const Spi&) = delete;
  Spi& operator=(const Spi&) = delete;

  // Moving is okay, though.
  Spi(Spi&&) = default;
  Spi& operator=(Spi&&) = default;

private:
  // Instance data...
};

class Adc {
public:
  Adc(Spi* spi) : spi_{spi} {}
  uint32_t read_channel(uint8_t channel_index);

private:
  Spi* spi_;
};
```

We don't want `Adc` to own an instance of `Spi` by value, because we need to
share the `Spi` instance between multiple devices. `Spi` needs to implement
resource locking and ensure that concurrent access to the bus is impossible.

There's no problem with these classes yet. We can leave the default move and
copy constructors--after all, they don't own any resources, so it's valid to
move an instance of these objects.

...Until I do this:

```
class ApplicationState {
public:
  ApplicationState() : spi_{}, left_adc_{&spi_}, right_adc_{&spi_} {}

private:
  Spi spi_;
  Adc left_adc_;
  Adc right_adc_;
};
```

It's _subtle_, but the move semantics of `ApplicationState` are now
constrained. When I create a `Spi*` member variable in the `Adc` class, I'm
introducing a new class invariant on `Adc`: a borrowed lifetime. This isn't
Rust, but if it were, we would be forced to add a generic lifetime parameter on
`Adc`, like this:

```
struct Adc<'a> {
  spi: &'a Spi,
}
```

So that the lifetime checker could ensure we are free of temporal memory safety
issues. C++ has nothing like this. Granted, this example is easy to spot. It
becomes harder at scale--when there are many member variables, or when we
aren't already familiar with the invariants on `Spi` and `Adc`--for example, if
we didn't write them.

## Pinned Places

The issue is that the class invariant is placed on the _instance data_ of
`Adc`. We could make the class `Spi` immovable, but that's not really correct.
There's nothing in the type `Spi` that makes it immovable. We may be able to
coerce the C++ type system into helping us create a type that enforces this
invariant. The concept of a [pinned place][2] may help us here.

We'll start by introducing our type, `Pin`:

```
template<typename T>
concept Value = std::is_same_v<std::remove_reference_t<std::remove_pointer_t<T>>, T>;

template<Value T>
class Pin {
public:
    using reference_type = std::add_lvalue_reference_t<T>;
    using pointer_type = gsl::not_null<T*>;

    template<typename... Args>
    Pin(Args&&... args) : m_value{std::forward<Args>(args)...} {}
    ~Pin() = default;

    // Pinned objects intentionally have non-copyable/non-movable semantics.
    // Strictly speaking, copy semantics ought to be definable if T is copyable,
    // but default-ing them would restrict Pin to copyable types T. Semantically,
    // there is no reason why we should be able to copy a pinned object, so we
    // are safe to delete this.
    Pin(const Pin&) = delete;
    Pin& operator=(const Pin&) = delete;
    Pin(Pin&&) = delete;
    Pin& operator=(Pin&&) = delete;

    reference_type operator*() const noexcept(noexcept(*std::declval<pointer_type>())) { return m_value; }
    pointer_type operator->() noexcept { return &m_value; }

private:
    T m_value;
};
```

A `Pin<T>` object wraps an instance of a movable type `T` in an immovable
container. For variables with automatic storage duration, this has the effect
of "pinning" them on the stack. The `noexcept` declaration on the operators is
not necessary for this discussion, but it allows the `noexcept` constraint on
this operator to be inherited from the same operator on the type `T`, which is
nice. Similarly, we use `gsl::not_null` for a little bit of extra safety. We
never intend to return a null pointer, so it's helpful to annotate that.
Finally, you may notice that I created the concept `Value` to ensure that `T`
is not a pointer or reference type. This would make the nested type
declarations more complicated, and after all, "pinning" a reference type has no
semantic value, so we disallow it.

Now, we need a type that will allow classes to require their callers to uphold
the immovable invariant on owned instance data. We'll call it `PinPtr`:

```
template<Value T>
class PinPtr {
public:
    using reference_type = std::add_lvalue_reference_t<T>;
    using pointer_type = gsl::not_null<T*>;

    // TODO: Constructors?

    reference_type operator*() const noexcept(noexcept(*std::declval<pointer_type>())) { return *m_value; }
    pointer_type operator->() const noexcept { return m_value; }

private:
    pointer_type m_value;
};
```

We'll come back to the constructors in a moment. We can now rewrite `Adc` like
this, and `PinPtr` acts just like any smart pointer type:

```
class Adc {
public:
  Adc(PinPtr<Spi> spi) : spi_{spi} {}
  uint32_t read_channel(uint8_t channel_index) {
    static constexpr std::array<uint8_t> command = {0x08, 0x00};
    spi_->write(command);
  }

private:
  PinPtr<Spi> spi_;
};
```

`Adc` is still movable, and so is `Spi`. But the idea is that now, when I write
`ApplicationState`:

```
class ApplicationState {
public:
  ApplicationState() : spi_{}, left_adc_{spi_}, right_adc_{spi_} {}

private:
  Pin<Spi> spi_;
  Adc left_adc_;
  Adc right_adc_;
};
```

The move and copy constructors for `ApplicationState` are automatically
deleted!

## Constructing a `PinPtr`

The last thing is to ensure that it's only possible to construct a `PinPtr`
from a valid `Pin<T>`. For this, we need to recall how [value categories][3]
work. Remember that an rvalue is either a temporary value that has no address,
or a temporary value that is "expiring". An lvalue is something that has an
address, and is neither of these. How these are represented in the type system,
however, may be surprising:

* `T&` can only represent an lvalue.
* `T&&` can only represent an rvalue.
* `const T&` can represent _either_ and lvalue or an rvalue.

The last point is critical! Objects of `Pin<T>` are only valid as lvalues, and
so it's only valid to construct a `PinPtr<T>` from a `Pin<T>&`--this is the
only way that we can ensure the pinned object will remain valid after the
constructor runs. With this in mind, we can add our constructors:

```
template<Value T>
class PinPtr {
public:
  // No default constructor!
  PinPtr() = delete;

  template<typename U>
  PinPtr(Pin<U>& pin) : m_value{pin.operator->()} {}
};
```

We template the constructor to allow polymorphic pointers. We can construct a
`PinPtr<T>` from a `Pin<U>` if `U` is a derived class of `T`. Prevailing wisdom
would have us declare the single-arg constructor as `explicit`, but I think
that's not necessary here. There is one--and only one--way to construct a
`PinPtr`. Requiring an explicit constructor call would not add clarity, and
would only add visual noise.

## Does It Really Work, Though?

The answer seems to be yes!

```
class Resource {};

class Borrows {
public:
    Borrows(PinPtr<Resource> resource) : resource_{resource} {}
private:
    PinPtr<Resource> resource_;
};

int main() {
    Resource r;
    Pin<Resource> pinned;

    // These fail to compile:
    // Borrows borrower{Pin<Resource>{Resource{}}};
    // Borrows borrower{&r};
    // Borrows borrower{Resource{}};

    // This is the only way to construct a Borrows:
    Borrows borrower{pinned};
}
```

## Conclusion

It's not a perfect bolt-on solution for temporal memory safety. In the previous
example, `PinPtr` cannot ensure that the lifetime of `pinned` outlives the
lifetime of `borrower`. Now that we're protected from pointer invalidation by
move/destruction, however, other temporal memory safety issues are
_theoretically_ harder to invoke _accidentally_, and easier to locate in code
inspection.

Whether this adds value, though, or visual noise, is up to you. It may feel odd
to represent a new semantic value category using a vocabulary type. If that's
the case, this likely isn't for you! I think it has the potential to prevent a
number of nasty UB issues, however, so I think I'm a fan of it! After trying to
use it, I'll give an update to see if that turned out to be the case.

[1]: https://en.cppreference.com/book/storage_durations
[2]: https://without.boats/blog/pin/
[3]: https://en.cppreference.com/w/cpp/language/value_category
