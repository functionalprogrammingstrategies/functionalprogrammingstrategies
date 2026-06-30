#import "../stdlib.typ": href, styled-table
== User Interfaces as Capabilities

In the previous section we analyzed a typical user interface implementation and extracted three capabilities spread across two stages.
We'll now turn to implementation, creating a framework for terminal user interfaces.


=== Infrastructure

We've already investigated the terminal in @sec:tagless-final:codata. Our usage here will be much more advanced, building full user interfaces, and as result we'll require more infrastructure. This code isn't particularly relevant to capability-passing, so we'll just quickly sketch it here. See the full code in the #href("https://github.com/functionalprogrammingstrategies/code")[code repository] for details.

The `Buffer` is the core type we'll use to display the interface. This is simply a two-dimensional array of characters representing what will appear on the screen. Each component should only write to a rectangular region of the terminal, and with the `Buffer` we can easily restrict them to the region they have been allocated. It's also much less error-prone to have a single type responsible for rendering than to delegate it to individual components.

The `Buffer` and related types. No styling (no bold, or underline, or blink, etc.) Only single character width, meaning no emojis or CJK characters.

`Text` and `Line`.


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
In the implementation we will pass around a `given` value implementing `Layout`.
A pure interface would return a new `Layout` value.

```scala
trait Layout:
  def addComponent(component: Component): Layout
```

This won't work as a `given` value; we would have to make the returned `Layout` itself a `given` value replacing the one already in scope.
This is not possible in Scala.

Conceptually, we've chosen to make `Layout` a capability, which means that calls to `Layout` are allowed to have effects.
In this case the effect is mutating the current layout tree.
We'll return to this point later *add xref* to discuss how it fits into the functional programming model.

Later on we'll create a concrete implementation of `Layout`.
Now, though, we'll move on to the other side of `Layout`, the actual layout algorithm.
This algorithm will dictate what `Component` needs to provide,
which in turn will allow us to define the `Component` type and complete this section.

There are many ways we can express layout.
Constraint based layout gives a very expressive system.
For example, we could say that the width of component A is twice that of component B,
and it's located immediately below component C.
The downside of constraints is that they are complex to implement and can be slow to run.
At the other extreme we have completely fixed layout, where size and location must be expressed upfront in absolute terms.
We'll choose a middle ground, that allows for some expressivity and is reasonably performant and simple to implement.
Specifically, we'll allow components to express their desired size in one of three ways:

1. a fixed size;
2. as a proportion of parent's available space; or
3. in terms of the space required by their children.

We'll further restrict components to take up rectangular regions, which is not especially onerous for a terminal user interface.
These constraints allow us to implement layout in a single pass, while still allowing expressive layout.

From this description we can derive the following requirements of components.
Firstly, parents must be able to inspect the desired size of their children so they can determine if they need to calculate how much space to allocate to the child or defer that calculation to the child.
Secondly, a component must be able to measure how much space it consumes given the space that is actually available to it.
Finally, we must be able to render a component to the `Buffer`.

With these three requirements in hand, we can now ask ourselves if `Component` should be data or codata?
It doesn't seem feasible to define all possible components up-front, so a codata representation makes sense.
This suggests the following interface

```scala
trait Component:
  /** The space the components wishes the occupy. */
  def size: Size

  /** The space the component actually occupies given available space. */
  def measure(constraint: Constraint): Dimensions

  /** Draw the component to the buffer with the given dimensions. */
  def render(dimensions: Dimensions, buf: Buffer): Unit
```

where we define the ancillary types as

```scala mdoc:silent
/** Concrete cell dimensions: the actual width and height of a component after
  * layout has been resolved.
  */
final case class Dimensions(width: Int, height: Int):

/** The layout size of a component: a measurement for each axis. */
final case class Size(width: Measurement, height: Measurement)

/** A Measurement expresses a dimension of size in terms of a fixed number of
  * cells, a portion of the parent's space, or in terms of the space occupied by
  * children.
  */
enum Measurement:
  /** Exactly `cells` */
  case Fixed(cells: Int)

  /** Exactly match the aggregate size of children elements. */
  case WrapContent

  /** A fraction of the parent container's remaining size after placing fixed size
    * and wrap to content children.*/
    */
  case Percentage(percent: Double)

/** Represents an unbounded amount of space in a Constraint. */
sealed trait Infinity
object Infinity extends Infinity

/** A range of acceptable sizes a parent offers a child during measurement.
  *
  * `min == max` on an axis is a *tight* constraint ("you must be exactly
  * this"); `min == 0` is *loose* ("take what you need, up to max"). A `max` of
  * [[Infinity]] means unbounded — the child may be as large as it likes.
  */
final case class Constraint(
    minWidth: Int,
    maxWidth: Int | Infinity,
    minHeight: Int,
    maxHeight: Int | Infinity
):
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

=== Event Capability


=== Reactive Capability


=== An Example TUI


=== Limitations and Future Work

Our system is limited in many ways. Removing some of these limitations, such as the restriction on styling, is a straightforward change. We'll only address here the changes that require interesting architectural changes.

We made the conscious restriction that the layout cannot change once constructed. This is severe limitation.

Resource handling. Deregister handlers when a component is deleted.

Adding effects (in the Solid / React sense) to the reactive system.

The type system cannot prevent us capturing a capability and using it outside the scope when it is active. (Segue into next section.)
