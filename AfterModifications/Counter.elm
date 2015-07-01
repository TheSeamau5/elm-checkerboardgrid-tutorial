module Counter where

import Helper exposing (..)
import Signal exposing (Address)
import Color  exposing (Color)
import Html   exposing (Html)
import Html.Attributes
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

-- The context for the counter
type alias Context =
  { viewport        : Vector
  , textColor       : Color
  , backgroundColor : Color
  }

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
