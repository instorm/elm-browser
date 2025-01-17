effect module ProOperate where { subscription = MySub } exposing
    ( productType
    , terminalId
    , firmwareVersion
    , contentsSetVersion
    , Config_pro2, defaultConfig_pro2
    , TouchResponse, untilTouch_pro2
    , observeTouch
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
@docs TouchResponse, untilTouch_pro2
@docs observeTouch

-}

import Dict exposing (Dict)
import Elm.Kernel.ProOperate
import Maybe exposing (Maybe)
import Platform
import ProOperate.Card as Card exposing (Felica, Mifare)
import ProOperate.Error as Error exposing (Error, newError)
import Process
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
    , felicaList : List Felica
    , mifareList : List Mifare
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
    , felicaList = [ Card.suica, Card.felica ]
    , mifareList = []
    , typeB = False
    }


{-| -}
type alias TouchResponse =
    { category : Int
    , paramResult : Maybe Int
    , auth : Maybe String
    , idm : Maybe String
    , data : Maybe String
    }


{-| -}
untilTouch_pro2 : Config_pro2 -> Task Error TouchResponse
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



-- Sub msg


{-| -}
observeTouch : (TouchResponse -> msg) -> Config_pro2 -> Sub msg
observeTouch tagger config =
    subscription (MySub config (Touch tagger))



-- For Effect Manager


{-| -}
type Event msg
    = Touch (TouchResponse -> msg)


{-| -}
type alias Taggers msg =
    List (Event msg)


{-| -}
type alias State msg =
    { tags : Taggers msg
    , pid : Maybe Process.Id
    }


{-| -}
type MySub msg
    = MySub Config_pro2 (Event msg)


{-| -}
init : Task Never (State msg)
init =
    Task.succeed
        { tags = []
        , pid = Nothing
        }


{-| -}
subMap : (a -> b) -> MySub a -> MySub b
subMap f (MySub config tagger) =
    case tagger of
        Touch g ->
            MySub config (Touch (f << g))


{-| -}
type alias Msg =
    { response : TouchResponse
    }


{-| -}
onEffects :
    Platform.Router msg Msg
    -> List (MySub msg)
    -> State msg
    -> Task Never (State msg)
onEffects router newSubs { tags, pid } =
    let
        config =
            List.head newSubs
                |> Maybe.map (\(MySub a _) -> a)
                |> Maybe.withDefault defaultConfig_pro2

        newtags =
            List.map (\(MySub _ a) -> a) newSubs
    in
    case pid of
        Nothing ->
            case newtags of
                [] ->
                    Task.succeed (State tags pid)

                _ ->
                    watch config (Platform.sendToSelf router) Msg
                        |> Process.spawn
                        |> Task.map (\pid_ -> State newtags (Just pid_))

        Just pid_ ->
            case newSubs of
                [] ->
                    Process.kill pid_
                        |> Task.map (always (State [] Nothing))

                _ ->
                    Task.succeed (State tags pid)


{-| -}
watch :
    Config_pro2
    -> (Msg -> Task Never ())
    -> (TouchResponse -> Msg)
    -> Task x Never
watch config =
    Elm.Kernel.ProOperate.spawnCommunication_pro2 config


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
                    Touch f ->
                        f msg.response
    in
    case state.tags of
        [] ->
            Task.succeed state

        tagger :: rest ->
            Task.sequence (List.map send (tagger :: rest))
                |> Task.map (always state)
