#import "../stdlib.typ": exercise, solution, href
== Building Constraints <sec:types:constraints>

Most applications work by progressively adding structure to inputs.
We might receive data from, say, the network or a database.
We perform some checks on that data, and remove instances that are invalid.
Imagine we're implementing a sign up flow, asking for user name and email address.
Basic checks could be requiring names that are not empty, and email addresses that contain an `@`.
There will usually be multiple layers of check.
For example, we might further validate email addresses
by sending them a verification email to them.

How should we represent these multiple levels of validation?
For example, how do we distinguish a random string from one that is an email address?
How about an unverified email from a verified one?
If you've worked on enough projects you're probably seen many approaches to this.
Most code bases use names in an ad hoc do this.
For example, we might use the names `email` and `verifiedEmail` to distinguish the different kinds of email addresses.
#href("https://en.wikipedia.org/wiki/Hungarian_notation")[Hungarian notation] is a semi-formal approach to naming
that was popular within Microsoft and spread from there.

Types provide a compelling alternative to naming schemes.
The advantage, of course, is that the compiler checks types and tells us if we've gone wrong.
If we have `EmailAddress` and `VerifiedEmailAddress` types,
we cannot use an `EmailAddress` where a `VerifiedEmailAddress` is required.
This brings us to two principles:

- types should represent invariants or constraints on inputs;
- whenever we establish an additional invariant or constraint we should change the type.

So for example, an email address might start out as a `String`, become an `EmailAddress` if we have verified it looks like an email, and then become a `VerifiedEmailAddress` when we've successfully sent it a verification email and received a response.

#href("https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/")[Parse, don't validate]
