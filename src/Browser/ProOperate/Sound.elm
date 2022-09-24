module Browser.ProOperate.Sound exposing (Device, device)

{-| Sound API
-}

import ProOperate.Error as Error exposing (Error)
import Task exposing (Task)


{-| -}
type Device
    = Device ()


{-| -}
device : Task Error Device
device =
    Task.succeed <| Device ()


{-| -}
play : String -> Task Error Int
play filePath =
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
