effect module ProOperate.Keypad where { subscription = MySub } exposing
    ( Device
    , device
    , UsbStatus, usbStatus
    , Display
    , getDisplayString, setDisplayString
    , observeUsb, observeKeyUp, observeKeyDown
    , andThenKeypad
    , mapDisplayKeypad
    , mapFirstLineKeypad
    , mapSecondLineKeypad
    , mapBothLineKeypad
    , KeypadEvent
    )

{-| This Module is an inteface for Keypad device supported by PitTouch.


## Overview

Provides a device operation interface for keypad device supported by PitTouch.


# Types & Constructor

@docs Device
@docs device


# USB Status

@docs UsbStatus, usbStatus


# Keypad Display

@docs Display
@docs getDisplayString, setDisplayString


# Subscription

@docs observeUsb, observeKeyUp, observeKeyDown


# Funcy Function for Keypad Display

@docs andThenKeypad
@docs mapDisplayKeypad
@docs mapFirstLineKeypad
@docs mapSecondLineKeypad
@docs mapBothLineKeypad


# Effect Manager

@docs KeypadEvent

-}

import Dict exposing (Dict)
import Elm.Kernel.ProOperate
import Maybe exposing (Maybe)
import Platform
import ProOperate.Error as Error exposing (Error)
import Process
import Task exposing (Task)



-- Keypad Device


{-| -}
type Device
    = Device ()


{-| -}
device : Task Error Device
device =
    Task.succeed <| Device ()



-- USB Status


{-| -}
type UsbStatus
    = KeypadConnected
    | KeypadDisconnection
    | SystemBusy


{-| -}
usbStatus : Task Never UsbStatus
usbStatus =
    let
        result =
            Elm.Kernel.ProOperate.getKeypadConnected ()
    in
    if result < 0 then
        Task.succeed SystemBusy

    else
        Task.succeed <| usbStatusFromInt result


{-| -}
usbStatusFromInt : Int -> UsbStatus
usbStatusFromInt n =
    if n == 1 then
        KeypadConnected

    else
        KeypadDisconnection


{-| -}
type KeypadEvent msg
    = Usb (UsbStatus -> msg)
    | KeyUp (Int -> msg)
    | KeyDown (Int -> msg)


{-| -}
type alias Display =
    { firstLine : String
    , secondLine : String
    }


{-| -}
getDisplayString : Task Error Display
getDisplayString =
    Elm.Kernel.ProOperate.getKeypadDisplay ()
        |> Task.mapError Error.keypadDisplayErrorFromInt


{-| -}
setDisplayString : Display -> Task Error ()
setDisplayString display =
    Elm.Kernel.ProOperate.setKeypadDisplay display
        |> Task.map (always ())
        |> Task.mapError Error.keypadDisplayErrorFromInt


{-| -}
andThenKeypad : (Display -> Task Error b) -> Task Error Device -> Task Error b
andThenKeypad f keypadDevice =
    keypadDevice
        |> Task.andThen (always getDisplayString)
        |> Task.andThen f


{-| -}
mapDisplayKeypad :
    (Display -> Display)
    -> Task Error Device
    -> Task Error Device
mapDisplayKeypad f keypadDevice =
    keypadDevice
        |> Task.andThen (always getDisplayString)
        |> Task.map f
        |> Task.andThen setDisplayString
        |> Task.andThen (always device)


{-| -}
mapBothLineKeypad :
    (String -> String)
    -> (String -> String)
    -> Task Error Device
    -> Task Error Device
mapBothLineKeypad f1 f2 keypadDevice =
    let
        applyFunction r =
            { r
                | firstLine = f1 r.firstLine
                , secondLine = f2 r.secondLine
            }
    in
    mapDisplayKeypad applyFunction keypadDevice


{-| -}
mapFirstLineKeypad :
    (String -> String)
    -> Task Error Device
    -> Task Error Device
mapFirstLineKeypad f keypadDevice =
    mapBothLineKeypad f identity keypadDevice


{-| -}
mapSecondLineKeypad :
    (String -> String)
    -> Task Error Device
    -> Task Error Device
mapSecondLineKeypad f keypadDevice =
    mapBothLineKeypad identity f keypadDevice



