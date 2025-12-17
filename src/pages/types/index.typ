#import "../stdlib.typ": chapter
#chapter[Types] <sec:types>

Our very first strategy is using *types as constraints*.
We'll start by discussing two different ways we can think of types:
by what it is, sometimes known as an *extensional* view; and
by what it can do, sometimes known as an *intensional* view.
The latter view is necessary to get the most from an expressive type systems,
but is not as well known,
so we'll spend some time talking elaborating this view and the benefits it brings.
We'll finish by looking at Scala 3 feature, known as *opaque types*,
that allows us to create distinct types that have the same runtime representation as another type.
As such, opaque types allow us to separate representation from operations,
and work with just the extensional or intensional view as appropriate.
