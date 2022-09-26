module ProOperate.Error exposing
    ( Error
    , newError
    , keypadDisplayErrorFromInt
    , soundErrorFromInt
    )

{-| This Module is Error handling for ProOperate modules


## Overview

Provides a standard error handling interface across ProOperate.


# Types & Constructor

@docs Error
@docs newError


# Inner

@docs keypadDisplayErrorFromInt
@docs soundErrorFromInt

-}

import Dict
import Maybe


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
