---
layout: post
title: Value- and Risk-driven Design
date: 2024-10-31
categories: design
---

I've been favoring design methods lately that I would consider to be "Value-"
and/or "Risk-" driven. "Risk-driven" design methods, as I refer to them, are
well-documented. The book _Just Enough Software Architecture: A Risk-driven
Approach_ by George Fairbanks stresses a risk-driven method for software
architecture. There are international standards for various industries that
describe risk management processes proven to be successful in their target
industry:

 * IEC 61508 (safety-critical industrial applications)
 * ISO 14971 (medical devices)
 * ISO 26262 (typically automotive applications)

Usually, this involves identifying hazards (situations that cause harm) and
failure modes (events that can cause hazardous situations). An engineer then
assigns a risk level based on the probability of the failure mode occurring and
the severity of the harm. If the risk level is not acceptable, the engineer
identifies mitigations that reduce the risk to an acceptable level. There are
many tools to aid this process, including fault tree analysis, reliability
testing and hypothesis testing.

Value-driven design methods are not well documented, but they are universally
understood; probably, a number of things come immediately to mind. Here, the
term refers to design methods that either increase the inherent "value" of a
product or service, or decrease its cost. This can involve optimizing unit cost
or reducing non-recurring expenses. Often, it means planning to deliver the
highest value features within the stakeholder's financial constraints.

How do we identify the highest value work?

# The Source of Requirements

Let's forget about business requirements for this conversation. I find there
are two sources for the genesis of product requirements:

 1. Suffering
 2. Risk

In that order.

Really, _use cases_ are the primary source of requirements. But what generates
use cases? Ultimately, people make choices to lessen their suffering (or the
suffering of others; I do believe in empathy). So _suffering_, I think, is the
root cause of a use case.

We can capture and model a person's choices through _functionality scenarios_,
which describe the course taken by an actor with a goal as they navigate from
problem to solution (Fairbanks, 2010). Generally, these don't capture the pain
point that motivated an actor, and they also don't capture the system of
interest--they simply trace an actor's steps. Though, perhaps they _should_
capture motivation. If they did, it may be easier for us to develop empathy for
our customers and end users. Where I work, in the engineering services
industry, empathy is what brings work through the door.

Functionality scenarios can be used to identify and quantify use cases and
domain concepts. From there, we can begin to identify features and facets of
the system under interest, and visions of the solution space may begin to dance
in our heads. Use cases lend themselves to requirements, and requirements lend
themselves to code. We _know_ this process, and yet we frequently fail to apply
it.

On the other hand, though, engineering _generates_ risk. Our product may
provide services that ease suffering, but it likely also introduces _new_ ways
of creating suffering. What happens if our actor uses the product wrong, or the
product fails? Is the user better or worse off than they were to begin with?
What about our business? If our product fails, our name may become tarnished
and our employees may worry about feeding their families.

Risk-analysis is the activity that removes the barriers to joy. It helps us to
implement mitigations that protect our users, reduce technical risk, and finish
faster with a better product. Risk mitigations reveal non-functional
requirements. They also lend themselves naturally to architecture solutions.
Risk mitigations tend to be _intensional_--as in, related to design _intent_,
rather than solutions we can apply directly to our code and assemblies.
Consider, for example, a heterogeneous redundant solution in a high-SIL
application. We can _read_ the code and _see_ that two software units have a
similar function, but the average reader might jump to the conclusion that one
unit is dead code--a relic from a prototype. However, an engineer could create
an architectural _view_ that traces the redundancy directly to a risk
mitigation.

In the medical and aerospace industries, outputs of risk analysis activities
feed into product requirements and architecture. I consider
cybersecurity-related activities to also fall into this category. Planning to
apply cybersecurity process at the end of a project is planning to fail.

I imagine the forces of suffering and risk as being on either side of a
see-saw. On Monday, we may discover a new use case. On Wednesday, we look at
our product invariants, affordances, and our new architecture, and consider all
the new ways we've just constructed to fail.

# Designing the Design Process

_How_ we tackle a problem is more important than the problem itself. Lately,
I've had two questions ringing in my head:

> Do I know everything I need to know to succeed?
> What can I do today to be more sure of my success tomorrow?

This forces me to think about technical and project management risk. But it
also forces me to think about the problem statement, and the design process.
What's my customer's greatest pain point? What's the problem they're trying to
solve? How can I make sure I know the _right_ answer to these questions? How
will I make sure the patient is safe, even if my code fails?

This, I think, is the fundamental principle underpinning the design methods I'm
referring to: not applying a rote development process, not indifferently
applying a canned architecture style. Continuously evaluating the present to
ensure I'm solving the right problem today.

# Conclusion

I'm currently trying to apply this strategy on a program at work, where I'm
serving the team as their software architect. I'm also trying to apply this to
two projects at home: designing a backup system for my server, and building a
financial tool.

In the past, I've failed at developing solutions for these because I would
either fall victim to a form of analysis paralysis, and end up designing an
ivory tower, or repeatedly prototype something that doesn't solve the problem.
Do I really need a tool with a hundred views that graphs data in real time? Do
I really need that Redfish-enabled off-site RAID array? The answer would turn
out to be no, of course. Now, I'm hoping that this fresh perspective will help
me to apply just enough design to the right problem.

If you know about any books on this topic, reach out to me. This is an area
where I want to read and learn more.
