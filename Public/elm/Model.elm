module Model exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode

-- Types

type alias Id = String

-- Models

type alias Model =
    -- Global
    { requesting : Bool
    , errMsg : String

    -- AuthUser
    , userUid : Id
    , name : String
    , email : String
    , password : String
    , token : String

    -- Trip
    , uid : Id
    , title : String
    , date : String
    , address : String -- yyyy-mm-dd: 2016-12-24
    , info : String
    , owningUsers : List User
    , joinedUsers : List User

    -- Trip Meta
    --, datePicker : DatePicker.DatePicker
    , hasEdited : Bool

    -- Trip List
    , trips : List Trip
    }

type alias User =
    { uid : Id
    , name : String
    }

type alias AuthUser =
    { uid : Id
    , name : String
    , email : String
    , password : String
    , token : String
    }

type alias Trip =
    { uid : Id
    , title : String
    , date : String
    , address : String
    , info : String
    , owningUsers : List User
    , joinedUsers : List User
    }

-- Init

type alias Flags =
    -- CurUser
    { userUid : String
    , name : String
    , token : String
    -- Trip
    , uid : Id
    , title : String
    , date : String
    , address : String
    , info : String
    , owningUsers : List User
    , joinedUsers : List User
    -- Trip Meta
    , hasEdited : Bool
    -- Trip List
    , trips : List Trip
    }

-- Model Constructors

emptyModel : Model
emptyModel =
    Model {- Global -} True "" {- CurUser -} "" "" "" "" "" 
        {- Trip -} "" "" "" "" "" [] [] {- Trip Meta -} {- datePicker -} False
        {- Trips -} []

makeAuthUser : Model -> AuthUser
makeAuthUser model =
    AuthUser model.userUid model.name model.email model.password model.token 

emptyTrip : Trip
emptyTrip =
    Trip "" "" "" "" "" [] []

makeTrip : Model -> Trip
makeTrip model =
    Trip model.uid model.title model.date model.address model.info model.owningUsers model.joinedUsers

-- JSON

{- 
To combine decoders:
Say sending both things as JSON: 

`{"cred": {"email" … }, "user" :{"uid" …} }` 

and then decode it with: 

`Decode.map2 (\c u -> {cred =c, user = u}) 
    (Decode.field "cred" credDecoder) 
    (Decode.field "user" userDecoder)`

type alias CredAndUser = {cred: Cred, user: User}
credAndUserDecoder : Decode.Decoder CredAndUser
-}

userDecoder : Decode.Decoder User
userDecoder =
    let _ = Debug.log "userDecoder body: " (Decode.field "body" Decode.string)
    in
        Decode.map2 User
            (Decode.field "uid" Decode.string)
            (Decode.field "name" Decode.string)

userEncoder : User -> Encode.Value
userEncoder user =
    Encode.object
        [ ( "uid", Encode.string user.uid )
        , ( "name", Encode.string user.name )
        ]

authUserDecoder : Decode.Decoder AuthUser
authUserDecoder =
    let _ = Debug.log "authUserDecoder body: " (Decode.field "body" Decode.string)
    in
        Decode.map5 AuthUser
            (Decode.field "uid" Decode.string)
            (Decode.field "name" Decode.string)
            (Decode.field "email" Decode.string)
            (Decode.field "password" Decode.string)
            (Decode.field "token" Decode.string)

authUserEncoder : AuthUser -> Encode.Value
authUserEncoder authUser =
    Encode.object
        [ ( "uid", Encode.string authUser.uid )
        , ( "name", Encode.string authUser.name )
        , ( "email", Encode.string authUser.email )
        , ( "password", Encode.string authUser.password )
        , ( "token", Encode.string authUser.token )
        ]

tripDecoder : Decode.Decoder Trip
tripDecoder =
    let _ = Debug.log "tripDecoder body: " (Decode.field "body" Decode.string)
    in
        Decode.map7 Trip
            (Decode.field "uid" Decode.string)
            (Decode.field "title" Decode.string)
            (Decode.field "date" Decode.string)
            (Decode.field "address" Decode.string)
            (Decode.field "info" Decode.string)
            (Decode.field "owningUsers" (Decode.list userDecoder))
            (Decode.field "joinedUsers" (Decode.list userDecoder))

tripEncoder : Trip -> Encode.Value
tripEncoder trip =
    Encode.object
        [ ( "uid", Encode.string trip.uid )
        , ( "title", Encode.string trip.title )
        , ( "date", Encode.string trip.date )
        , ( "address", Encode.string trip.address )
        , ( "info", Encode.string trip.info )
        , ( "owningUsers", Encode.list <| List.map userEncoder <| trip.owningUsers )
        , ( "joinedUsers", Encode.list <| List.map userEncoder <| trip.joinedUsers )
        ]

tripsDecoder : Decode.Decoder (List Trip)
tripsDecoder =
    let _ = Debug.log "tripsDecoder body: " (Decode.field "body" Decode.string)
    in
        Decode.list tripDecoder

tripUserIdEncoder : Id -> String -> Encode.Value
tripUserIdEncoder tripId userId =
    Encode.object
        [ ( "tripId", Encode.string tripId )
        , ( "userId", Encode.string userId )
        ]


        