module Main exposing (..)

import Types exposing (..)
import Models exposing (..)
import Msgs exposing (..)
import Api exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import String
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task

type alias Flags =
  { uid : String
  , name : String
  , info : String
  }

main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

init : Flags -> ( Trip, Cmd Msg )
init flags =
    ( Trip flags.uid flags.name flags.info
    , fetchTrip 
    )

-- UPDATE


update : Msg -> Trip -> ( Trip, Cmd Msg )
update msg trip =
    case msg of
        Name name ->
            ({trip | name = name}, Cmd.none)

        Info info ->
            ({ trip | info = info}, Cmd.none)

        Reset ->
            (trip, fetchTrip)

        Save ->
            (trip, updateTrip trip)

        FetchTrip (Ok newTrip) ->
            let _ = Debug.log "FetchTrip ok" trip
            in 
            (Trip newTrip.uid newTrip.name newTrip.info, Cmd.none)

        FetchTrip (Err err) ->
            let _ = Debug.log "FetchTrip err" err
            in 
            (trip, Cmd.none)

        UpdateTrip (Ok newTrip) ->
            let _ = Debug.log "UpdateTrip ok" newTrip
            in 
            (trip, Cmd.none)

        UpdateTrip (Err err) ->
            let _ = Debug.log "UpdateTrip err" err
            in 
            (trip, Cmd.none)

-- VIEW

view : Trip -> Html Msg
view trip =
    div []
        [ input [ placeholder "Enter Name...", value (trip.name), onInput Name, nameStyle ] []
        , br [] []
        , input [ placeholder "Info", value (trip.info), onInput Info, infoStyle ] []
        , button [ onClick Reset ] [ text "Reset" ]
        , button [ onClick Save ] [ text "Save" ]
        ]

-- Style

nameStyle =
    style
        [ ( "width", "100%" )
        , ( "height", "40px" )
        , ( "padding", "10px 0" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ] 

infoStyle =
    style
        [ ( "width", "100%" )
        , ( "height", "30px" )
        , ( "padding", "10px 0" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ] 

-- SUBSCRIPTIONS

subscriptions : Trip -> Sub Msg
subscriptions trip =
    Sub.none



