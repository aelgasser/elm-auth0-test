module Model exposing (..)


type alias Model =
    { username : String
    , password : String
    , token : String
    , quote : String
    , errorMsg : String
    , protectedQuote : String
    }
