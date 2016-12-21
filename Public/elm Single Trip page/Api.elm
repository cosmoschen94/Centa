module Api exposing (..)

import Types exposing (..)
import Models exposing (..) 
import Msgs exposing (..)
import Http
import Array exposing (Array)
import Json.Decode as Decode
import Json.Encode as Encode

-- Trip

fetchTrip : Cmd Msg
fetchTrip =
    let
        _ = Debug.log "fetchTrip"
        request =
            Http.get apiTrip tripDecoder
    in
        Http.send FetchTrip request

updateTrip : Trip -> Cmd Msg
updateTrip trip =
    let
        _ = Debug.log "updateTrip" 
        request = 
            Http.post apiTrip (Http.jsonBody (tripEncoder trip)) tripDecoder 
    in
        Http.send UpdateTrip request

-- HTTP Infra

apiTrip = "/api/trip"
