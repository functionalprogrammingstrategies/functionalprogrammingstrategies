#import "../stdlib.typ": chapter
#chapter[Types] <sec:types>

We'll start with a discussion of types.
Almost everything we'll see in this book will be represented in code as some variation of a type,
so it's appropriate we should start with a discussion of what a type is.

Types as constraints. Parse don't validate.

We'll see two different ways we can understand a type:

- by what it is, sometimes known as an *extensional* view; and
- by what it can do, sometimes known as an *intensional* view.

We'll finish by looking at Scala 3 feature, called as an *opaque type*,
that allows us to create distinct types that have the same runtime representation as another type.
