module Main exposing (..)

import Model exposing (..)
import Ports exposing (..)
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)


type Msg
    = GetQuote
    | FetchRandomQuoteCompleted (Result Http.Error String)
    | SetUsername String
    | SetPassword String
    | ClickRegisterUser
    | GetTokenCompleted (Result Http.Error String)
    | ClickLogin
    | LogOut
    | GetProtectedQuote
    | FetchProtectedQuoteCompleted (Result Http.Error String)



{-
   API Urls
-}


api : String
api =
    "http://localhost:3001/"


protectedQuoteUrl : String
protectedQuoteUrl =
    api ++ "api/protected/random-quote"


loginUrl : String
loginUrl =
    api ++ "sessions/create"


registerUrl : String
registerUrl =
    api ++ "users"


randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"



{-
   Encoders
-}


userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ( "username", Encode.string model.username )
        , ( "password", Encode.string model.password )
        ]



{-
   Decoders
-}


tokenDecoder : Decoder String
tokenDecoder =
    Decode.field "access_token" Decode.string



{-
   Effects
-}


authUser : Model -> String -> Http.Request String
authUser model apiUrl =
    let
        body =
            model |> userEncoder |> Http.jsonBody
    in
        Http.post apiUrl body tokenDecoder


fetchRandomQuote : Http.Request String
fetchRandomQuote =
    Http.getString randomQuoteUrl


fetchProtectedQuote : Model -> Http.Request String
fetchProtectedQuote model =
    { method = "GET"
    , headers = [ Http.header "Authorization" ("Bearer " ++ model.token) ]
    , url = protectedQuoteUrl
    , body = Http.emptyBody
    , expect = Http.expectString
    , timeout = Nothing
    , withCredentials = False
    }
        |> Http.request



{-
   Commands
-}


authUserCmd : Model -> String -> Cmd Msg
authUserCmd model apiUrl =
    Http.send GetTokenCompleted (authUser model apiUrl)


fetchRandomQuoteCmd : Cmd Msg
fetchRandomQuoteCmd =
    Http.send FetchRandomQuoteCompleted fetchRandomQuote


fetchProtectedQuoteCmd : Model -> Cmd Msg
fetchProtectedQuoteCmd model =
    Http.send FetchProtectedQuoteCompleted (fetchProtectedQuote model)



{-
   Effect Callbacks
-}


getTokenCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
getTokenCompleted model result =
    case result of
        Ok newToken ->
            setStorageHelper { model | token = newToken, password = "", errorMsg = "" } |> Debug.log "got new token"

        Err error ->
            ( { model | errorMsg = (toString error) }, Cmd.none )


fetchRandomQuoteCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
fetchRandomQuoteCompleted model result =
    case result of
        Ok newQuote ->
            setStorageHelper { model | quote = newQuote }

        Err _ ->
            ( model, Cmd.none )


fetchProtectedQuoteCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
fetchProtectedQuoteCompleted model result =
    case result of
        Ok newQuote ->
            setStorageHelper { model | protectedQuote = newQuote }

        Err _ ->
            ( model, Cmd.none )


setStorageHelper : Model -> ( Model, Cmd Msg )
setStorageHelper model =
    ( model, setStorage model )



{-
   Elm Program handlers
-}


init : Maybe Model -> ( Model, Cmd Msg )
init model =
    case model of
        Just model ->
            ( model, fetchRandomQuoteCmd )

        Nothing ->
            ( Model "" "" "" "" "" "", fetchRandomQuoteCmd )


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

        ClickLogin ->
            ( model, authUserCmd model loginUrl )

        LogOut ->
            ( { model | token = "", username = "" }, removeStorage model )

        GetProtectedQuote ->
            ( model, fetchProtectedQuoteCmd model )

        FetchProtectedQuoteCompleted result ->
            fetchProtectedQuoteCompleted model result


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
                        , p [ class "text-center" ]
                            [ button [ class "btn btn-danger", onClick LogOut ] [ text "Log Out" ]
                            ]
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
                            [ button [ class "btn btn-link", onClick ClickRegisterUser ] [ text "Register" ]
                            , button [ class "btn btn-primary", onClick ClickLogin ] [ text "Log In" ]
                            ]
                        ]

        protectedQuoteView =
            let
                hideIfNoProtectedQuote : String
                hideIfNoProtectedQuote =
                    if String.isEmpty model.protectedQuote then
                        "hidden"
                    else
                        ""
            in
                if loggedIn then
                    div []
                        [ p [ class "text-center" ]
                            [ button [ class "btn btn-info", onClick GetProtectedQuote ] [ text "Grab a protected quote!" ] ]
                        , blockquote [ class hideIfNoProtectedQuote ]
                            [ p [] [ text model.protectedQuote ] ]
                        ]
                else
                    p [ class "text-center" ] [ text "Please log in or register to see protected quotes." ]
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
            , div []
                [ h2 [ class "text-center" ] [ text "Protected Chuck Norris Quotes" ]
                , protectedQuoteView
                ]
            ]


main : Program (Maybe Model) Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
