#import "../stdlib.typ": exercise, solution, href
== Building Constraints <sec:types:constraints>

Most applications work by progressively adding structure to inputs.
We might receive data from, say, the network or a database.
We perform some checks on that data, and remove instances that are invalid.
Imagine we're implementing a sign up flow, asking for user name and email address.
Basic checks could be requiring names that are not empty, and email addresses that contain an `@`.
There will usually be multiple layers of checks.
For example, we might further validate email addresses
by sending them a verification email.

How should we represent these multiple levels of validation?
For example, how do we distinguish a random string from one that is an email address?
How about an unverified email from a verified one?
If you've worked on enough projects you're probably seen many approaches to this.
Many code bases use names in an ad hoc do this.
For example, we might use the name `email` and `verifiedEmail` to distinguish the different kinds of email addresses
in method parameters and data structure members,
while still representing both as strings.
#footnote[
    #href("https://en.wikipedia.org/wiki/Hungarian_notation")[Hungarian notation] is a more formal approach to
    this idea of encoding type information in names.
    Hungarian notation was popular within Microsoft and its ecosystem,
    but to the best of my knowledge it is no longer in common use.
]

Types provide a compelling alternative to naming schemes.
It provides all the advantages of naming schemes,
while also representing this information in a form the compiler can check for us.
For example, if we have `EmailAddress` and `VerifiedEmailAddress` types,
the compiler will tell us if we try to use an `EmailAddress` where a `VerifiedEmailAddress` is required.
This brings us to two principles:

1. Types should represent what we know about values, or in other words the invariants or constraints on values. A `String` could be any sequence of characters. A `VerifiedEmailAddress` is also a sequence of characters, but it's one that represents an email address that we have verified is active.

2. Whenever we establish an additional invariant or constraint we should change the type to reflect this additional information. So for example, an email address might start out as a `String`, become an `EmailAddress` if we have verified it looks like an email, and then become a `VerifiedEmailAddress` when we've successfully sent it a verification email and received a response.


=== Constraints Backwards and Forwards
