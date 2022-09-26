module ProOperate exposing
    ( productType
    , terminalId
    , firmwareVersion
    , contentsSetVersion
    , Config_pro2, defaultConfig_pro2
    , ResponseObject, untilTouch_pro2
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


# Touch

@docs Config_pro2, defaultConfig_pro2
@docs ResponseObject, untilTouch_pro2

-}

import Dict exposing (Dict)
import Elm.Kernel.ProOperate
import Maybe exposing (Maybe)
import ProOperate.Card as Card exposing (Felica, Mifare)
import ProOperate.Error as Error exposing (Error, newError)
import String exposing (String)
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
