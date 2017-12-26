port module Ports exposing (..)

import Model exposing (..)


{-
   Ports
-}


port setStorage : Model -> Cmd msg


port removeStorage : Model -> Cmd msg
