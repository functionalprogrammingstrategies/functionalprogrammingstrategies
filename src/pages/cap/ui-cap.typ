#import "../stdlib.typ": href, styled-table
== User Interfaces as Capabilities

In the previous section we analyzed a typical user interface implementation and extracted three capabilities spread across two stages.
We'll now turn to implementation, creating a framework for terminal user interfaces in a capability-passing style.

It will help to ground the discussion with an example.
In the previous section we considered an example with a text input and a button.
Here's that same example, this time written in the capability-passing framework we'll develop.

```scala
val app = FullScreen {
  val action = Var(text.Line(""))
  val enabled = action.map(_.isNonEmpty)

  Row(Size.wrapContent) {
    TextInput(
      Size(Measurement.Fixed(25), Measurement.WrapContent),
      action
    )

    Button(Size.wrapContent) { ctx ?=>
      ctx.enabledWhen(enabled)
      ctx.onSubmit {
        doSomething(action.peek)
        action.set(text.Line.empty)
      }
      Var(text.Line("< Go >"))
    }
  }
}

app.run(Terminal)
```

It looks similar to the code for the reactive variables example, but notice that layout and event handling are effects. For example, we ignore the result of the call to the `onSubmit` method on `ctx` (`ctx` represents a capability); it's the effect that is important, not the value the method returns.


=== Infrastructure

We've already investigated the terminal in @sec:tagless-final:codata. Our usage here will be much more advanced, building full user interfaces, and as result we'll require more infrastructure. This code isn't particularly relevant to capability-passing, so we'll just quickly sketch it here. See the full code in the #href("https://github.com/functionalprogrammingstrategies/code")[code repository] for details.

There are three broad categories of types in the infrastructure code:

1. representations of text that we can display;
2. representation of the screen we will display; and
3. measurements of various kinds.

Let's discuss each in turn.

In a terminal user interface we have to be careful when we display a `String`. If it contains certain characters, for example the newline `\n`, it could mess up rendering. For this reason we use the `Line` type within the `text` package. It represents text that will displayed on a single line in the terminal, and strips out characters that could mess up the display.

The `Buffer` is the core type we'll use to display the interface. This is simply a two-dimensional array of cells representing what will appear on the screen, along with styling information for each cell. We use the term "cell" because some characters, such as emojis, take up twice the width of a normal character. Each component should only write to a rectangular region of the terminal, and with the `Buffer` we can easily restrict them to the region they have been allocated. It's also much less error-prone to have a single type responsible for rendering than to delegate it to individual components. `Buffer` depends on a number of other types, such as those that represent styling, but this detail is not important to us here.

Finally, we have the types representing measurements. There are a surprisingly number of them, as we need to not only represent rectangular regions (`Rect`) and length and width (`Dimensions`) in terms of cells, but also constraints on components that we need for layout. The later we'll discuss in more detail when we discuss the layout algorithm.


=== Layout Capability

Layout is our first, and simplest, capability. There are two sides to this: the side that creates the layout tree, which is exposed to the application programmer, and the side that does layout, which is internal to the user interface runtime. Each side also corresponds to one of the two stages we identified earlier. Construction belongs purely to the setup stage, as we're disallowing dynamic changes to the layout tree. Layout itself belongs to the reactive stage. This means components can change their size in response to events, but we cannot add or remove components from the tree.

We'll start with the construction of the layout tree.
For the application programmer we only need to define an interface that allows adding a component to the tree.
The interface below does the job.

```scala
trait Layout:
  def addComponent(component: Component): Unit
```

This is an imperative interface, a decision that we can see as driven by both implementation and conceptual concerns.
Consider a pure interface, which would return a new `Layout` value upon calling `addComponent`:

```scala
trait Layout:
  def addComponent(component: Component): Layout
```

We'll implement capabilities, like `Layout`, using `given` values.
The pure interface won't work as a `given` value.
We would have to make the returned `Layout` itself a `given` value replacing the one already in scope,
which is not possible in Scala.

That's the implementation angle; now let's look at the conceptual argument.
It's quite simple: we've chosen to make `Layout` a capability, and capabilities are allowed to have effects.
In this case the effect is mutating the current layout tree.
We'll return to this point later *add xref* to discuss how this fits into the functional programming paradigm of composition and reasoning.

Later on we'll create a concrete implementation of `Layout`.
Now, though, we'll move on to the other side of `Layout`, the actual layout algorithm.
This algorithm will dictate what `Component` needs to provide,
which in turn will allow us to define the `Component` type and complete this section.

There are many ways we can express layout.
For example, we could say that the width of component A is twice that of component B,
and it's located immediately below component C.
This is a very expressive type of layout system, and implies a constraint based layout algorithm.
The downside of constraints is that they are complex to implement and can be slow to run.
At the other extreme we have completely fixed layout, where size and location must be expressed upfront in absolute terms.
We'll choose a middle ground, that allows for some expressivity and is reasonably performant and simple to implement.
Specifically, we'll allow components to express their desired size in one of two ways:

1. a fixed size; or
3. in terms of the space required by their children.

We'll further restrict components to take up rectangular regions, which is not especially onerous for a terminal user interface.
These constraints allow us to implement layout in a single pass, while still allowing reasonably expressive layout.

From this description we can derive the following requirements of components:
Firstly, parents must be able to inspect the desired size of their children, so when the parent's size is determined by the children it can calculate that size.
Secondly, a component must be able to determine how much space it consumes given the space that is actually available to it.
We will also need to be able to render a component to the `Buffer` once the layout is complete.

