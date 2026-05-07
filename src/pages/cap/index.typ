#import "../stdlib.typ": info, warning, solution, chapter
#chapter[Capability-Passing Style] <sec:cap>

In this chapter we'll look at *capability-passing style*,
an approach to what's known as *effect handlers* or *algebraic effects*.
This is an approach to writing program with effects that avoids the problems of monads,
while still keeping the ability to compose and reason about effectful programs.
While we will discuss this side of capability-passing,
our main focus will be on capability-passing as a program architecture.
There are a couple of reasons for this.
One is that capability-passing is still somewhat experimental:
it's the topic of active research and language support is a work-in-progress.
The other is that I find it a really good architecture for certain cases,
and one that, perhaps surprisingly, has been demonstrated in many practical systems.

We'll begin by discussing capability-passing as an architecture.
We'll see it's a development of final tagless and dependency injection,
both topics of previous chapters.
To illustrate this we'll use capability-passing to implement a stripped down user interface library.
We'll then turn to the effect handlers,
describing them and some of the future work needed to fully realise that vision.
