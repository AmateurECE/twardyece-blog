---
layout: post
title: "From Problem to Solution"
date: 2024-11-11
categories: [design]
---

# From Problem to Solution

I often struggle to organize and prioritize my ideas. Time is precious, and I'd
prefer to spend it with love ones, relaxing, and practicing self care, but my
time spent tinkering is also very important to me. Today, I did some semantic
modeling to understand the motivation for the work I do in my free time, and I
came up with this model:

![Semantic Model of Problem Solving and Motivation](/assets/images/2024-11-11/module.svg)

In this model, a _Feature_ is an increment of work; a thing that I spent time
to accomplish. My takeaway was that there are three motivations for completing
_Features_:

1. To enable a _Use Case_.
2. To mitigate a _Risk_.
3. To advance a _Goal_.

I think that completely captures the solution space. I won't explain every
relationship in the diagram, since the relationships speak for themselves.
There are a couple of details not represented in this diagram that deserve a
little explaining, however.

# Solvable Problems

This model exists so that I can focus my creativity to develop solutions to
problems. The starting point is to recognize when a need arises and to identify
the next step. The fundamental assumption of this process is that the _Problem_
statement is the genesis of the product--that there exists some hypothetical
product or process which is capable of addressing the need underlying the
problem statement. Obviously, some problems can't be solved with products or
processes. I'm sure you have no trouble thinking of one. _Some_ of these
problems can be decomposed further into problem statements that _do_ uphold
this assumption, however.

# The Genesis of Product

In my last post, I wrote about the source of requirements. You might notice
that I only listed two sources of requirements there, but there's a third thing
here that motivates my work--_Goals_, which are driven by _Values_. I hope you
won't find me naive if I say that values are generally _not_ a motivating
factor in industry. My employer defines a set of values, but they only inform
_how_ I accomplish my work. They do not dictate _what_ I work on. Conversely, I
as an individual can form a value statement around the accessibility and
quality of open source software. That's enough justification to make
contributions to the Linux kernel. I'd be surprised if businesses were making
decisions in the same way. That's why I included it here.

# Use Case Subtypes

I often work with a subtype of _Use Cases_ with which any software developer
ought to be familiar: _User Stories_. I chose to omit it from the diagram to
minimize visual noise. Here, I consider a user story to be a subtype of a use
case because it has more constraints than a use case often does: a user story
contains the use case built into its statement, and includes the user's
motivation. The latter is usually omitted from a canonical Use Case
description. It may be the case that the next logical step, after capturing a
problem statement, may be to conceive a _User Story_ that addresses the
underlying need, especially if the solution to the problem involves a great
amount of technical detail not suitable for a high-level use case, or if the
motivation isn't inherently clear from the solution.

# Risk Subtypes

There are also two implicit subtypes of _Risk_ not captured in the model.

A _Program Risk_ is a risk that I will fail to implement my objective. For
example, if I'm working with a new technology to implement a feature, there may
be a chance that I misunderstand the technology and fail to implement the
product in a useful manner. I may choose to mitigate this risk by doing some
investigation or prototyping to burn down the risk.

I'll refer to the other type of risk as _System Risk_. This is the risk that a
user, while acting on my product to achieve their goal, will fail or experience
harm. These are usually mitigated with tools like _invariants_, which enforce
rules on the ways that a user can interact with a product based on its state,
or with _architectural features_, which support a qualitative architectural
characteristic, such as quality or reliability.

Both kinds of risk impede my _Goals_ and _Use Cases_, which is why I didn't
draw the distinction in the model.

# Conclusion

My plan is to refer back to this model from time to time, to calibrate my
process for tinkering. The goal here was not to create a new process, but to
model the process I'm already using, to be able to understand and reason about
it more effectively in the future. I'll provide updates in the context of my
projects in future posts!
