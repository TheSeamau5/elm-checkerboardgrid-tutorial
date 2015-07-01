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
