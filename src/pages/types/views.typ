#import "../stdlib.typ": exercise, solution
== Sets and Constraints <sec:types:views>

What is a type?
One way of answering this question quickly veers into mathematics and philosophy.
There are some references in the conclusions if you want to follow this direction.
However, here we'll answer this question from the programmer's perspective.

One perspective is that types are sets of values.
For example, an `Int` in Scala is 32-bits and as such can represent one of 4,294,967,296 possible values.
This is a common view, particularly among people who see types as primarily serving the compiler.
When we think of types in terms of how data is represented
we are working with the information the compiler needs to allocate memory for values,
and to generate instructions that operate on those values.
As mentioned in the introduction, this an extensional view,
meaning the concept of a type is defined by specifying all the values of that type.

The extensional view doesn't provide any *encapsulation* or *information hiding*.
Knowing the representation can be a problem when that integer represents, say,
an index into an array, or an age, or a timestamp.
In these cases we have access to a whole range of operations
that aren't meaningful on the data.
For example, neither indices nor ages can be negated,
but nonetheless we can negate any integer that is represented as an `int`.
Furthermore, as we'll see in @sec:indexed-types,
it can be useful to have types that have no representation.

This brings us to an alternate view of types,
the intensional view.
Instead of thinking of a type in terms of its representation,
we can think of a type in terms of the conditions, invariants, or constraints that hold for elements of that type.
This may in turn imply a set of operations that are valid on our types.
With this view we can ensure our ages are always non-negative,
our names are not empty strings,
and our email addresses are case insensitive.

We might argue that our `Int` example above
_is_ defined by a constraint: namely it's an integer that fits into 32-bits.
This is true!
This constraint also implies which operations are available on `Int`.
We cannot, for example, try to convert an `Int` to upper case;
this is meaningless.
Remember that we're taking two different views on the same concept.
It's expected that we can translate between these views in many cases.
The problem is the purely extensional view couples operations and representation.
We cannot represent, say, a timestamp as an `Int`
and not make meaningless bitwise operations available
if we only have the extensional view.

Decoupling operations and representation sounds a lot like programming to an interface.
Indeed this is true, and we'll look at this in much more detail in @sec:codata.
In this chapter we'll look at opaque types, which directly decouple type and representation,
allowing us to reuse a representation as a different type.
However, before doing so I want to spend more time on the mindset shift that the intensional view promotes.
