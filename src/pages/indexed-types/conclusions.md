## Conclusions {#sec:indexed-types:conclusions}


The earliest reference I've found to phantom types is @10.1145/331960.331977.

The majority of research on generalized algebraic data types focuses on type checking and inference algorithms, which is not so relevant to the working programmer.
@10.1145/1708016.1708024 is not different in this respect, but it does have a particularly clear breakdown of how GADTs are used in the most common case.


Indexed codata is described in [@10.1145/3022670.2951929].

Fluent APIs. [@Roth_2023]

We briefly touched on the application of the probability monad to property based testing. 

Statistical inference is another use of the probability monad. In this domain we build a probability model or stochastic model of some domain of interest, and then attempt to infer some values in that domain from observations. For example, we might have a map of the world and a model of the uncertainty in a robot's sensors, and attempt to estimate where the robot is located in the map based on this information and observations from its sensors. @scibior15:monads describes how the probability monad can be used to build a general system, called a probabilistic programming language, to tackle these tasks.
