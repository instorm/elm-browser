effect module Browser.ProOperate.Keypad where { subscription = MySub } exposing
    ( Device, Event(..), UsbStatus(..)
    , device
    , mapDisplay, mapFirstLine, mapSecondLine, mapBothLine, andThen
    , observeKeyDown, observeKeyUp, observeUsb
    , usbStatus
    )

{-| Keypad


# Type

@docs Device, Event, UsbStatus


# Object of Keypad Device

@docs device


# Funcy

@docs mapDisplay, mapFirstLine, mapSecondLine, mapBothLine, andThen


# Keypad Observer Functions

@docs observeKeyDown, observeKeyUp, observeUsb


# Function

@docs usbStatus

-}

import Dict exposing (Dict)
import Platform
import ProOperate.Error as Error exposing (Error)
import Process
import Task exposing (Task)


{-| -}
type UsbStatus
    = KeypadConnected
    | KeypadDisconnection
    | SystemBusy


{-| -}
type Event msg
    = Usb (UsbStatus -> msg)
    | KeyUp (Int -> msg)
    | KeyDown (Int -> msg)


{-| -}
type Device
    = Device ()



-- Task


{-| -}
type alias Display =
    { firstLine : String
    , secondLine : String
    }


{-| -}
device : Task Error Device
device =
    Task.succeed <| Device ()


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
andThen : (Display -> Task Error b) -> Task Error Device -> Task Error b
andThen f keypad =
    keypad
        |> Task.andThen (always getDisplayString)
        |> Task.andThen f


{-| -}
mapDisplay : (Display -> Display) -> Task Error Device -> Task Error Device
mapDisplay f keypad =
    keypad
        |> Task.andThen (always getDisplayString)
        |> Task.map f
        |> Task.andThen setDisplayString
        |> Task.andThen (always keypad)


{-| -}
mapBothLine :
    (String -> String)
    -> (String -> String)
    -> Task Error Device
    -> Task Error Device
mapBothLine f1 f2 keypad =
    let
        applyFunction r =
            { r
                | firstLine = f1 r.firstLine
                , secondLine = f2 r.secondLine
            }
    in
    mapDisplay applyFunction keypad


{-| -}
mapFirstLine : (String -> String) -> Task Error Device -> Task Error Device
mapFirstLine f keypad =
    mapBothLine f identity keypad


{-| -}
mapSecondLine : (String -> String) -> Task Error Device -> Task Error Device
mapSecondLine f keypad =
    mapBothLine identity f keypad



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



-- Inner


{-| -}
usbStatusFromInt : Int -> UsbStatus
usbStatusFromInt n =
    if n == 1 then
        KeypadConnected

    else
        KeypadDisconnection


{-| -}
keypadDisplayErrorFromInt : Int -> Error
keypadDisplayErrorFromInt n =
    let
        errors =
            [ ( -1, Error.new "Arg Error." "param.*" )
            , ( -2, Error.new "Keypad not connected." "Keypad" )
            , ( -3, Error.new "System busy." "System" )
            ]
    in
    Dict.fromList errors
        |> Dict.get n
        |> Maybe.withDefault (Error.new "Unknown Error" "Keypad")


{-| -}
getDisplayString : Task Error Display
getDisplayString =
    Elm.Kernel.ProOperate.getKeypadDisplay ()
        |> Task.mapError keypadDisplayErrorFromInt


{-| -}
setDisplayString : Display -> Task Error ()
setDisplayString display =
    Elm.Kernel.ProOperate.setKeypadDisplay display
        |> Task.map (always ())
        |> Task.mapError keypadDisplayErrorFromInt



-- for Effect Manager


{-| -}
type alias Taggers msg =
    List (Event msg)


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
    = MySub String (Event msg)


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
