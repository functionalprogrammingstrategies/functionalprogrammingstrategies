#import "../stdlib.typ": part

#part[Foundations] <sec:part:foundations>

In this first part of the book we're building the foundational strategies on
which the rest of the book will build and elaborate.
In @sec:types we discuss the role of types as representing constraints,
and see how we can separate representation and operations.
In @sec:adt we look at algebraic data types.
Algebraic data types are our main way of modelling data, where we are concerned with what things are.
We turn to codata in @sec:codata, which is the opposite, or dual, or algebraic data.
Codata gives us a way to model things by what they can do.
Abstracting over context, and the particular case of type classes, are the focus of @sec:type-classes.
Type classes allow us to extend existing types with new functionality,
and to abstract over types that are not related by the inheritance hierarchy.
The fundamentals of interpreters are discussed in @sec:interpreters, and are the final chapter of this part.
Interpreters give a clear distinction between description and action,
and are a fundamental tool for achieving composition when working with effects.

These five strategies all describe code
artifacts. For example, we can label part of code as an algebraic data type or a
type class. We'll also see strategies that help us write code but don't
necessarily end up directly reflected in it, such as following the types.

