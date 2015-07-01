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
        (gridContext.row % 2 == 0) == (gridContext.column % 2 == 0)

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
