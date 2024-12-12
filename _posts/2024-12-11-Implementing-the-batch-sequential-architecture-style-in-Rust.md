---
layout: post
title: Implementing the batch-sequential architecture style in Rust
date: 2024-12-11 09:00:00
categories: design
---

As promised, this post is a follow up to my [previous post][1] with the details of how we've implemented a batch-sequential architecture pattern for the redfish-codegen project.

# Types that do work

The goal is to write code like this:

```
struct Hello;
impl Process<()> for Hello {
    type Output = String;
    fn process(self, input: ()) -> Self::Output {
        "Hello, world!".to_string()
    }
}

fn print_message(input: String) {
    println!("{}", &input);
}

Pipeline::builder()
    .stage(Hello)
    .stage(print_message)
    .execute();
```

Here, we can construct a pipeline, and then execute it. We don't care whether a
stage consists of a free function or a type `impl`. The pipeline ensures,
statically, that the input type of a stage is compatible with the output type
of the previous stage. To achieve this, we start with the trait `Process`:

```
pub trait Process<Input> {
    type Output;
    fn process(self, input: Input) -> Self::Output;
}
```

This type represents a procedure that consumes `self` (is terminating) from an
input value to an output. We can provide a blanket implementation for all
`FnOnce` closures:

```
impl<F, In, Out> Process<In> for F
where
    F: FnOnce(In) -> Out,
{
    type Output = Out;
    fn process(self, input: In) -> Out {
        self(input)
    }
}
```

# Composing a Pipeline

The next trait is `Stage`, and we can use it to combine stages to form our
pipeline:

```
pub trait Stage<P, In, Out>: private::Sealed {
    type Result<R>;
    fn stage<Q>(self, process: Q) -> Self::Result<Q>
    where
        Q: Process<Out>;
}
```

Note that I've [sealed][2] this trait. Other areas of the code should not be
implementing this trait. We'll implement this on a type `Pipeline`. Here's the
definition of `Pipeline`, with some of the cruft removed:

```
pub struct Pipeline<Proc, PreviousStage> {
    pub(super) process: Proc,
    pub(super) previous: PreviousStage,
}

impl<P, S, Input, Output> Stage<P, Input, Output> for Pipeline<P, S>
where
    P: Process<Input, Output = Output>,
{
    type Result<R> = Pipeline<R, Self>;
    fn stage<Q>(self, process: Q) -> Self::Result<Q>
    where
        Q: Process<Output>,
    {
        Pipeline {
            process,
            previous: self,
        }
    }
}
```

All this does is compose a new `Pipeline` containing the previous `Pipeline`.
You might refer to this type as _telescoping_, because its real type (as known
to the compiler) contains the type of its sub-pipeline...

...which of course, contains the type of its sub-pipeline (recursively).

# Executing a Pipeline

We know that we need a trait that can allow us to execute a stage, so let's
begin there:

```
trait RunStage {
    type Output;
    fn run_stage(self) -> Self::Output;
}
```

If `Process` is the category of types with a self-consuming function from an
input to an output, `RunStage` is the category of types that can execute a
`Process` and propagate its output value. I'll leave this for now, and we'll
come back to it in a moment.

Executing a pipeline requires executing each sub-pipeline. Earlier, while
showing the `Stage` trait, I left out one critical piece of information. What
is the nature of the pipeline's first stage? I've got a type called
`PipelineBuilder`. The name of this type should conjure an accurate depiction
of its actual qualities--it contains nothing interesting. Except, an
implementation of `Stage`:

```
impl Stage<(), (), ()> for PipelineBuilder {
    type Result<R> = Pipeline<R, ()>;
    fn stage<Q>(self, process: Q) -> Self::Result<Q>
    where
        Q: Process<()>,
    {
        Pipeline {
            process,
            previous: (),
        }
    }
}
```

So with this, if there exists a function `Pipeline::builder()` which returns a
`PipelineBuilder`, we can construct a `Pipeline`, given a process whose input
is the unit type `()`, and whose previous stage is also the unit type. This is
nice--it requires that the initial stage of a pipeline take no inputs.

What does this have to do with executing a pipeline, though? Since we know the
"head" of the pipeline is always the unit type, we can use this as a kind of
recursive "base case" and provide an `impl` for it:

```
impl RunStage for () {
    type Output = ();
    fn run_stage(self) -> Self::Output {
        ()
    }
}
```

You might have noticed that the output of this `impl` is _also_ the unit type,
which happens to _also_ be the input type of the next stage. Isn't that
beautiful? Finally, we can provide an implementation for `Pipeline`.

```
impl<P, R> RunStage for Pipeline<P, R>
where
    P: Process<<R as RunStage>::Output>,
    R: RunStage,
{
    type Output = P::Output;
    fn run_stage(self) -> Self::Output {
        let Self { process, previous } = self;
        process.process(previous.run_stage())
    }
}
```

The one thing I've left out is the trait `Execute`, which can be implemented in
terms of `RunStage`. It's so simple that I don't see any value to including it
here. I'll leave this and other details as an exercise to the reader, or you
can go and look at the [feature branch][3] where I've implemented some of this
stuff. Cheater!

With this, the redfish-codegen project should be in a good place to begin
applying this pattern in future work.

Thanks for reading!

[1]: {{page.previous.url}}
[2]: https://predr.ag/blog/definitive-guide-to-sealed-traits-in-rust/
[3]: https://github.com/AmateurECE/redfish-codegen/tree/feature/sequential-batch-processing
