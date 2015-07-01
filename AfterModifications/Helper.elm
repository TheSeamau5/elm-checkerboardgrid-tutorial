module Helper where

import Color exposing (Color)

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
