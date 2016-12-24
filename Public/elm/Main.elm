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

import Date exposing (Date, Day(..), day, dayOfWeek, month, year)
import DatePicker exposing (defaultSettings)
 
import Random exposing (..)
import Random.String exposing (..)
import Random.Char exposing (..)

type alias Id = String 

type alias Flags =
  { uid : Id
  , name : String
  , info : String
  , isNew : Bool
  }

main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model flags.uid flags.name flags.info flags.isNew []
    , fetchTrips
    )

-- MODEL

type alias Model =
    { uid : Id
    , name : String
    , info : String
    , isNew : Bool
    , trips : List Trip
    }

type alias Trip =
    { uid : Id
    , name : String
    , info : String
    }

emptyModel : Model
emptyModel =
    { uid = ""
    , name = ""
    , info = "" 
    , isNew = True
    , trips = []
    }
 
newTrip : String -> String -> String -> Trip
newTrip uid name info =
    { uid = uid
    , name = name
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
        _ = Debug.log ("fetchTrip uid:" ++ uid)
        request =
            Http.get (apiTrip ++ "/" ++ uid) tripDecoder
    in
        Http.send FetchTrip request

updateTrip : Trip -> Cmd Msg
updateTrip trip =
    let
        _ = Debug.log ("updateTrip uid:" ++ trip.uid)
        request = 
            Http.post apiTrip (Http.jsonBody (tripEncoder trip)) tripDecoder 
    in
        Http.send UpdateTrip request

-- UPDATE

type Msg
    = NoOp

    | Add
    | Delete Id

    | Edit Id
    | Name String
    | Info String

    | Reset
    | Save

    | FetchTrips (Result Http.Error (List Trip))
    | AddCurTripIfNeeded 

    | FetchTrip (Result Http.Error Trip)
    | UpdateTrip (Result Http.Error Trip)

    | NewUid String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Add ->
            { model
                | uid = ""
                , name = ""
                , info = ""
                , isNew = True
                , trips = model.trips
            }
                ! [ Random.generate NewUid (Random.String.string 6 Random.Char.english) ]

        Delete uid ->
            { model | trips = List.filter (\t -> t.uid /= uid) model.trips }
                ! []

        Edit uid ->
            let t = Maybe.withDefault 
                        { uid = "efg"
                        , name = ""
                        , info = ""
                        }
                        (List.head (List.filter (\t -> t.uid == uid) model.trips))
            in 
                { model
                    | uid = uid
                    , name = t.name
                    , info = t.info
                    , isNew = String.isEmpty t.name
                }
                    ! []

        Name name ->
            { model | name = name} ! []

        Info info ->
            { model | info = info} ! []

        Reset ->
            (model, fetchTrip model.uid)

        Save ->
            (model, updateTrip (Trip model.uid model.name model.info))

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
                            [ newTrip model.uid model.name model.info ] ++ model.trips
                            
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
                    , info = trip.info
                } 
                    ! []

        FetchTrip (Err err) ->
            let _ = Debug.log "FetchTrip err" err
            in 
            (model, Cmd.none)

        UpdateTrip (Ok trip) ->
            let _ = Debug.log "UpdateTrip ok" trip

                updateTrip t =
                    if t.uid == trip.uid then
                        { t 
                            | name = trip.name
                            , info = trip.info
                        }
                    else 
                        t
            in 
                { model | isNew = False, trips = List.map updateTrip model.trips }
                    ! []

        UpdateTrip (Err err) ->
            let _ = Debug.log "UpdateTrip err" err
            in 
            (model, Cmd.none)

        NewUid newUid ->
            { model 
                | uid = newUid
                , trips = [ newTrip newUid model.name model.info ] ++ model.trips
            } 
                ! []

-- VIEW

view : Model -> Html Msg
view model =
    div [ class "m-x-auto" ]
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "col-sm-8" ]
                    [ section [ class "trip-info" ]
                        [ label [] [ text ("Share URL: id/" ++ model.uid ++ " isNew:" ++ (if model.isNew then "true" else "false")) ]
                        , input [ placeholder "Enter Name...", value (model.name), onInput Name, nameStyle ] []
                        , br [] []
                        , br [] []
                        , textarea [ cols 40, rows 10, placeholder "Info...", value (model.info), onInput Info, infoStyle ] []
                        , div [ class "btn-group" ]
                            [ button [ onClick Reset, class "btn btn-secondary ml-3 mr-1", disabled model.isNew ] [ text "Reset" ]
                            , button [ onClick Save, class "btn btn-primary ml-1 mr-3", disabled (String.isEmpty model.name) ] [ text "Save" ]
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

infoStyle =
    style
        [ ( "width", "100%" )
        , ( "height", "150px" )
        , ( "padding", "10px 0" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ] 

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



