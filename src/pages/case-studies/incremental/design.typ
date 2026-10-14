== Designing Incremental Computing

We're going to design our incremental computing by applying strategies, just as we did in @sec:case-study:reactive:design. I want to once again note that reading the literature is an very appropriate strategy to use here---see the literature review in @sec:case-study:incremental:conclusions---but we're once again going to take the harder route and build it from scratch.

We'll start with the API.
Incremental programming is very similar to reactive programming.
The main difference is that reactive streams have a value at a given point in time (but not perhaps at other points in time) while an incremental computing signal always has a value.
This means the APIs can largely be the same.
The methods that don't carry across to incremental computing at ones that work with some notion of time.
We didn't implement many of these, so we can carry across the API with little change.

Following Javascript naming conventions:

- Signal
- computed
- writable signal

API: we can implement the usual combinators. Lets start with a limited set.

We could reify, but we saw an extensive case study on this in @sec:case-study:reactive. Instead we'll take a codata approach.

Implement. Straightforward.

We're done?

Let's think about semantics. Dependency update when they are observed; *lazy*. Seems reasonable (only recompute when you need) but we do too much work: recomputing the entire tree when we could stop short. What's the alternative. The dual, *eager* seems natural. Recompute whenever a dependency changes.

How do we implement? Pull demands flows from downstream to upstream and results flow upstream to downstream. Push inverts this. CPS. Listeners.

Critically relies on single threaded assumption.

This again is inefficient: recompute values that are never needed. What about: eagerly mark what needs recomputing, but only recompute when needed. Eager / lazy or push-pull following reactive terminology. A classic space-time tradeoff: use more memory to avoid computation.


=== Dynamic Dependencies

We've dodged `flatMap`. We'll now address it. What makes `flatMap` hard? It introduces dynamic dependencies. A signal may not always be a dependency of another signal.

Subscribers and unsubscribe.


=== Direct Style

Get rid of combinators. Pass context as given value.
