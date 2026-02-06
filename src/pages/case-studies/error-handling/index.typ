#import "../../stdlib.typ": info, warning, solution, chapter
#chapter[Error Handling] <sec:error-handling>

In this case study we'll look at error handling, a task that all sizable programs must address.
We'll tease apart the different kinds of errors a program may have, and the different roles they play.
We'll then explore the different tools in our toolbox for working with errors, and discuss where each is appropriate.


== Errors Are Not One Thing

Our starting point is dissect the different types of errors and the different needs we have for errors.

Errors can be broadly divided into two kinds: those that can plausibly be recovered from, and those that cannot.
The former often involves user input.
For example, if we cannot find any products in response to a user's query, we can ask the user to try a different query.
However, if we cannot find any products because we cannot connect to the database, there is probably little that the program can do to recover.
It might be that the database credentials are incorrect, or the network is down, or the database is down.
Either way, we're unlikely to have given our system the ability to recover from these problems.

The next dimension to consider is who will use the information in an errors.
Again, this can broadly be divided into two groups: users and programmers.
These groups often correlate with the previous two groups: recoverable errors are often ones of interest to users,
while programmers (or associated people, like system administrators) are usually the ones interested in unrecoverable errors.

In summary, there are broadly two kinds of errors: recoverable and unrecoverable errors. The former are usually of interest to users, while the latter are usually only of interest to programmers.

Context needed to determine what kind of error.

Multiple errors or first error?


== Requirements for Error Handling

All user errors be represented explicitly, so we can present them correctly.

All programmer errors include relevant internal details.

Must not expose programmer errors to users; security risk.


== Tools

Algebraic data type
