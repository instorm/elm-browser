effect module ProOperate where { subscription = MySub } exposing
    ( productType
    , terminalId
    , firmwareVersion
    , contentsSetVersion
    , Error
    , newError
    , Felica, FelicaService
    , Mifare, MifareService
    , felicaCard, suicaCard, sapicaCard
    , playSound
    , Config_pro2, defaultConfig_pro2
    , ResponseObject, untilTouch_pro2
    , UsbStatus, usbStatus
    , Keypad, keypad
    , Display
    , getDisplayString, setDisplayString
    , andThenKeypad
    , mapDisplayKeypad
    , mapFirstLineKeypad
    , mapSecondLineKeypad
    , mapBothLineKeypad
    , observeUsb, observeKeyUp, observeKeyDown
    )

{-| This module helps you operate the Pit Touch Pro. This is the
fancy api for PitTouchApp Developper.

The most important function is [`untilTouch_pro2`](#untilTouch_pro2) which untile the
touch the card.


## What is a PitTouch?

PitTouch is Reader for Felica.


# Device Information

@docs productType
@docs terminalId
@docs firmwareVersion
@docs contentsSetVersion


# Error

@docs Error
@docs newError


# Card

@docs Felica, FelicaService
@docs Mifare, MifareService
@docs felicaCard, suicaCard, sapicaCard


# Sound

@docs playSound


# Touch

@docs Config_pro2, defaultConfig_pro2
@docs ResponseObject, untilTouch_pro2


# Usb Status

@docs UsbStatus, usbStatus


# Kypad Device

@docs Keypad, keypad


# Keypad Display

@docs Display
@docs getDisplayString, setDisplayString


# Funcy Function for Keypad Display

@docs andThenKeypad
@docs mapDisplayKeypad
@docs mapFirstLineKeypad
@docs mapSecondLineKeypad
@docs mapBothLineKeypad


# Subscriptions

@docs observeUsb, observeKeyUp, observeKeyDown

-}

import Dict exposing (Dict)
import Elm.Kernel.Browser
import Elm.Kernel.ProOperate
import Maybe exposing (Maybe)
import Process
import Result exposing (Result)
import Task exposing (Task)


{-| -}
productType : String
productType =
    Elm.Kernel.ProOperate.productType


{-| -}
terminalId : String
terminalId =
    Elm.Kernel.ProOperate.getTerminalId ()


{-| -}
firmwareVersion : String
firmwareVersion =
    Elm.Kernel.ProOperate.getFirmwareVersion ()


{-| -}
contentsSetVersion : String
contentsSetVersion =
    Elm.Kernel.ProOperate.getContentsSetVersion ()



{-
    _____
   | ____|_ __ _ __ ___  _ __
   |  _| | '__| '__/ _ \| '__|
   | |___| |  | | | (_) | |
   |_____|_|  |_|  \___/|_|
-}


{-| -}
type alias Error =
    { name : String
    , message : String
    }


{-| -}
newError : String -> String -> Error
newError name message =
    { name = name
    , message = message
    }


{-| -}
keypadDisplayErrorFromInt : Int -> Error
keypadDisplayErrorFromInt n =
    let
        errors =
            [ ( -1, newError "Arg Error." "param.*" )
            , ( -2, newError "Keypad not connected." "Keypad" )
            , ( -3, newError "System busy." "System" )
            ]
    in
    Dict.fromList errors
        |> Dict.get n
        |> Maybe.withDefault (newError "Unknown Error" "Keypad")


{-| -}
soundErrorFromInt : Int -> Error
soundErrorFromInt n =
    let
        errors =
            [ ( -1, newError "Arg Error." "param.*" )
            , ( -2, newError "Sound file not exist." "param.filePath" )
            , ( -3, newError "Invalid file format." "param.filePath" )
            , ( -4, newError "Too many play sound." "Sound System" )
            , ( -5, newError "System Busy" "Sound System" )
            ]
    in
    Dict.fromList errors
        |> Dict.get n
        |> Maybe.withDefault (newError "Unknown Error" "Sound System")



{-
     ____              _
    / ___|__ _ _ __ __| |
   | |   / _` | '__/ _` |
   | |__| (_| | | | (_| |
    \____\__,_|_|  \__,_|
-}


{-| -}
type alias Felica =
    { systemCode : String
    , useMasterIDm : Bool
    , services : List FelicaService
    }


{-| -}
type alias FelicaService =
    { serviceCode : String
    , offsetBlock : Int
    , block : Int
    }


{-| -}
type alias Mifare =
    { type_ : Int
    , services : List MifareService
    }


{-| -}
type alias MifareService =
    { address : String
    , keyType : Int
    , keyValue : String
    }


{-| -}
felicaCard : Felica
felicaCard =
    Felica "FFFF" True []


{-| -}
suicaCard : Felica
suicaCard =
    Felica "0003" True [ FelicaService "090F" 0 20 ]


{-| -}
sapicaCard : Felica
sapicaCard =
    Felica "865E" True [ FelicaService "090F" 0 20 ]



{-
    ____                        _
   / ___|  ___  _   _ _ __   __| |
   \___ \ / _ \| | | | '_ \ / _` |
    ___) | (_) | |_| | | | | (_| |
   |____/ \___/ \__,_|_| |_|\__,_|
-}


{-| -}
playSound : String -> Task Error Int
playSound filePath =
    Elm.Kernel.ProOperate.playSound filePath
        |> Task.mapError soundErrorFromInt



{-
    _____                _
   |_   _|__  _   _  ___| |__
     | |/ _ \| | | |/ __| '_ \
     | | (_) | |_| | (__| | | |
     |_|\___/ \__,_|\___|_| |_|
-}


{-| -}
type alias Config_pro2 =
    { successSound : String
    , failSound : String
    , successLamp : String
    , failLamp : String
    , waitLamp : String
    , felicas : List Felica
    , mifares : List Mifare
    , typeB : Bool
    }


{-| -}
defaultConfig_pro2 : Config_pro2
defaultConfig_pro2 =
    { successSound = "/pjf/sound/success.wav"
    , failSound = "/pjf/sound/fail.wav"
    , successLamp = "BB0N"
    , failLamp = "RR0N"
    , waitLamp = "BG1L"
    , felicas = [ felicaCard ]
    , mifares = []
    , typeB = False
    }


{-| -}
type alias ResponseObject =
    { category : Int
    , paramResult : Maybe Int
    , auth : Maybe String
    , idm : Maybe String
    , data : Maybe String
    }


{-| -}
untilTouch_pro2 : Config_pro2 -> Task Error ResponseObject
untilTouch_pro2 config =
    let
        errors =
            [ ( -2, newError "File not found." "successSound or failSound" )
            , ( -3, newError "System busy." "System" )
            ]

        toError n =
            Dict.fromList errors
                |> Dict.get n
                |> Maybe.withDefault (newError "Unknown Error" "Where?")
    in
    Elm.Kernel.ProOperate.startCommunication_pro2 config toError



{-
    _  __                          _
   | |/ /___ _   _ _ __   __ _  __| |
   | ' // _ \ | | | '_ \ / _` |/ _` |
   | . \  __/ |_| | |_) | (_| | (_| |
   |_|\_\___|\__, | .__/ \__,_|\__,_|
             |___/|_|
-}


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
type Keypad
    = Keypad ()



-- Funcy


{-| -}
type alias Display =
    { firstLine : String
    , secondLine : String
    }


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


{-| -}
keypad : Task Error Keypad
keypad =
    Task.succeed <| Keypad ()


{-| -}
andThenKeypad : (Display -> Task Error b) -> Task Error Keypad -> Task Error b
andThenKeypad f keypadDevice =
    keypadDevice
        |> Task.andThen (always getDisplayString)
        |> Task.andThen f


{-| -}
mapDisplayKeypad :
    (Display -> Display)
    -> Task Error Keypad
    -> Task Error Keypad
mapDisplayKeypad f keypadDevice =
    keypadDevice
        |> Task.andThen (always getDisplayString)
        |> Task.map f
        |> Task.andThen setDisplayString
        |> Task.andThen (always keypad)


{-| -}
mapBothLineKeypad :
    (String -> String)
    -> (String -> String)
    -> Task Error Keypad
    -> Task Error Keypad
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
    -> Task Error Keypad
    -> Task Error Keypad
mapFirstLineKeypad f keypadDevice =
    mapBothLineKeypad f identity keypadDevice


{-| -}
mapSecondLineKeypad :
    (String -> String)
    -> Task Error Keypad
    -> Task Error Keypad
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
