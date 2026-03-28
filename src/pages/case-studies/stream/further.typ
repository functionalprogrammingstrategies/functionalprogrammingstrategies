== Further Enhancements

There are many more additions we could add to `Stream`.
For example, concurrency is a natural extension.
There are at least two ways that we could support concurrency:
via a concurrent pipeline of transformations, such as a concurrent `map`, and
by concurrent merging of streams.


For example, concurrency, error handling and recovery, and resource management are all useful features we might want in a production system.
However, we're going to stop the case study here as we have already illustrated all the major implementation techniques.
Additional features are not trivial, but don't require major changes to the foundation we've already built.
