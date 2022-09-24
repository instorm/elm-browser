module Browser.ProOperate exposing
    ( ResponseObject
    , productType, terminalId, firmwareVersion, contentsSetVersion
    , untilTouch_pro2
    )

{-| This library is PitTouch-Device API wrapper.


# Types

@docs ResponseObject


# Functions

@docs productType, terminalId, firmwareVersion, contentsSetVersion


# Tasks

@docs untilTouch_pro2

-}

import Dict
import Elm.Kernel.ProOperate
import Maybe exposing (Maybe)
import ProOperate.Card as Card exposing (Felica, Mifare)
import ProOperate.Config as Config exposing (Config_pro2, defaultConfig_pro2)
import ProOperate.Error as Error exposing (Error)
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
