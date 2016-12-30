module Main exposing (..)

import String
import Array exposing (Array)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)

import Task
import Http
import Json.Decode as Decode
import Json.Encode as Encode

import Date exposing (Date, Month(..), Day(..), day, dayOfWeek, month, year)
import Date.Extra as Date

import DatePicker exposing (defaultSettings)
 
import Random exposing (..)
import Random.String exposing (..)
import Random.Char exposing (..)

type alias Id = String 

type alias Flags =
  { uid : Id
  , name : String
  , date : String
  , address : String
  , info : String
  , isNew : Bool
  }

-- MODEL

type alias Model =
    { 
    -- Trip
      uid : Id
    , name : String
    , date : String -- yyyy-mm-dd: 2016-12-24
    , address : String
    , info : String

    , datePicker : DatePicker.DatePicker

    -- Trip Meta
    , isNew : Bool
    , hasEdited : Bool

    -- Trip List
    , trips : List Trip

    -- App State
    --, urlLocation Navigation.Location
    }

type alias Trip =
    { uid : Id
    , name : String
    , date : String
    , address : String
    , info : String
    }
 
-- FUNCTIONS

main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

init : Flags -> ( Model, Cmd Msg )
init flags =
    let 
        pickedDate = Date.fromIsoString flags.date

        ( datePicker, datePickerFx ) =
            DatePicker.init
                { defaultSettings
                    | placeholder = "Pick a date..."
                    , pickedDate = pickedDate
                } 
    --                                                                                 hasEdited trips
        model = Model flags.uid flags.name flags.info flags.date flags.address datePicker flags.isNew False []

    in
        ( model,  Cmd.batch [ fetchTrips, Cmd.map ToDatePicker datePickerFx])

--updateDatePicker : Cmd Msg
--updateDatePicker =


newTrip : String -> String -> String -> String -> String -> Trip
newTrip uid name date address info =
    { uid = uid
    , name = name
    , date = date
    , address = address
    , info = info
    }

-- JSON 

tripsDecoder : Decode.Decoder (List Trip)
tripsDecoder = 
    let _ = Debug.log "tripsDecoder fields" (Decode.field "body" Decode.string)
    in 
    Decode.list tripDecoder

tripDecoder : Decode.Decoder Trip
tripDecoder = 
    let _ = Debug.log "tripDecoder fields" (Decode.field "body" Decode.string)
    in 
    Decode.map5 Trip
        (Decode.field "uid" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "date" Decode.string)
        (Decode.field "address" Decode.string)
        (Decode.field "info" Decode.string)       
 
tripEncoder : Trip -> Encode.Value
tripEncoder trip =
    Encode.object
        [ ("uid", Encode.string trip.uid)
        , ("name", Encode.string trip.name)
        , ("date", Encode.string trip.date)
        , ("address", Encode.string trip.address)
        , ("info", Encode.string trip.info)
        ]

-- API

apiTrips = "/api/trips"
apiTrip = "/api/trip"

fetchTrips : Cmd Msg
fetchTrips =
    let 
        _ = Debug.log "fetchTrips"
        request =
            Http.get (apiTrips) tripsDecoder
    in
        Http.send FetchTrips request

fetchTrip : Id -> Cmd Msg
fetchTrip uid =
    let
        _ = Debug.log "fetchTrip uid:" NewUid
        request =
            Http.get (apiTrip ++ "/" ++ uid) tripDecoder
    in
        Http.send FetchTrip request

upsertTrip : Trip -> Cmd Msg
upsertTrip trip =
    let
        _ = Debug.log "upsertTrip uid:" trip.uid
        request = 
            Http.post apiTrip (Http.jsonBody (tripEncoder trip)) tripDecoder 
    in
        Http.send UpsertTrip request

-- UPDATE

