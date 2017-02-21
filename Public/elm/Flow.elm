module Flow exposing (..)

import Model exposing (..)
import Func exposing (..)

import Http
import Task
import Jwt exposing (..)
import Date exposing (Date, Month(..), Day(..), day, dayOfWeek, month, year)
import Date.Extra as Date
import DatePicker exposing (defaultSettings)

-- API

{-
post : String -> Body -> Request ()
post url body =
    request
        { method = "PUT"
        , headers = []
        , url = url
        , body = body
        , expect = expectStringResponse (\_ -> Ok ())
        , timeout = Nothing
        , withAuthUsers = False
        }
-}

register : AuthUser -> Cmd Msg
register authUser =
    let _ = log "register email:" authUser.email
    in
        Http.post ("/register") (Http.jsonBody (authUserEncoder authUser)) authUserDecoder
            |> Http.send PostRegister

login : AuthUser -> Cmd Msg
login authUser =
    let _ = log "login email:" authUser.email
    in
        (authUserEncoder authUser)
        |> Jwt.authenticate ("/login") authUserDecoder
        |> Http.send PostLogin

{--
fetchProtectedQuote : Model -> Task Http.Error String
fetchProtectedQuote model =
    { verb = "GET"
    , headers = [ ("Authorization", "Bearer " ++ model.token) ]
    , url = protectedQuoteUrl
    , body = Http.empty
    }
        |> Http.send Http.defaultSettings
        |> Http.Decorators.interpretStatus -- decorates Http.send result so error type is Http.Error instead of RawError
        |> Task.map responseText
        --}

getTrips : Cmd Msg
getTrips =
    let _ = log "getTrips"
        request = Http.get "/trips" tripsDecoder
    in
        Http.send GetTrips request

getTrip : Id -> Cmd Msg
getTrip uid =
    let _ = log "getTrip uid:" uid
        request = Http.get ("/trip/" ++ uid) tripDecoder
    in
        Http.send GetTrip request

postTrip : Trip -> Cmd Msg
postTrip trip =
    let _ = log "postTrip uid:" trip.uid
        request = Http.post "/trip" (Http.jsonBody (tripEncoder trip)) tripDecoder
    in
        Http.send PostTrip request

postTripJoin : Id -> Id -> Cmd Msg
postTripJoin tripId userId =
    let _ = log "postTripJoin uid:" (tripId ++ " userId:" ++ userId)
        request = Http.post "/trip/join" (Http.jsonBody (tripUserIdEncoder tripId userId)) tripDecoder
    in
        Http.send PostTrip request

postTripLeave : Id -> Id -> Cmd Msg
postTripLeave tripId userId =
    let _ = log "postTripLeave uid:" (tripId ++ " userId:" ++ userId)
        request = Http.post "/trip/leave" (Http.jsonBody (tripUserIdEncoder tripId userId)) tripDecoder
    in
        Http.send PostTrip request

-- UPDATE

