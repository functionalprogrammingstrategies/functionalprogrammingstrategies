== How Capability-Passing Relates to Other Strategies

In this section we'll look at the relationship between capability-passing, tagless final (@sec:tagless-final), and dependency injection (@sec:di), and capability-passing and monads

We can view both capability-passing and tagless final as forms of dependency injection.

Both offer more than dependency injection. Tagless final addresses the expression problem. Capability-passing adds tracking of capability usage. There is also a shift in view point in capability-passing. We usually think of dependencies are peripheral to the code. As we saw in this example, capability can be central to the code.

All are interpreters, and all are variants of codata interpreters.


Capability-passing has a comonadic flavor. In a monad we write `A => F[B]`. In capability-passing we write `F[A] => B`, where `F` represents the required capabilities.

Deeper duality: in capability-passing we write in direct style and use continuations to reify control flow, the dual of monadic style.

Requiring side is comonadic, and providing side is monadic.
