module Grid where

import Helper exposing (..)
import Signal exposing (Address)
import Color  exposing (Color)
import Html   exposing (Html)
import Html.Attributes
import List

-- The state of the grid
type alias State childState =
  { children    : List childState
  , cellHeight  : Float
  , numCols     : Int
  , gridWidth   : Float
  }

-- Get the size of a grid
gridSize : State childState -> Vector
gridSize state =
  let
      numChildren =
        List.length state.children

      numRows =
        numChildren // state.numCols

      gridHeight =
        state.cellHeight * (toFloat numRows)
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

-- A grid merely relays actions to the appropriate child
type Action childAction
  = ChildAction Int childAction

-- The update function
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


-- The context for each cell
type alias Context =
  { viewport  : Vector
  , row       : Int
  , column    : Int
  }


-- Generate the context a cell at a given index
--generateContext : Int -> State -> Context
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

-- The view function
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
