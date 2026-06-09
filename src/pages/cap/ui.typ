== The Problems of User Interfaces


The starting point of implementing a cpaability based library is determining the capabilities.
We could do this by trial-and-error: by implementing a system, seeing what capabilities fall out, and refactoring.
However, in this case we have a lot of prior work to we can use; there are many UI frameworks with a variety of different approaches. These frameworks are not necessarily explicitly using capabilities, but we can analyse them to see the core tasks they undertake, will inform the capabilities we need to provide.

...exposition here...

In summary, we have seen we can distinguish two different stages in a user interface: the setup stage where we construct the user interface, and the reactive stage where we respond to user actions. We have also identified the following capabilities:

- layout, which is the ability to add components to the layout tree;
- event registration, which is the ability to register interest in particular events; and
- reaction, which is the ability to respond to events we registered an interest in.

Not all capabilities are availabe in both stages. We cannot react to events in the setup stage. We're also going to disallow layout and event registration in the reactive stage. This means the user interface cannot dynamically add and remove components or event handlers. This serves both to simplify the implementation, which is useful in a case study context, and illustrate how we can use the type system to prevent errors.

... diagram here ...

We're going to create a framework for terminal user interfaces. We've already using the terminal in @sec:tagless-final:codata. Our usage here will be much more advanced, building full user interfaces. As result we'll require more infrastructure. This code isn't particularly relevant to capability-passing, so we'll just quickly sketch it here. See the full code in the code repository **link here** for details.


User interfaces are difficult to create. This is in part because user interfaces have an enormous amount of detail; there's just a lot of stuff to write for a good user interface. That's not the problem we're considering here. Rather, we're concerned with the architecture. That is, the way in which the user interface author expresses the structure of the user interface, as mediated by the framework they use.

Consider a user interface, similar to the Google home page, where the user enters text into an input and then presses a button.
The button is disabled until there is some text in the input, and pressing the button clears the input.
In pseudo-code, we might write

```scala
val i = Input("", placeholder = "Type something...")
val b = Button("Go!").disable()

i.onKey(_ => b.enable())
b.onSubmit{ _ =>
  doSomething(i.value)
  i.clear()
  b.disable()
}

RowContainer(i, b).show()
```

This code is written in a callback-driven style. It will be familiar to many from the browser DOM, but this model stretches back to Smalltalk and the first GUIs.

The callback-driven approach focuses on the *components* representing what is displayed on the screen. `Input` and `Button` represent the text input and the button, respectively, and the `RowContainer` specifies the text input and button should be displayed in a row. We can see that:

1. Components are values. We can pass them around and combine them to produce new components, as we do when passing `i` and `b` to the `RowContainer`.
2. Components form a tree. We'll call this the *layout tree*.

*diagram here*

It's natural to focus on what we see on the screen, but this ignores another structure that is equally important: the flow of events. In the example above the input field `i` refers to the button `b`, to enable it, and the button `b` refers backs to the input field `i`, to clear it. This means the event handling structure is a cyclic graph, which is a more complex structure than the layout tree. We'll call this the *event graph*.

*diagram here*

It is difficult to express cyclic structures in code. The callback-driven solution is to write user interfaces in a two stage process. First we create all the components. Now that we can reference any component of interest we add callbacks to define the event handling structure. Layout is straightforward to read in this model, but event handling is fragmented across a mess of callbacks and becomes difficult to reason about.

In summary, user interfaces require we define two structures: layout and event handling. Layout is a tree, but event handling is a cyclic graph. To further complicate things, the layout tree and event graph have references to each other. How different architectures handle this is the core of what we'll examine when we look at contemporary frameworks.
