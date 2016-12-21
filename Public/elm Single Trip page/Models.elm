module Models exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode

-- MODEL

type alias Trip =
    { uid : String
    , name : String
    , info : String
    }

-- JSON

tripDecoder : Decode.Decoder Trip
tripDecoder = 
    let _ = Debug.log "tripDecoder fields" (Decode.field "body" Decode.string)
    in 
    Decode.map3 Trip
        (Decode.field "uid" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "info" Decode.string)       
 
tripEncoder : Trip -> Encode.Value
tripEncoder trip =
    Encode.object
        [ ("uid", Encode.string trip.uid)
        , ("name", Encode.string trip.name)
        , ("info", Encode.string trip.info)
        ]