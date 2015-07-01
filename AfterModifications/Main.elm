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


main =
  StartApp.start
    { model  = initial
    , update = Grid.update Counter.update
    , view   = Grid.view (toCounterContext >> Counter.view)
    }


---- Convert contexts

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
