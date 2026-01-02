---
layout: post
title: Evaluating Design Micro-Decisions with the Curry-Howard Isomorphism
date: 2025-08-30 14:00:00
---

# Which of these is better?

Design One:

```rust
use std::time::Duration;

/// Gateway to determining cumulative tack times. May have other methods, which
/// may perform reads from hardware, or increment internal counts, etc.
struct CumulativeTackTimes {
  // Omitted...
}

impl CumulativeTackTimes {
  /// The time spent on port tack
  pub fn port(&self) -> Duration {
    todo!()
  }

  /// The time spent on starboard tack
  pub fn starboard(&self) -> Duration {
    todo!()
  }
}

pub mod logic {
  pub mod spinnaker {
    pub enum Set {
      BearAway,
      Gybe,
    }

    pub fn set(times: CumulativeTackTimes) -> Set {
      todo!()
    }
  }
}
```

Design Two:

```rust
use std::time::Duration;

struct CumulativeTackTimes {
  pub port: Duration,
  pub starboard: Duration,
}

pub mod logic {
  pub mod spinnaker {
    pub enum Set {
      BearAway,
      Gybe,
    }

    pub fn set(times: CumulativeTackTimes) -> Set {
      todo!()
    }
  }
}
```

!! TODO: I'm pretty sure Uncle Bob has written about this before?
!! TODO: Bertrand Meyer definitely wrote about this before.
!! TODO: What about if we change design one to be a trait?
!! TODO: What if this is an architecture boundary?
!! TODO: How does the expression problem play into this?

The location of the state is the fundamental difference between these two
designs. In Design One, we're given a type that exposes methods for checking
cumulative port and starboard tack times. In Design Two, we're given an object
that contains them. Let's use the Curry-Howard Isomorphism to translate these
designs into propositions. Design One is translated roughly as:

Okay, now what about this design?

```rust
/// Gateway to determining cumulative tack times. May have other methods, which
/// may perform reads from hardware, or increment internal counts, etc.
struct CumulativeTackTimes {
  // Omitted...
}

impl CumulativeTackTimes {
  // A very-pointed query.
  pub fn time_on_starboard_exceeds_port(&self) -> bool {
    todo!()
  }
}

pub mod logic {
  pub mod spinnaker {
    pub enum Set {
      BearAway,
      Gybe,
    }

    pub fn set(times: CumulativeTackTimes) -> Set {
      todo!()
    }
  }
}
```