type Msg
    = NoOp

    | Add
    | Delete Id

    | Edit Id
    | Name String
    | Address String
    | Info String

    | Reset
    | Save

    | FetchTrips (Result Http.Error (List Trip))
    | AddCurTripIfNeeded 

    | FetchTrip (Result Http.Error Trip)
    | UpsertTrip (Result Http.Error Trip)

    | NewUid String

    | UpdateDatePicker 
    | ToDatePicker DatePicker.Msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Add ->
            { model
                | uid = ""
                , name = ""
                , date = ""
                , address = ""
                , info = ""
                , isNew = True
                , hasEdited = False
                , trips = model.trips
            }
                ! [ Random.generate NewUid (Random.String.string 6 Random.Char.english) ]

        Delete uid ->
            { model | trips = List.filter (\t -> t.uid /= uid) model.trips }
                ! []

        Edit uid ->
            let t = Maybe.withDefault 
                        { uid = ""
                        , name = ""
                        , date = ""
                        , address = ""
                        , info = ""
                        }
                        (List.head (List.filter (\t -> t.uid == uid) model.trips))
            in 
                { model
                    | uid = uid
                    , name = t.name
                    , date = t.date
                    , address = t.address
                    , info = t.info
                    , isNew = String.isEmpty t.name
                    , hasEdited = False
                }
                    |> update UpdateDatePicker

        Name name ->
            { model | name = name, hasEdited = True } ! []

        Address address ->
            { model | address = address, hasEdited = True } ! []

        Info info ->
            { model | info = info, hasEdited = True } ! []

        Reset ->
            (model, fetchTrip model.uid)

        Save ->
            (model, upsertTrip (Trip model.uid model.name model.date model.address model.info))

        FetchTrips (Ok trips) ->
            let _ = Debug.log "FetchTrips ok" trips
            in
                { model | trips = trips }
                |> update AddCurTripIfNeeded

        FetchTrips (Err err) ->
            let _ = Debug.log "FetchTrips err" err
            in 
            (model, Cmd.none)

        AddCurTripIfNeeded ->
            { model
                | trips =
                    case List.head (List.filter (\t -> t.uid == model.uid) model.trips) of
                        Nothing ->
                            [ newTrip model.uid model.name model.date model.address model.info ] ++ model.trips
                            
                        Just val ->
                            model.trips
            }
                ! []

        FetchTrip (Ok trip) ->
            let _ = Debug.log "FetchTrip ok" trip
            in
                { model
                    | uid = trip.uid
                    , name = trip.name
                    , date = trip.date
                    , address = trip.address
                    , info = trip.info
                    , isNew = False 
                    , hasEdited = False 
                } 
                    |> update UpdateDatePicker

        FetchTrip (Err err) ->
            let _ = Debug.log "FetchTrip err" err
            in 
            (model, Cmd.none)

        UpsertTrip (Ok trip) ->
            let _ = Debug.log "UpsertTrip ok" trip

                updateTrip t =
                    if t.uid == trip.uid then
                        { t 
                            | name = trip.name
                            , date = trip.date
                            , address = trip.address
                            , info = trip.info
                        }
                    else 
                        t
            in 
                { model 
                    | isNew = False
                    , hasEdited = False
                    , trips = List.map updateTrip model.trips 
                }
                    ! []

        UpsertTrip (Err err) ->
            let _ = Debug.log "UpsertTrip err" err
            in 
            (model, Cmd.none)

        NewUid newUid ->
            { model 
                | uid = newUid
                , trips = [ newTrip newUid model.name model.date model.address model.info ] ++ model.trips
            } 
                ! []

        UpdateDatePicker ->
            let 
                _ = Debug.log "UpdateDatePicker"
                pickedDate = Date.fromIsoString model.date

                ( datePicker, datePickerFx ) =
                    DatePicker.init
                        { defaultSettings
                            | placeholder = "Pick a date..."
                            , pickedDate = pickedDate
                        } 
            in 
                ( { model | datePicker = datePicker },  Cmd.map ToDatePicker datePickerFx )

        ToDatePicker msg ->
            let
                ( newDatePicker, datePickerFx, maybeDate ) =
                    DatePicker.update msg model.datePicker

                _ = Debug.log "ToDatePicker maybeDate:" maybeDate
                _ = Debug.log "ToDatePicker datePickerFx:" datePickerFx

                dateStr =
                    case maybeDate of
                        Nothing -> model.date
                        Just date -> Date.toFormattedString "yyyy-MM-dd" date

                hasEdited =
                    case maybeDate of
                        Nothing -> model.hasEdited
                        Just date -> True
            in
                { model
                    | date = dateStr
                    , datePicker = newDatePicker
                    , hasEdited = hasEdited
                }
                    ! [ Cmd.map ToDatePicker datePickerFx ]


