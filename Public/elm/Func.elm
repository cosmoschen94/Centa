module Func exposing (..)

import Model exposing (..)

-- Common

log : String -> a -> ()
log str a =
    let _ = Debug.log (str ++ " ") a
    in ()

-- Auth

hasLoggedIn : Model -> Bool
hasLoggedIn model =
    not (String.isEmpty model.token)

canLogin : Model -> Bool
canLogin model =
    not (String.isEmpty model.email || String.isEmpty model.password)

canRegister : Model -> Bool
canRegister model =
    not (String.isEmpty model.name || String.isEmpty model.email || String.isEmpty model.password)

-- Trip

canAdd : Model -> Bool
canAdd model = 
    let 
        hasUnsavedTrip =
            case List.head (List.filter (\t -> String.isEmpty t.uid ) model.trips) of
                Nothing -> False
                Just val -> True
        _ = Debug.log "canAdd requesting? " model.requesting
        _ = Debug.log "canAdd model.uid " model.uid
        _ = Debug.log "canAdd hasUnsavedTrip? " hasUnsavedTrip
    in
        not model.requesting 
        && not (String.isEmpty model.uid)
        && not hasUnsavedTrip

canClear : Model -> Bool
canClear model = 
    not model.requesting
    && String.isEmpty model.uid
    && not (String.isEmpty model.title && String.isEmpty model.info)

canRestore : Model -> Bool
canRestore model = 
    not model.requesting
    && not (String.isEmpty model.uid)
    && model.hasEdited

canSave : Model -> Bool
canSave model = 
    not model.requesting
    && not (String.isEmpty model.title)
    && (String.isEmpty model.uid || model.hasEdited )