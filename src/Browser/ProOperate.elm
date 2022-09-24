module Browser.ProOperate exposing
    ( Config_pro2
    , ResponseObject
    , Felica, Mifare
    , FelicaService, MifareService
    , felica, sapica, suica
    , defaultConfig_pro2
    , productType, terminalId, firmwareVersion, contentsSetVersion
    , untilTouch_pro2
    )

{-| This library is PitTouch-Device API wrapper.


# Types

@docs Config_pro2
@docs ResponseObject


# Card Types

@docs Felica, Mifare


# Card ConfigTypes

@docs FelicaService, MifareService


# Card Constructor

@docs felica, sapica, suica


# Configration Helper

@docs defaultConfig_pro2


# Functions

@docs productType, terminalId, firmwareVersion, contentsSetVersion


# Touch

@docs untilTouch_pro2


# Sound

@docs playSound

-}

import Dict
import Elm.Kernel.ProOperate
import List exposing (List)
import Maybe exposing (Maybe)
import Result exposing (Result)
import Task exposing (Task)


{-| -}
type alias ResponseObject =
    { category : Int
    , paramResult : Maybe Int
    , auth : Maybe String
    , idm : Maybe String
    , data : Maybe String
    }


{-| -}
type alias MifareService =
    { address : String
    , keyType : Int
    , keyValue : String
    }



-- CONFIG


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
    , felicas = [ Card.felica ]
    , mifares = []
    , typeB = False
    }



-- CARD


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
felica : Felica
felica =
    Felica "FFFF" True []


{-| -}
suica : Felica
suica =
    Felica "0003" True [ FelicaService "090F" 0 20 ]


{-| -}
sapica : Felica
sapica =
    Felica "865E" True [ FelicaService "090F" 0 20 ]



-- MISC


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



-- Touch Task


{-| -}
untilTouch_pro2 : Config_pro2 -> Task Error ResponseObject
untilTouch_pro2 config =
    let
        errors =
            [ ( -2, Error.new "File not found." "successSound or failSound" )
            , ( -3, Error.new "System busy." "System" )
            ]

        toError n =
            Dict.fromList errors
                |> Dict.get n
                |> Maybe.withDefault (Error.new "Unknown Error" "Where?")
    in
    Elm.Kernel.ProOperate.startCommunication_pro2 config toError



-- Sound Task


{-| -}
playSound : String -> Task Error Int
playSound filePath =
    Elm.Kernel.ProOperate.playSound filePath
        |> Task.mapError soundErrorFromInt



-- Inner


{-| -}
soundErrorFromInt : Int -> Error
soundErrorFromInt n =
    let
        errors =
            [ ( -1, Error.new "Arg Error." "param.*" )
            , ( -2, Error.new "Sound file not exist." "param.filePath" )
            , ( -3, Error.new "Invalid file format." "param.filePath" )
            , ( -4, Error.new "Too many play sound." "Sound System" )
            , ( -5, Error.new "System Busy" "Sound System" )
            ]
    in
    Dict.fromList errors
        |> Dict.get n
        |> Maybe.withDefault (Error.new "Unknown Error" "Sound System")
