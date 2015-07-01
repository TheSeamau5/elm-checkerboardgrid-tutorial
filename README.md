# Checkerboard Grid Tutorial

In this tutorial, we'll see how we can make a [checkerboard](https://en.wikipedia.org/wiki/Checkerboard) grid in Elm where each cell contains an independent, self-updating counter. The goal is to understand more about the [Elm Architecture](http://elm-lang.org/guide/architecture) by exploring container components and how to handle problems such as layout and update when dealing with nested components.

You will learn a lot in this tutorial. Concretely, you will learn:

  - The basics of the Elm Architecture
  - How to make a simple counter component in elm-html
  - How to make a grid component
  - How addresses work
  - How to deal with nested actions and updates
  - What is a context
  - How to convert between contexts in order to ensure your components are as generic as possible


## Pre-requisites

This tutorial uses [Elm](http://elm-lang.org/) and [elm-html](http://package.elm-lang.org/packages/evancz/elm-html/3.0.0). While familiarity with both is preferred, I will try to assume as little as possible. Please refer to the Elm docs if anything is confusing or alien. Although, it is important to first read up on the [Elm Architecture](http://elm-lang.org/guide/architecture) before starting as this tutorial seeks to expand upon the Architecture. Passing knowledge of CSS is helpful.

As such, assume the following libraries:
  - [elm-html] (http://package.elm-lang.org/packages/evancz/elm-html/3.0.0)
  - [start-app] (http://package.elm-lang.org/packages/evancz/start-app/1.0.0)

Furthermore, assume the following imports

```elm
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Signal exposing (Address)
import List
import Window
import Color exposing (Color)
```

and the following helper code to aid code readability and usability

```elm
infixl 2 =>
(=>) = (,)

type alias Vector =
  { x : Float
  , y : Float
  }

toRgbaString : Color -> String
toRgbaString color =
  let {red, green, blue, alpha} = Color.toRgb color
  in
      "rgba(" ++ toString red ++ ", " ++ toString green ++ ", " ++ toString blue ++ ", " ++ toString alpha ++ ")"
```

Finally, assume that the grid component resides in a file called `Grid.elm` that defines the `Grid` module

```elm
module Grid where
```

and that the Counter component resides in a file called `Counter.elm` that defines the `Counter` module

```elm
module Counter where
```

and that we can try both out in a separate file called `Main.elm` with the following imports

```elm
import Grid
import Counter
```

## Modeling the Problem

We know that our goal is to have a grid and a bunch of counters. We can use this information to divide our problem into two smaller problems: a grid and a counter. Counters sound easy, so let's start with that.

### A Counter Component

At the very basic level, a component that uses elm-html can be modeled as follows:

```elm
initial : State
update  : Action -> State -> State
view    : Address Action -> State -> Html
```

- `initial` refers to the initial state the component starts at. In the case of a counter, the initial state would be 0
- `update` is a function that updates the state of the component given some action
- `view` is how we view the component as HTML. The `Address` part refers to the fact that UI will need to send back actions, when clicked or hovered for example, and thus the address will allow this. We will come back to this point later.


The State of a counter is very simple, it is just an integer

```elm
type alias State = Int
```

with an initial state of 0

```elm
initial : State
initial = 0
```

A counter can be either incremented or decremented

```elm
type Action
  = Increment
  | Decrement
```

And given, these actions we can update a counter as follows

```elm
update : Action -> State -> State
update action state =
  case action of
    Increment ->
      state + 1

    Decrement ->
      state - 1
```


Now, to view a counter, all we need are two buttons and a some text where the current counter value will go

```elm
view : Address Action -> State -> Html
view address state =
  Html.div
      []
      [ Html.button  -- The increment button
            [ Html.Events.onClick address Increment ]
            [ Html.text "+"]
      , Html.button  -- The decrement button  
            [ Html.Events.onClick address Decrement ]
            [ Html.text "-" ]
      , Html.span    -- The text with the current counter value
            [ ]
            [ Html.text (toString state) ]
      ]
```
---
Note on Addresses:

The `address` defines where the action will be sent. For example, the line

```elm
Html.Events.onClick address Increment
```
says that, when the button is clicked, `address` will be sent the action `Increment`.

An address is merely part of a mailbox

```elm
type alias Mailbox a =
  { address : Address a
  , signal  : Signal a
  }
```  
---

And, whenever a message is sent to the address, the corresponding signal is updated.


And, that's it, this component is fully defined. All we needed were two functions and two type definitions.

*ASIDE:
If you wish to try this component, you can use StartApp and add the import line*

```elm
import StartApp
```
*you can then, in `main` say,*

```elm
main =
  StartApp.start
    { model  = initial
    , view   = view
    , update = update
    }
```

*And you have a working counter.*


### A Grid Component

Now that we have a working counter, let's make a grid. Unlike a counter, a grid is mainly there to house multiple components. As such, we need to be as general as possible when defining the grid and thus making zero assumptions on the types of components housed in the grid.

The way the grid works is that it is a collection of cells, all of equal dimensions. The cells are stacked horizontally and vertically forming rows and columns, as in a checkerboard.

So, first of all, the state of the grid. We know that the grid will have a list of children states (in our case the counter state). It turns out that you can fully define a grid with just the following information:
  - cell height
  - number of columns
  - grid width

As such, the state of the grid can be represented as :

```elm
type alias State childState =
  { children    : List childState
  , cellHeight  : Float
  , numCols     : Int
  , gridWidth   : Float
  }
```


For the actions, we know that each child will be independent and as such we will need to somehow identify the action with the component. We know that each child will be at a different index in the list, so we can use the index to identify this action

```elm
type Action childAction
  = ChildAction Int childAction
```


As for the update, we would need to take the function to update the child component as input in order to use it appropriately.

```elm
update : (childAction -> childState -> childState) -> Action childAction -> State childState -> State childState
update updateChild action state =
  case action of
    ChildAction n childAction ->
      let
          -- We only update if the index of the child state matches that of the action
          updateN index childState =
            if n == index
            then
              updateChild childAction childState
            else
              childState
      in
          { state | children <- List.indexedMap updateN state.children }
```



Similarly, for the view, we need to that the function to view the child component as input in order to view the children appropriately

```elm
view : (Address childAction -> childState -> Html) -> Address (Action childAction) -> State childState -> Html
view viewChild address state =
  let
      -- Get the dimensions of the grid
      gridDims : Vector
      gridDims =
        gridSize state

      -- Get the dimensions of an individual cell
      cellDims : Vector
      cellDims =
        cellSize state

      -- The CSS styles for the grid
      containerStyle =
        [ "position"  => "absolute"
        , "top"       => "0px"
        , "left"      => "0px"
        , "width"     => toString gridDims.x ++ "px"
        , "height"    => toString gridDims.y ++ "px"
        ]

      -- Function to view an individual cell at a given index
      -- viewN : Int -> childState -> Html
      viewN index childState =
        let
            -- The left or x-position of the cell
            left =
              cellDims.x * toFloat (index % state.numCols)

            -- The top or y-position of the cell
            top =
              cellDims.y * toFloat (index // state.numCols)

            -- The CSS styles for the cell
            -- Hint: Try adding a border here to see the cell
            childContainerStyle =  
              [ "position"  => "absolute"
              , "left"      => toString left ++ "px"
              , "top"       => toString top ++ "px"
              , "width"     => toString cellDims.x ++ "px"
              , "height"    => toString cellDims.y ++ "px"
              ]

            -- Make a forwarding address for the child at the given index
            childAddress =
              Signal.forwardTo address (ChildAction index)
        in
            -- We simply wrap the child in an container div
            Html.div
                [ Html.Attributes.style childContainerStyle ]
                [ viewChild childAddress childState ]
  in
      -- Wrap the whole thing in a div
      -- And view each child with the `viewN` function defined above
      Html.div
          [ Html.Attributes.style containerStyle ]
          ( List.indexedMap viewN state.children )
```

Where the helper functions `gridSize` and `cellSize` are defined as follows :

```elm
-- Get the size of a grid
gridSize : State childState -> Vector
gridSize state =
  let
      numChildren =
        List.length state.children

      numRows =
        numChildren // state.numCols

      gridHeight =
        state.cellheight * (toFloat numRows)
  in
      { x = state.gridWidth
      , y = gridHeight
      }

-- Get the size of each individual cell of a grid
cellSize : State childState -> Vector
cellSize state =
  { x = state.gridWidth / (toFloat state.numCols)
  , y = state.cellHeight
  }
```

---
Note on Addresses:

Since each individual component expects an address but we are only given a single address, we create a forwarding address from our given address that will forward all the actions of the individual address to the grid's address.

To do this, we use the `[Signal.forwardTo](http://package.elm-lang.org/packages/elm-lang/core/2.1.0/Signal#forwardTo)` function which has the following signature

```elm
Signal.forwardTo : Address a -> (b -> a) -> Address b
```
---

And that's it, we've defined our grid component. We have our state, actions, view, and update.

Let's try it out. All we need to do is to initialize our grid and we're done.


```elm
import StartApp
import Grid
import Counter
import List

initial : Grid.State Counter.State
initial =
  { children    = List.repeat 64 Counter.initial
  , cellHeight  = 50
  , numCols     = 8
  , gridWidth   = 400
  }

main =
  StartApp.start
    { model  = initial
    , update = Grid.update Counter.update
    , view   = Grid.view Counter.view
    }

```

## Modifying our Application

Now that we have both our grids and our counters working, we can attempt to modify them. Originally, we wanted the grid to look like a checkerboard. This means that we need to set the background color of the individual grid cells. Furthermore, if we leave the text of the individual cells black, the text will not appear on a black background. So, we will need to modify the text color of each counter.

For this we will need some context.

### Contexts

A context is an additional parameter we pass to the view which will contain information pertinent to the displaying of the components. In our case, we would like the counter to be aware of how much space does it have (in our case, the dimensions of the grid cells) and we need to know the background and text colors.


```elm
type alias Context =
  { viewport        : Vector
  , textColor       : Color
  , backgroundColor : Color  
  }
```

From here, we'll need to modify the view function of the Counter from having this type signature:

```elm
view : Address Action -> State -> Html
```

to this type signature:

```elm
view : Context -> Address Action -> State -> Html
```

Now that we have the new type signature, we can modify the implementation of the view function :

```elm
-- The counter will have three parts
-- The top third will be the increment button
-- The middle third will be the text
-- The bottom third will be the decrement button
view : Context -> Address Action -> State -> Html
view context address state =
  let
      -- The font size depends on the viewport
      -- Responsive design for the win
      fontSize =
        (min context.viewport.x context.viewport.y) / 3

      -- The width of each section
      width =
        context.viewport.x

      -- The height of the viewport
      height =
        context.viewport.y

      -- The height of each section
      sectionHeight =
        height / 3

      -- The CSS for the container
      containerStyle =
          [ "position"  => "absolute"
          , "top"       => "0px"
          , "left"      => "0px"
          , "width"     => toString width ++ "px"
          , "height"    => toString height ++ "px"
          , "background-color" => toRgbaString context.backgroundColor
          ]

      -- The CSS for the increment button
      incrementButtonStyle =
          [ "position"    => "absolute"
          , "top"         => "0px"
          , "left"        => "0px"
          , "width"       => toString width ++ "px"
          , "height"      => toString sectionHeight ++ "px"
          , "color"       => toRgbaString context.textColor
          , "cursor"      => "pointer"
          , "font-size"   => toString fontSize ++ "px"
          , "text-align"  => "center"
          , "-webkit-user-select" => "none"
          ]

      -- The CSS for the decrement button
      decrementButtonStyle =
          [ "position"    => "absolute"
          , "top"         => toString (2 * sectionHeight) ++ "px"
          , "left"        => "0px"
          , "width"       => toString width ++ "px"
          , "height"      => toString sectionHeight ++ "px"
          , "color"       => toRgbaString context.textColor
          , "cursor"      => "pointer"
          , "font-size"   => toString fontSize ++ "px"
          , "text-align"  => "center"
          , "-webkit-user-select" => "none"
          ]

      -- The CSS for the text
      textStyle =
          [ "position"    => "absolute"
          , "top"         => toString sectionHeight ++ "px"
          , "left"        => "0px"
          , "width"       => toString width ++ "px"
          , "height"      => toString sectionHeight ++ "px"
          , "color"       => toRgbaString context.textColor
          , "font-size"   => toString fontSize ++ "px"
          , "text-align"  => "center"
          ]
  in
      Html.div
          [ Html.Attributes.style containerStyle ]
          [ Html.div  -- We're changing buttons to divs for aesthetics reasons
                [ Html.Events.onClick address Increment
                , Html.Attributes.style incrementButtonStyle
                ]
                [ Html.text "+" ]
          , Html.div
                [ Html.Events.onClick address Decrement
                , Html.Attributes.style decrementButtonStyle
                ]
                [ Html.text "-" ]
          , Html.span
                [ Html.Attributes.style textStyle ]
                [ Html.text (toString state) ]
          ]
```

As we can see, the big part of the code is really dedicated to the CSS. The actual meat of the the view function is largely unchanged. Note that I've changed buttons to divs for aesthetic reasons. Consider never doing this in real life as buttons come pre-packaged with amazing built-in accessibility.

Now that we've done this, we'll need to modify the view function of the grid. First of all, this won't even compile due to the newly introduced context. As such, the grid's view function will need to generate contexts on the fly. That said, the grid should not explicitly generate that exact context. The goal of a good grid is to remain as general as it possibly can. Therefore, the grid would produce its own context which we would then convert to the counter's context.

From a viewing perspective, the grid only needs to tell a cell which row and column it is located as well as the size of the cell's viewport.

```elm
type alias Context =
  { viewport  : Vector
  , row       : Int
  , column    : Int
  }
```

Which we can generate from the grid state as follows :

```elm
generateContext : Int -> State -> Context
generateContext index state =
  let
      column =
        index % state.numCols

      row =
        index // state.numCols

      viewport =
        cellSize state

  in
      { viewport  = viewport
      , row       = row
      , column    = column
      }
```

Now, we'll need the function to convert between both contexts.

```elm
-- Convert a grid context to a counter context
toCounterContext : Grid.Context -> Counter.Context
toCounterContext gridContext =
  let
      isBlack =
        if gridContext.row % 2 == 0
        then
          if gridContext.column % 2 == 0
          then
            True
          else
            False
        else
          if gridContext.column % 2 == 0
          then
            False
          else
            True

      (textColor, backgroundColor) =
        if isBlack
        then
          (Color.white, Color.black)
        else
          (Color.black, Color.white)


  in
      { viewport        = gridContext.viewport
      , textColor       = textColor
      , backgroundColor = backgroundColor
      }
```

And now, we can finally change the code of the view function of the grid component to deal with contexts.

Concretely, we will need to change the type signature from :

```elm
view : (Address childAction -> childState -> Html) -> Address (Action childAction) -> State childState -> Html
```

to the following type signature :

```elm
view : (Context -> Address childAction -> childState -> Html) -> Address (Action childAction) -> State childState -> Html
```


We can implement the view function as follows:

```elm
view : (Context -> Address childAction -> childState -> Html) -> Address (Action childAction) -> State childState -> Html
view viewChild address state =
  let
      -- Get the dimensions of the grid
      gridDims : Vector
      gridDims =
        gridSize state

      -- Get the dimensions of an individual cell
      cellDims : Vector
      cellDims =
        cellSize state

      -- The CSS styles for the grid
      containerStyle =
        [ "position"  => "absolute"
        , "top"       => "0px"
        , "left"      => "0px"
        , "width"     => toString gridDims.x ++ "px"
        , "height"    => toString gridDims.y ++ "px"
        ]

      -- Function to view an individual cell at a given index
      -- viewN : Int -> childState -> Html
      viewN index childState =
        let
            -- The left or x-position of the cell
            left =
              cellDims.x * toFloat (index % state.numCols)

            -- The top or y-position of the cell
            top =
              cellDims.y * toFloat (index // state.numCols)

            -- The CSS styles for the cell
            -- Hint: Try adding a border here to see the cell
            childContainerStyle =
              [ "position"  => "absolute"
              , "left"      => toString left ++ "px"
              , "top"       => toString top ++ "px"
              , "width"     => toString cellDims.x ++ "px"
              , "height"    => toString cellDims.y ++ "px"
              ]

            -- Make a forwarding address for the child at the given index
            childAddress =
              Signal.forwardTo address (ChildAction index)

            -- We generate our context here
            context =
              generateContext index state

        in
            -- We simply wrap the child in an container div
            Html.div
                [ Html.Attributes.style childContainerStyle ]
                [ viewChild context childAddress childState ]
                -- And we simply pass the child context as a parameter
  in
      -- Wrap the whole thing in a div
      -- And view each child with the `viewN` function defined above
      Html.div
          [ Html.Attributes.style containerStyle ]
          ( List.indexedMap viewN state.children )
```


And now, if we want to view our changes, we just need the modify `Main` as follows :

```elm
import StartApp
import Grid
import Counter
import List
import Color

initial : Grid.State Counter.State
initial =
  { children    = List.repeat 64 Counter.initial
  , cellHeight  = 50
  , numCols     = 8
  , gridWidth   = 400
  }

-- As implemented above
toCounterContext : Grid.Context -> Counter.Context
toCounterContext gridContext = ...

main =
  StartApp.start
    { model  = initial
    , update = Grid.update Counter.update
    , view   = Grid.view (toCounterContext >> Counter.view)
    }
-- Note that converting contexts is just a matter of function composition
```

And, ta-da! We have a checkerboard grid where each component is independent.

## Conclusions and Further Explorations

Hopefully, this tutorial can give you a taste of how to work with components in Elm and how easy it is to modify code without making a mess. Elm can make it incredibly easy to write simple, extensible, and maintainable code and this tutorial attempts to mimic that exercise in maintainability and extensibility.

Now that you know how to make a grid and plug in a component, why not try making your own components and placing them in the grid and see how things go? What if you want the ability to resize the grid? What if you want to place the grid in another grid? What modifications will be needed there?
