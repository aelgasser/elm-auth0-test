module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http


type alias Model =
    { quote : String
    }


type Msg
    = GetQuote
    | FetchRandomQuoteCompleted (Result Http.Error String)


api : String
api =
    "http://localhost:3001/"


randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"


fetchRandomQuote : Http.Request String
fetchRandomQuote =
    Http.getString randomQuoteUrl


fetchRandomQuoteCmd : Cmd Msg
fetchRandomQuoteCmd =
    Http.send FetchRandomQuoteCompleted fetchRandomQuote


fetchRandomQuoteCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
fetchRandomQuoteCompleted model result =
    case result of
        Ok newQuote ->
            ( { model | quote = newQuote }, Cmd.none )

        Err _ ->
            ( model, Cmd.none )


init : ( Model, Cmd Msg )
init =
    ( Model "", fetchRandomQuoteCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetQuote ->
            ( model, fetchRandomQuoteCmd )

        FetchRandomQuoteCompleted result ->
            fetchRandomQuoteCompleted model result


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
        , p [ class "text-center" ]
            [ button [ class "btn btn-success", onClick GetQuote ] [ text "Grab a quote!" ]
            ]
        , blockquote []
            [ p [] [ text model.quote ]
            ]
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
