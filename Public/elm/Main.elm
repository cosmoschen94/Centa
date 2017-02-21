port module Main exposing (..)

import Model exposing (..)
import Flow exposing (..)
import View exposing (..)

import Html exposing (..)

-- Init

main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = subscriptions
        }

port setStorage : Model -> Cmd msg

{- 
We want to `setStorage` on every update. 
This function adds the setStorage command for every step of the update function.
-}
updateWithStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithStorage msg model =
    let ( newModel, cmds ) = update msg model
    in ( newModel, Cmd.batch [ setStorage newModel, cmds ] )

init : Maybe Model -> ( Model, Cmd Msg )
init savedModel =
    ( Maybe.withDefault emptyModel savedModel, getTrips )
    -- ( Maybe.withDefault emptyModel savedModel, Cmd.batch [ getTrips, Cmd.map ToDatePicker datePickerFx ] )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
