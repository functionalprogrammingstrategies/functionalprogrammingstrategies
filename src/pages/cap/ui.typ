#import "../stdlib.typ": href, styled-table
== The Problems of User Interfaces

The starting point of implementing a capability-passing library is determining the capabilities.
We could do this by trial-and-error: by implementing a system, seeing what capabilities fall out, and refactoring.
In the case of user interfaces we can shortcut this process by examining the enormous quantity of prior work that tackles the problem.
This is a useful enough problem solving strategy that I've given it a name: *reading the literature*.
This name is both a nod to the #href("https://www.gutenberg.org/ebooks/3008")[Jargon File]
and a gentle exhortation to the working programmer to connect a bit more to the academic literature.
As I hope the references at the end of each chapter have shown, there are a lot of good ideas in said literature, many of which have been reinvented by working programmers.
In fact we'll see such an example in this case study.

Consider a user interface, similar to the Google home page, where the user enters text into an input and then presses a button.
The button is disabled until there is some text in the input, and pressing the button clears the input.

In pseudo-code, we might write

```scala
val i = Input("", placeholder = "Type something...")
val b = Button("Go!").disable()

i.onChange(value => if value.nonEmpty then b.enable() else b.disable())
b.onSubmit{ _ =>
  doSomething(i.value)
  i.clear()
  b.disable()
}

RowContainer(i, b).show()
```

This code is written in a callback-driven style.
There are already user interface frameworks that we can view as implementing a capability-passing approach (though I don't think this was a conscious design choice in any of them) but I've chosen the callback-driven style, used by the browser DOM and stretching back to Smalltalk and the first GUIs, as I suspect it will be more familiar.
The callback-driven approach focuses on the *components* representing what is displayed on the screen. `Input` and `Button` represent the text input and the button, respectively, and the `RowContainer` specifies the text input and button should be displayed in a row. We can see that components form a tree. We'll call this the *layout tree*.

*diagram here*

It's natural to focus on what we see on the screen, but this ignores another structure that is equally important: the flow of events. In the example above the input field `i` refers to the button `b`, to enable it, and the button `b` refers back to the input field `i`, to clear it. This means the event handling structure is a cyclic graph, which is a more complex structure than the layout tree. We'll call this the *event graph*.

*diagram here*

From this analysis we can identify two capabilities. The first is the layout capability, which is the ability to construct the layout tree.
The second is the event capability, which is the ability to construct the event graph.
Notice that there are two *stages* in the example above. The setup stage, where we define the user interface, is everything that happens before we call `show`. After that we're in the reactive stage, where the user interface responds to input events. This is another example of the separation between description and action that we have seen in the interpreter strategy. Setup is description and reactive is action. This will become important later when we restrict which capabilities are available in each stage.

Before we dive into building our system I want to look at an alternative to callbacks. In the callback-driven style, event handling is fragmented across a mess of callbacks and becomes difficult to reason about. We can introduce *reactive variables* to deal with this. A reactive variable is a time-varying value that is automatically updated when any of its dependencies change.

The code below shows how the same user interface might be represented with reactive variables.

```scala
val text = Var("")
val enabled = text.map(t => t.nonEmpty)

val i = Input(text).onChange(text.set)
val b = Button("Go!")
          .enabled(enabled)
          .onSubmit{ _ =>
            doSomething(text.now)
            text.set("")
          }

RowContainer(i, b).show()
```

`Var` creates a reactive variable with an initial value.
We use it to create `text`, which stores the text displayed by the `Input` component and starts as the empty `String`.
We assume that we can pass a reactive variable to an `Input`,
and it will automatically update the value displayed to the user (and held internally in the component) from that reactive variable.
Note, however, that we're not assuming the `Input` will update the reactive variable when the displayed value changes.
This would introduce *bidirectional data binding*, which is difficult to reason about.
We instead choose *unidirectional data binding*, which means updates flow into components from reactive variables but changes to reactive variables must be explicitly written.
This is why we update `text` when the `Input` changes.
We assume that `onChange` gives us the current value displayed by the `Input`.

From `text` we derive the reactive variable `enabled`, which determines if the button is enabled or disabled.
We assume we can set the `enabled` property on a `Button` component directly from a `Boolean` valued reactive variable.

Finally, when the `Button` is submitted we get the current value of `text`, using the `now` method,
and then clear `text`.
Clearing `text` causes changes to propagate, which end up clearing the `Input` and disabling the `Button`.

Notice that the invariant that the button is enabled only if the text is not empty is only stated once, when we define the `enabled` reactive variable as `text.map(t => t.nonEmpty)`.
In the callback-driven version this is spread across three places: the initial call to `disable`, the `onChange` handler, and the `onSubmit` handler.

Perhaps more importantly we can see that the reactive variables have broken the cycles in the code.
In the callback-driven code the `Input` refers to the `Button`, and the `Button` in turn refers to the `Input`.
These cyclic dependencies in turn require us to write the user interface in two steps:
by first creating all the components, and then adding the event handlers.
The reactive variables reify the vertices of the event graph.
This allows us to break the cycles by indirecting through the reactive variables.
The cyclic graph still exists dynamically, when the code runs, but it doesn't exist in the code itself.
This means the two step process is not needed, and we can write each component in one step.

There is a third capability hiding in the code: the ability to respond to changes in reactive variables.
Why treat this as a capability?
One reason is that we only want to allow changes to reactive variables in the reactive stage.
In the setup stage our reactive variables should be static,
otherwise the interface we end up constructing could depend on the order in which updates apply,
which will be difficult to reason about.
We also don't want reactive variables to update in an ad-hoc manner,
as this could lead us to observing incorrect intermediate values known as glitches.

In summary, we have seen we can distinguish two different stages in a user interface: the setup stage where we construct the user interface, and the reactive stage where we respond to user actions. We have also identified the following capabilities:

- layout, which is the ability to add components to the layout tree;
- event registration, which is the ability to register interest in particular events; and
- reaction, which is the ability to respond to changes in reactive variables.

Not all capabilities are available in both stages. We cannot react to events in the setup stage. We're also going to disallow layout and event registration in the reactive stage. This means the user interface cannot dynamically add and remove components or event handlers. This serves both to simplify the implementation, which is useful in a case study context, and illustrate how we can use the type system to prevent errors. The table shows which stage can use which capability.

#styled-table(
    columns: (auto, auto, auto),
    alignment: (left, center, center),
    table.header([Capability], [Setup Stage], [Reactive Stage]),
    [ Layout                ], [ Yes       ], [ No           ],
    [ Event registration    ], [ Yes       ], [ No           ],
    [ Reaction              ], [ No        ], [ Yes          ]
)

With all that background out of the way, we're ready to proceed to implementation!
