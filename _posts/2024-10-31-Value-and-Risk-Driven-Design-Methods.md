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
architecture. There are standards in use in various industries that define risk
analysis and risk-driven design methods:

 * IEC 61508 (safety-critical industrial applications)
 * ISO 14971 (medical devices)
 * ISO 26262 (typically automotive applications)

These standards describe risk management processes that are proven to be
successful in their target industry--but there's a lot of similarity between
them.

Value-driven design methods are not well documented, but they are universally
understood; probably, you can already guess what I mean. Here, the term refers
to design methods that improve the value of a product or project--by increasing
the usefulness of a product or service, or decreasing its cost.

# The Source of Requirements

Putting aside business requirements, I find there are two sources for the
genesis of product requirements:

 * Suffering
 * Risk-analysis

Really, _use cases_ are the primary source of requirements. But what generates
use cases? Ultimately, people make choices to lessen their suffering (or the
suffering of others--I do believe in empathy). So _suffering_, I think, is the
root cause of a use case.

We can capture and model a person's choices through _functionality scenarios_,
which describe the course taken by an actor with a goal (Fairbanks, 2010).
Generally, these don't capture the pain point that motivated an actor, and they
also don't capture the system of interest--they simply trace an actor's steps.
Though, perhaps they _should_ capture motivation. If they did, it may be easier
for us to develop empathy for our customers and end users. Where I work, in the
engineering services industry, empathy is what keeps me from going mad.

Functionality scenarios can be used to identify and quantify use cases and
domain concepts. From there, we can begin to identify features and facets of
the system under interest, and images of the solution may begin to dance in our
heads.

On the other hand, though, engineering _generates_ risk. Our product may
provide services that ease suffering, but it likely also introduces _new_ ways
of suffering. What happens if our actor uses the product wrong, or the product
fails? Is the user better or worse off than they were to begin with? What about
our business? If our product fails, our name may become tarnished and our
employees may worry about feeding their families.

Risk-analysis is the activity that removes the barriers to revenue. It helps us
to implement mitigations that protect our users, reduce technical risk, and get
to market sooner with a better product. It also lends itself naturally to
architecture solutions. Risk mitigations tend to be _intensional_--as in,
related to design _intent_, rather than solutions we can apply directly to our
code and assemblies. In the medical and aerospace industries, outputs of risk
analysis activities feed into product requirements and architecture. I consider
cybersecurity-related activities to also fall into this category. Planning to
apply cybersecurity process at the end of a project is planning to fail.

I imagine these two forces as being on either side of a see-saw. On Monday, we
may discover a new use case. On Wednesday, we look at our product invariants,
affordances, and our new architecture, and consider all the new ways we've just
constructed to fail.

# Designing the Design Process

_How_ we tackle a problem is more important than the problem itself. Lately,
I've had two questions ringing in my head, like a tape on repeat:

> Do I know everything I need to know to succeed?
> What can I do today to be more sure of my success tomorrow?

This forces me to think about technical and project management risk. But it
also forces me to think about the problem statement, and the design process.
What's my customer's greatest pain point? What's the problem they're trying to
solve? How can I make sure I know? How will I make sure the patient is safe,
even if my code fails?

This, I think, is the fundamental principle underpinning the design methods I'm
referring to: not applying a rote development process, not indifferently
applying a canned architecture style, but continuously evaluating my status to
evaluate whether I'm solving the right problem today.

# Conclusion

I'm currently trying to apply this strategy to a program at work, where I'm
serving the team as the software architect. I'm also trying to apply this to
two projects at home: designing a backup system for my server, and building a
financial tool.

In the past, I've failed at developing solutions for these because I would
either fall victim to a form of analysis paralysis (designing an ivory tower)
or repeatedly prototype something that doesn't address my needs. Do I really
need a tool with a hundred views that graphs data in real time? Do I really
need that Redfish-enabled off-site RAID array? The answer would turn out to be
no, of course. Now, I'm hoping that this fresh perspective will help me to
apply just enough design to the right problem.
