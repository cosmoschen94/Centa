module Msgs exposing (..)

import Types exposing (..)
import Models exposing (..)
import Http

type Msg
    = Name String
    | Info String
    | Reset
    | Save
    | FetchTrip (Result Http.Error Trip)
    | UpdateTrip (Result Http.Error Trip)