-- VIEW

view : Model -> Html Msg
view model =
    div [ class "m-x-auto" ]
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "col-sm-8" ]
                    [ section [ class "trip-info" ]
                        [ label [] 
                            [ text ("Share URL: /id/" ++ model.uid 
                            ++ " isNew:" ++ (if model.isNew then "true" else "false") 
                            ++ " hasEdited:" ++ (if model.hasEdited then "true" else "false")) 
                            ]
                        , input [ placeholder "Enter Name...", value (model.name), onInput Name, nameStyle ] []
                        , br [] []
                        , br [] []
                        , div [ class "form-group" ]
                            [ DatePicker.view model.datePicker
                                |> Html.map ToDatePicker
                            ]
                        , a [ href ("http://baidu.com/s?wd=" ++ model.address), target "_blank", hidden (String.isEmpty model.address), class "mr-1" ] [ text "Map" ]
                        , input [ placeholder "Enter Address...", value (model.address), onInput Address, addressStyle ] []
                        , br [] []
                        , br [] []
                        , textarea [ cols 40, rows 16, placeholder "Info...", value (model.info), onInput Info, infoStyle ] []
                        , div [ class "btn-group" ]
                            [ button [ onClick Reset, class "btn btn-secondary mr-1", disabled (model.isNew || not model.hasEdited) ] [ text "Reset" ]
                            , button [ onClick Save, class "btn btn-primary ml-1 mr-3", disabled (String.isEmpty model.name || not model.hasEdited) ] [ text "Save" ]
                            ] 
                        ]
                    ]
                , div [ class "col-sm-4" ]
                    [ section [ class "all-tirps" ]
                        [ label [] [ text "Upcoming Trips" ]
                        , br [] []
                        , button [ onClick Add, class "btn-block btn btn-success", disabled model.isNew ] [ text "Add New" ]
                        , br [] []
                        , lazy viewTrips model.trips 
                        ]
                    ]
                ]
            , infoFooter
            ]
        ]

-- VIEW TRIPS

viewTrips : List Trip -> Html Msg
viewTrips trips =
    let _ = Debug.log "ViewTrips " trips
    in 
        section []
            [ Keyed.ol [] <|
                List.map viewKeyedTrip trips
            ]

viewKeyedTrip : Trip -> (String, Html Msg)
viewKeyedTrip trip = 
    ( trip.uid, lazy viewTrip trip) 

viewTrip : Trip -> Html Msg
viewTrip trip =
    let 
        nameEmpty = String.isEmpty trip.name

        title = 
            if nameEmpty then
                "Unsaved New Trip"
            else
                trip.name

    in
        button 
            [ onClick (Edit trip.uid)
            , classList
                [ ("btn-block", True)
                , ("btn btn-outline-danger", nameEmpty)
                , ("btn btn-outline-info", not nameEmpty)
                ]
            , style [ ("font-size", "1.3vw") ]
            ]
            [ text (title) ]

-- VIEW MISC

infoFooter : Html msg
infoFooter =
    footer [ class "info" ]
        [ p [] [ text "Making it happen" ]
        , p [] [ text "By hyouuu & Jackson" ]
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

addressStyle =
    style
        [ ( "width", "90%" )
        , ( "height", "40px" )
        , ( "padding", "20px 20px" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ] 

infoStyle =
    style
        [ ( "width", "100%" )
        , ( "height", "200px" )
        , ( "padding", "10px 0" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ] 

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



