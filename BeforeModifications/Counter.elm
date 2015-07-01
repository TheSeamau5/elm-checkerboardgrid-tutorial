module Counter where

import Signal exposing (Address)
import Html   exposing (Html)
import Html.Events

-- The Counter State
type alias State = Int

-- Counters start at 0
initial : State
initial = 0

-- A counter can be either incremented or decremented
type Action
  = Increment
  | Decrement

-- The update function
update : Action -> State -> State
update action state =
  case action of
    Increment ->
      state + 1

    Decrement ->
      state - 1

-- The view function
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