With these three requirements in hand, we can now consider if `Component` should be data or codata.
It doesn't seem feasible to define all possible components up-front, so a codata representation makes sense.
This suggests the following interface

```scala
trait Component:
  /** The space the components wishes to occupy. */
  def size: Size

  /** The space the component actually occupies given available space. */
  def measure(constraint: Constraint): Dimensions

  /** Draw the component to the buffer with the given dimensions. */
  def render(dimensions: Dimensions, buf: Buffer): Unit
```

The final step is to implement `Layout` and some components.
We'll start with an implementation of `Layout`.
This simply uses a mutable buffer to store the child components.

```scala
import scala.collection.mutable

trait DefaultLayout extends Layout:
  private[ui] val components: mutable.ArrayBuffer[Component] =
    mutable.ArrayBuffer.empty

  def addComponent(component: Component): Unit =
    components += component
object DefaultLayout:
  def apply(): DefaultLayout =
    new DefaultLayout {}
```

Now we need some components.
We'll show implementations for two:
a very simple component that displays a single line of text,
and a component that lays its children out in a row.

We need to add a final component, which will be the root of the component tree.

*Code here*

We now have enough to display some user interfaces!

*Example here*

However, our interfaces are entirely static.
We need the ability to respond to events to add interactivity.
This is what we turn to next.


=== Event Capability

Our next capability will allow us to respond to user input.
Although some terminals do support mouse events, for simplicity we'll only consider keyboard events.
Components will need the ability to respond to specific key presses, and in some cases all key presses.
The interface provided by the `Event` capability below will suffice.

```scala
trait Event:
  /** Register a handler that fires only for the given key. */
  def onKey(key: Key)(handler: => Unit): Unit

  /** Register a handler that fires for every key press. */
  def onAnyKey(handler: Key => Unit): Unit
```

This seems simple enough, but when we come to implement it we'll immediately run into some problems. Lets walk through them. We'll start by trying to implement a `DefaultEvent`, mirroring the `DefaultLayout` we created above.

```scala
import scala.collection.mutable

trait DefaultEvent extends Event:
  val keyHandlers: mutable.Map[Key, () => Unit]

  def onKey(key: Key)(handler: => Unit): Unit =
    keyHandlers += (key -> () => handler)
```

We immediately run into a problem.
Although we can implement `onKey`
(and `onAnyKey`, though I haven't shown this)
how are we going to use this?
Adding local state, the same trick that worked with `Layout`,
doesn't work here because we're lacking something to choose between handlers when a key pressed, and then call the chosen handler.
What we need is some kind of application-level state and control.

We've just run into three important concepts, in order of increasing abstraction:

1. the concept of focus, which determines the currently active component;
2. the idea of an application runtime; and
3. the concept of external interfaces—that is, those that address application concerns—versus internal interfaces, addressing framework concerns.

Focus is a well established concepts in user interface frameworks.
However this does not mean it is straightforward.
Our system will work as follows:
the unit of focus is the component, meaning that focus can apply only to components and not parts within components (unless those parts are themselves components).
A component will only become focusable when it has registered an event handler.
In this way focus is an implicit property of a component.
Finally, the order in which focus will traverse components will be determined by the order in which components register as focusable.

There are many reasonable semantics we could choose for focus.
If we look at other frameworks we can find other choices.
For example, HTML allows the application developer to determine the focus traversal order by setting the `tabindex` property.
In Jetpack Compose the `focusable` modifier must be explicitly used to make a component focusable.
What is important is not the specific semantics, within reason,
but that we consciously choose those semantics.
In our case, the semantics are designed to be convenient for the application developer (so focus is implicit) while keeping the implementation simple (so focus traversal order is fixed).

Let's move on to the runtime.
We motivated the runtime by saying we needed some kind of application-level state.
By digging deeper into focus, we've found that we also need to maintain the current focus and the focus traversal order.
The concept of a runtime, also known as an environment or execution context, is very common in a large system.
In our case the runtime is providing services to the rest of the framework.
We don't want the application to have access to the map of handlers, for example, because if it did the application could send events to the wrong handler.

We can think of the runtime as a capability that is provided to the rest of framework.
As a framework, not application, concern we shouldn't expose it the way we're exposing the application capabilities such as `Layout` and `Event`.
How, then, should we implement the runtime?
We could add methods to our capabilities, and use access modifiers to prevent the application from calling them.
For example, each `Event` could hold a reference to a `Runtime` as shown below.

```scala
trait Event(runtime: Runtime):

  def onKey(key: Key)(handler: => Unit): Unit =
    // Implement in terms of the runtime
    runtime.registerHandler(key, handler)
```

I don't like this approach, as it mixes application and framework concerns.
I prefer to keep the capabilties as pure interfaces providing only application capabilities.

Component is the right place: it's where we go from application to framework.
Notice that `Component` already provides methods that are a framework concern.
Layout is where components enter the framework, so adding a component now provides a runtime to the component.


=== Reactive Capability


=== An Example TUI


=== Limitations and Future Work

Our system is limited in many ways. Removing some of these limitations, such as the restriction on styling, is a straightforward change. We'll only address here the changes that require interesting architectural changes.

We made the conscious restriction that the layout cannot change once constructed. This is severe limitation.

Resource handling. Deregister handlers when a component is deleted.

Adding effects (in the Solid / React sense) to the reactive system.

The type system cannot prevent us capturing a capability and using it outside the scope when it is active. (Segue into next section.)
