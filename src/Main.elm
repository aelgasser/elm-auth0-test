module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)


type alias Model =
    { username : String
    , password : String
    , token : String
    , quote : String
    , errorMsg : String
    }


type Msg
    = GetQuote
    | FetchRandomQuoteCompleted (Result Http.Error String)
    | SetUsername String
    | SetPassword String
    | ClickRegisterUser
    | GetTokenCompleted (Result Http.Error String)


api : String
api =
    "http://localhost:3001/"


registerUrl : String
registerUrl =
    api ++ "users"


userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ( "username", Encode.string model.username )
        , ( "password", Encode.string model.password )
        ]


authUser : Model -> String -> Http.Request String
authUser model apiUrl =
    let
        body =
            model |> userEncoder |> Http.jsonBody
    in
        Http.post apiUrl body tokenDecoder


authUserCmd : Model -> String -> Cmd Msg
authUserCmd model apiUrl =
    Http.send GetTokenCompleted (authUser model apiUrl)


getTokenCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
getTokenCompleted model result =
    case result of
        Ok newToken ->
            ( { model | token = newToken, password = "", errorMsg = "" } |> Debug.log "got new token", Cmd.none )

        Err error ->
            ( { model | errorMsg = (toString error) }, Cmd.none )


tokenDecoder : Decoder String
tokenDecoder =
    Decode.field "access_token" Decode.string


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
    ( Model "" "" "" "" "", fetchRandomQuoteCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetQuote ->
            ( model, fetchRandomQuoteCmd )

        FetchRandomQuoteCompleted result ->
            fetchRandomQuoteCompleted model result

        SetUsername login ->
            ( { model | username = login }, Cmd.none )

        SetPassword pwd ->
            ( { model | password = pwd }, Cmd.none )

        ClickRegisterUser ->
            ( model, authUserCmd model registerUrl )

        GetTokenCompleted result ->
            getTokenCompleted model result


view : Model -> Html Msg
view model =
    let
        loggedIn : Bool
        loggedIn =
            if String.length model.token > 0 then
                True
            else
                False

        authBoxView =
            let
                showError : String
                showError =
                    if String.isEmpty model.errorMsg then
                        "hidden"
                    else
                        ""

                greeting : String
                greeting =
                    "Hello, " ++ model.username ++ "!"
            in
                if loggedIn then
                    div [ id "greeting" ]
                        [ h3 [ class "text-center" ] [ text greeting ]
                        , p [ class "text-center" ] [ text "You have super-secret access to protected quotes." ]
                        ]
                else
                    div [ id "form" ]
                        [ h2 [ class "text-center" ] [ text "Log In or Register" ]
                        , p [ class "help-block" ] [ text "If you already have an account, please Log In. Otherwise, enter your desired username and password and Register. " ]
                        , div [ class showError ]
                            [ div [ class "alert alert-danger" ] [ text model.errorMsg ]
                            ]
                        , div [ class "form-group row" ]
                            [ div [ class "col-md-offset-2 col-md-8" ]
                                [ label [ for "username" ] [ text "Username:" ]
                                , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.username, onInput SetUsername ] []
                                ]
                            ]
                        , div [ class "form-group row" ]
                            [ div [ class "col-md-offset-2 col-md-8" ]
                                [ label [ for "password" ] [ text "Password:" ]
                                , input [ id "password", type_ "text", class "form-control", Html.Attributes.value model.password, onInput SetPassword ] []
                                ]
                            ]
                        , div [ class "text-center" ]
                            [ button [ class "btn btn-link", onClick ClickRegisterUser ] [ text "Register" ] ]
                        ]
    in
        div [ class "container" ]
            [ h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
            , p [ class "text-center" ]
                [ button [ class "btn btn-success", onClick GetQuote ] [ text "Grab a quote!" ]
                ]
            , blockquote []
                [ p [] [ text model.quote ]
                ]
            , div [ class "jumbotron text-left" ]
                [ authBoxView ]
            ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