type Msg
    = NoOp
    -- User Input
    | Name String
    | Email String
    | Password String
    | Register
    | Login
    | Logout
    -- Trip Entry
    | Add
    | Delete Id
    -- Trip Edit
    | Edit Id
    | Title String
    | Address String
    | Info String
    -- Trip Status
    | JoinTrip
    | LeaveTrip
    -- Trip Status
    | Reset
    | Save
    -- Auth Response
    | PostRegister (Result Http.Error AuthUser)
    | PostLogin (Result Http.Error AuthUser)
    -- Trip Response
    | GetTrips (Result Http.Error (List Trip))
    | AddTripIfNeeded
    | GetTrip (Result Http.Error Trip)
    | PostTrip (Result Http.Error Trip)
    -- Date Helper
    -- | UpdateDatePicker
    -- | ToDatePicker DatePicker.Msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        --- AUTH ---

        -- Auth Action
        Name name ->
            { model | name = name } ! []

        Email email ->
            let _ = log "Cred email" (model.email ++ " pw: " ++ model.password)
            in
                { model | email = email } ! []

        Password password ->
            { model | password = password } ! []

        Register ->
            ( { model | requesting = True }, register (makeAuthUser model) )

        Login ->
            ( { model | requesting = True }, login (makeAuthUser model) )

        Logout ->
            { model | token = "" } ! []

        -- Auth API
        PostRegister (Ok user) ->
            let _ = log "PostRegister ok" (" email:" ++ user.email ++ " token:" ++ user.token)
            in
                { model
                | requesting = False
                , userUid = user.uid
                , name = user.name
                , email = user.email
                , password = user.password
                , token = user.token
                }
                    ! []

        PostRegister (Err err) ->
            let _ = log "PostRegister err" err
            in
                { model | requesting = False, token = "" } ! []

        PostLogin (Ok user) ->
            let _ = log "PostLogin ok" (" email:" ++ user.email ++ " token:" ++ user.token)
            in
                { model
                | requesting = False
                , userUid = user.uid
                , name = user.name
                , email = user.email
                , password = user.password
                , token = user.token
                }
                    ! []

        PostLogin (Err err) ->
            let _ = log "PostLogin err" err
            in
                { model | requesting = False, token = "" } ! []

        --- TRIP ---

        Add ->
            { model
            | uid = ""
            , title = ""
            , date = ""
            , address = ""
            , info = ""
            , hasEdited = False
            , trips = [ emptyTrip ] ++ model.trips
            }
                ![]
                --! [ Random.generate NewUid (Random.String.string 6 Random.Char.english) ]
                -- NewUid newUid ->

        Delete uid ->
            { model | trips = List.filter (\t -> t.uid /= uid) model.trips }
            ! []

        Edit uid ->
            let
                _ = log "Edit uid:" uid
                trip = Maybe.withDefault
                    { uid = ""
                    , title = ""
                    , date = ""
                    , address = ""
                    , info = ""
                    , owningUsers = []
                    , joinedUsers = []
                    }
                        (List.head (List.filter (\trip -> trip.uid == uid) model.trips))
            in
                { model
                | uid = uid
                , title = trip.title
                , date = trip.date
                , address = trip.address
                , info = trip.info
                , owningUsers = trip.owningUsers
                , joinedUsers = trip.joinedUsers
                , hasEdited = False
                }
                    ! []
                    --|> update UpdateDatePicker

        Title title ->
            { model | title = title, hasEdited = True } ! []

        Address address ->
            { model | address = address, hasEdited = True } ! []

        Info info ->
            { model | info = info, hasEdited = True } ! []

        -- Trip Status
        JoinTrip ->
            ( { model | requesting = True }, postTripJoin model.uid model.userUid )

        LeaveTrip ->
            ( { model | requesting = True }, postTripLeave model.uid model.userUid )

        --({ model | requesting = True}, postTripLeave model.uid model.email )
        Reset ->
            case String.isEmpty model.uid of
                True ->
                    { model
                    | title = ""
                    , date = ""
                    , address = ""
                    , info = ""
                    , hasEdited = False
                    }
                        ![]
                False ->
                    ( { model | requesting = True }, getTrip model.uid )

        Save ->
            ( { model | requesting = True }, postTrip (makeTrip model) )

        
        -- Trip API ---
        GetTrips (Ok trips) ->
            let _ = log "GetTrips ok count:" ((toString (List.length trips)) ++ " trips: " ++ (toString trips))
                -- If server deleted a trip but client still has it stored in model, need to purge uid
                containsCurTrip = 
                    case List.head (List.filter (\t -> t.uid == model.uid) trips) of
                        Nothing -> False
                        Just val -> True
            in
                { model
                | requesting = False
                , uid = if containsCurTrip then model.uid else ""
                , trips = trips
                }
                    |> update AddTripIfNeeded

        GetTrips (Err err) ->
            let _ = log "GetTrips err" err
            in
                { model | requesting = False } ! []

        AddTripIfNeeded ->
            { model
                | trips =
                    case List.head (List.filter (\t -> t.uid == model.uid) model.trips) of
                        Nothing ->
                            let _ = log "AddTripIfNeeded adding" model.uid
                            in [ makeTrip model ] ++ model.trips

                        Just val ->
                            model.trips
            }
                ! []

        GetTrip (Ok trip) ->
            let _ = log "GetTrip ok" trip
            in
                { model
                | requesting = False
                , uid = trip.uid
                , title = trip.title
                , date = trip.date
                , address = trip.address
                , info = trip.info
                , owningUsers = trip.owningUsers
                , joinedUsers = trip.joinedUsers
                , hasEdited = False
                }
                    ! []
                    --|> update UpdateDatePicker

        GetTrip (Err err) ->
            let _ = log "GetTrip err" err
            in
                { model | requesting = False } ! []

        PostTrip (Ok trip) ->
            let _ = log "PostTrip ok" trip
                _ = log "model uid" model.uid
                updateTrip t =
                    if t.uid == trip.uid then
                        { t
                        | title = trip.title
                        , date = trip.date
                        , address = trip.address
                        , info = trip.info
                        , owningUsers = trip.owningUsers
                        , joinedUsers = trip.joinedUsers
                        }
                    else
                        t 

                upsertedTrips =
                    case List.head (List.filter (\t -> t.uid == trip.uid) model.trips) of
                        Nothing -> 
                            let _ = log "upsertedTrips didn't find" trip.uid
                            in [ trip ] ++ List.filter (\t -> t.uid /= "") model.trips
                        Just val ->
                            let _ = log "upsertedTrips did find" trip.uid
                            in List.map updateTrip model.trips
            in
                if String.isEmpty model.uid || model.uid == trip.uid then
                    { model
                    | requesting = False
                    , uid = trip.uid
                    , title = trip.title
                    , date = trip.date
                    , address = trip.address
                    , info = trip.info
                    , owningUsers = trip.owningUsers
                    , joinedUsers = trip.joinedUsers
                    , hasEdited = False
                    , trips = upsertedTrips
                    }
                        ! []

                else
                    { model
                    | requesting = False
                    , hasEdited = False
                    , trips = List.map updateTrip model.trips
                    }
                        ! []

        PostTrip (Err err) ->
            let _ = log "PostTrip err" err
            in
                { model | requesting = False } ! []

{-
        UpdateDatePicker ->
            let _ = log "UpdateDatePicker"
                pickedDate =
                    Date.fromIsoString model.date

                ( datePicker, datePickerFx ) =
                    DatePicker.init
                        { defaultSettings
                        | placeholder = "Pick a date..."
                        , pickedDate = pickedDate
                        }
            in
                ( { model | datePicker = datePicker }, Cmd.map ToDatePicker datePickerFx )

        ToDatePicker msg ->
            let
                ( newDatePicker, datePickerFx, maybeDate ) =
                    DatePicker.update msg model.datePicker

                _ = log "ToDatePicker maybeDate:" maybeDate

                _ = log "ToDatePicker datePickerFx:" datePickerFx

                dateStr =
                    case maybeDate of
                        Nothing ->
                            model.date

                        Just date ->
                            Date.toFormattedString "yyyy-MM-dd" date

                hasEdited =
                    case maybeDate of
                        Nothing ->
                            model.hasEdited

                        Just date ->
                            True
            in
                { model
                | date = dateStr
                , datePicker = newDatePicker
                , hasEdited = hasEdited
                }
                    ! [ Cmd.map ToDatePicker datePickerFx ]
-}