-- Sub msg


{-| -}
observeUsb : (UsbStatus -> msg) -> Sub msg
observeUsb tagger =
    subscription (MySub "usb" (Usb tagger))


{-| -}
observeKeyUp : (Int -> msg) -> Sub msg
observeKeyUp tagger =
    subscription (MySub "keyup" (KeyUp tagger))


{-| -}
observeKeyDown : (Int -> msg) -> Sub msg
observeKeyDown tagger =
    subscription (MySub "keydown" (KeyDown tagger))



-- For Effect Manager


{-| -}
type alias Taggers msg =
    List (KeypadEvent msg)


{-| -}
type alias Subscribers msg =
    Dict String (Taggers msg)


{-| -}
type alias State msg =
    { subs : Subscribers msg
    , pid : Maybe Process.Id
    }


{-| -}
type MySub msg
    = MySub String (KeypadEvent msg)


{-| -}
init : Task Never (State msg)
init =
    Task.succeed
        { subs = Dict.empty
        , pid = Nothing
        }


{-| -}
subMap : (a -> b) -> MySub a -> MySub b
subMap f (MySub _ tagger) =
    case tagger of
        Usb g ->
            MySub "usb" (Usb (f << g))

        KeyUp g ->
            MySub "keyup" (KeyUp (f << g))

        KeyDown g ->
            MySub "keydown" (KeyDown (f << g))


{-| -}
categorize : List (MySub msg) -> Subscribers msg
categorize newSub =
    categorizeHelp newSub Dict.empty


{-| -}
categorizeHelp :
    List (MySub msg)
    -> Subscribers msg
    -> Subscribers msg
categorizeHelp newSub subs =
    let
        concat : a -> Maybe (List a) -> Maybe (List a)
        concat a xs =
            Maybe.withDefault [] xs
                |> (::) a
                |> Just
    in
    case newSub of
        [] ->
            subs

        (MySub category tagger) :: rest ->
            categorizeHelp rest <|
                Dict.update category (concat tagger) subs


{-| -}
type alias Msg =
    { category : String
    , eventCode : Int
    }


{-| -}
onEffects :
    Platform.Router msg Msg
    -> List (MySub msg)
    -> State msg
    -> Task Never (State msg)
onEffects router newSubs { subs, pid } =
    let
        leftStep _ _ task =
            task

        bothStep category _ taggers task =
            Task.map (Dict.insert category taggers) task

        rightStep category taggers task =
            Task.map (Dict.insert category taggers) task
    in
    Dict.merge
        leftStep
        bothStep
        rightStep
        subs
        (categorize newSubs)
        (Task.succeed Dict.empty)
        |> Task.andThen (spawnHelp router pid)


{-| -}
watch :
    (Msg -> Task Never ())
    -> (String -> Int -> Msg)
    -> Task x Never
watch =
    Elm.Kernel.ProOperate.startKeypadListen


{-| -}
spawnHelp :
    Platform.Router msg Msg
    -> Maybe Process.Id
    -> Subscribers msg
    -> Task Never (State msg)
spawnHelp router maybePid subs =
    case maybePid of
        Nothing ->
            if Dict.isEmpty subs then
                Task.succeed (State subs maybePid)

            else
                Process.spawn (watch (Platform.sendToSelf router) Msg)
                    |> Task.map (\pid -> State subs (Just pid))

        Just pid ->
            if Dict.isEmpty subs then
                Process.kill pid
                    |> Task.map (always (State Dict.empty Nothing))

            else
                Task.succeed (State subs maybePid)


{-| -}
onSelfMsg :
    Platform.Router msg Msg
    -> Msg
    -> State msg
    -> Task Never (State msg)
onSelfMsg router msg state =
    let
        send tagger =
            Platform.sendToApp router <|
                case tagger of
                    Usb f ->
                        f <| usbStatusFromInt msg.eventCode

                    KeyUp f ->
                        f msg.eventCode

                    KeyDown f ->
                        f msg.eventCode
    in
    case Dict.get msg.category state.subs of
        Nothing ->
            Task.succeed state

        Just taggers ->
            Task.sequence (List.map send taggers)
                |> Task.map (always state)
