module View exposing (..)

import Model exposing (..)
import Func exposing (..)
import Flow exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)

view : Model -> Html Msg
view model =
    div [ class "m-x-auto" ]
        [ div [ class "row" ]
        [ div [ class "col-sm-8" ] [ lazy viewTrip model ]
        , div [ class "col-sm-4" ]
            [ lazy viewAuthUser model
            , lazy viewTrips model
            ]
        ]
        , infoFooter
        , section [ class "debug-info" ]
        [ label []
            [ text (
                "Debug Info:  •••  Share URL: /id/" ++ model.uid ++ "  •••  hasEdited: " ++
                (if model.hasEdited then "True" else "False")
              ) ]
        ]
    ]

-- View User

viewAuthUser : Model -> Html Msg
viewAuthUser model =
    if hasLoggedIn model then
        section [ class "user" ]
            [ label [] [ text "My Info" ]
            , br [] []
            , label [] [ text ("Hello " ++ model.name ++ "!!") ]
            , span [] []
            , button
                [ onClick Logout
                , class "btn btn-secondary"
                , disabled model.requesting
                ]
                [ text "Logout" ]
            , br [] []
            , br [] []
            , div [] [ lazy viewUserTrips model ]
            ]
    else
        section [ class "user" ]
            [ label [] [ text "My Info" ]
            , br [] []
            , br [] []
            , input [ placeholder "email", value (model.email), onInput Email, class "email" ] []
            , br [] []
            , input [ placeholder "password", value (model.password), onInput Password, class "passowrd" ] []
            , br [] []
            , br [] []
            , button
                [ onClick Login
                , class "btn btn-primary"
                , disabled (model.requesting || not (canLogin model))
                ]
                [ text "Login" ]
            , br [] []
            , br [] []
            , input [ placeholder "name", value (model.name), onInput Name, class "name" ] []
            , br [] []
            , br [] []
            , button
                [ onClick Register
                , class "btn btn-primary"
                , disabled (model.requesting || not (canRegister model))
                ]
                [ text "Register" ]
            
            , br [] []
            , br [] []
            ]

-- View Trips

viewUserTrips : Model -> Html Msg
viewUserTrips model =
    section [ class "trip-entries" ]
        [ label [] [ text "Your Trips" ]
        , br [] []
        --, button [ onClick Add, class "btn-block btn btn-success", disabled (model.requesting || String.isEmpty model.uid) ] [ text "Add New" ]
        , br [] []
        , lazy viewTripEntries model.trips
        ]

-- View Trip

viewTrip : Model -> Html Msg
viewTrip model =
    section [ class "trip-content" ]
    -- Title
        [ input
            [ placeholder "Enter Title..."
            , value (model.title)
            , onInput Title
            , class "trip-title"
            ]
            []
        , br [] []
        , br [] []
        -- Date
        -- , div [ class "form-group" ]
        --    [ DatePicker.view model.datePicker |> Html.map ToDatePicker ]
        -- Address
        , div [ class "group" ]
            [ a
                [ href ("http://baidu.com/s?wd=" ++ model.address)
                , target "_blank"
                , hidden (String.isEmpty model.address)
                , class "mr-1"
                ]
                [ text "Map" ]
            , input
                [ placeholder "Enter Address..."
                , value (model.address)
                , onInput Address
                , class "trip-address"
                ]
                []
            ]
        , br [] []
        , br [] []
        -- CurUser status
        , label [] [ text ("Your Status:") ]
        --(tripUsers: " ++ model.owningUsers ++ model.joinedUsers ")") ]
        , let 
            isOwning = 
              case List.head (List.filter (\u -> u.uid == model.userUid) model.owningUsers) of
                  Nothing -> False
                  Just val -> True

            isJoined =
              case List.head (List.filter (\u -> u.uid == model.userUid) model.joinedUsers) of
                  Nothing -> False
                  Just val -> True

          in
              div [ class "btn-group" ]
                  [ button
                      [ onClick JoinTrip
                      , class "btn btn-primary ml-1 mr-1"
                      , disabled (model.requesting || isOwning || isJoined)
                      ]
                      [ text ( if isOwning || isJoined then "Joined" else "Join" ) ]
                  , button
                      [ onClick LeaveTrip
                      , class "btn btn-secondary ml-1 mr-3"
                      , disabled (model.requesting || (not isOwning && not isJoined))
                      , hidden (not (isOwning || isJoined))
                      ]
                      [ text "Leave" ]

                  ]
        , br [] []
        , br [] []
        -- TripUsers
        , label [] [ text "Trip Owners:" ]
        , div [ class "group" ]
            [ lazy viewUsers model.owningUsers ]

        , div [ class "group" ]
            [ label [] [ text "Trip Members:" ]
            , lazy viewUsers model.joinedUsers 
            ]

        -- Info
        , textarea
            [ cols 40
            , rows 16
            , placeholder "Info..."
            , value (model.info)
            , onInput Info
            , class "trip-info"
            ]
            []
        -- Reset & Save
        , div [ class "btn-group" ]
            [ button
                [ onClick Reset
                , class "btn btn-secondary mr-1"
                , disabled (not (canClear model || canRestore model))
                ]
                [ text (if canClear model then "Clear" else "Restore") ]
            , button
                [ onClick Save
                , class "btn btn-primary ml-1 mr-3"
                , disabled (not (canSave model))
                ]
                [ text "Save" ]
            ]
        , br [] []
        , br [] []
        ]

viewUsers : List User -> Html Msg
viewUsers users =
    let _ = Debug.log "viewUsers " users
    in
        Keyed.ol [] <| List.map viewKeyedUser users 

viewKeyedUser : User -> ( String, Html Msg )
viewKeyedUser user =
    ( user.uid, lazy viewUser user )

viewUser : User -> Html Msg
viewUser user =
    label [ class "trip-member" ] [ text (user.name) ]

-- View Trip Entries

viewTrips : Model -> Html Msg
viewTrips model =
    section [ class "trip-entries" ]
        [ label [] [ text "Upcoming Trips" ]
        , br [] []
        , button
            [ onClick Add
            , class "btn-block btn btn-success"
            , disabled (not (canAdd model))
            ]
            [ text "Add New" ]
        , br [] []
        , lazy viewTripEntries model.trips
        ]

viewTripEntries : List Trip -> Html Msg
viewTripEntries trips =
    let _ = Debug.log "ViewTrips " trips
    in
        section []
            [ Keyed.ol [] <| List.map viewKeyedTripEntry trips ]

viewKeyedTripEntry : Trip -> ( String, Html Msg )
viewKeyedTripEntry trip =
    ( trip.uid, lazy viewTripEntry trip )

viewTripEntry : Trip -> Html Msg
viewTripEntry trip =
    let
        isUnsaved = String.isEmpty trip.uid

        title =
            if isUnsaved then "Unsaved New Trip"
            else trip.title
    in
        button
            [ onClick (Edit trip.uid)
            , classList
                [ ( "btn-block", True )
                , ( "btn btn-outline-danger", isUnsaved )
                , ( "btn btn-outline-info", not isUnsaved )
                ]
            , style [ ( "font-size", "1.3vw" ) ]
            ]
            [ text (title) ]

-- VIEW MISC

infoFooter : Html msg
infoFooter =
    footer [ class "info" ]
        [ p [] [ text "Making it happen" ]
        , p [] [ text "By hyouuu & Jackson" ]
        ]