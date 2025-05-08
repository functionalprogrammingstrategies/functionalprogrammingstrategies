## Conclusions {#sec:indexed-types:conclusions}


The earliest reference I've found to phantom types is @10.1145/331960.331977.

The majority of research on generalized algebraic data types (indexed data) focuses on type checking and inference algorithms, which is not so relevant to the working programmer.
@10.1145/1708016.1708024 is not different in this respect, but it does have a particularly clear breakdown of how GADTs are used in the most common case.


Indexed codata is described in [@10.1145/3022670.2951929].

Fluent APIs. [@Roth_2023]

The probability monad we developed, which is specialized to sampling data, is only one of many possibilities. 
Sampling gives us an approximate representation of a distribution. Small discrete distributions can be represented exactly.
@ERWIG_KOLLMANSBERGER_2006 show how this can be done, in addition to the sampling approach we used. @kidd07:prob shows how the exact and sampling approaches can be factored into monad transformer stacks. 
@scibior15:monads uses probability monad as the underlying abstraction on which a variety of different statistical inference algorithms are defined. This is application of the idea of multiple interpretations that we have stressed throughout this book. @scibor18:modular expands on this idea, breaking down inference algorithms into reusable components.

We introduced the probability monad in the context of property based testing [@claessen00:quickcheck].
Randomly generating test data is not the only approach. 
@runciman09:smallcheck describes an elegant way of enumerating data.
Also see @duregard12:feat for an approach specialized to enumerating algebraic data types.
More recently machine learning techniques are being explored. See, for example, @reddy20:rlcheck and @lemieux23:codamosa.
@goldstein24:practice is an interesting case study of property based testing in practice.
