module ProOperate.Sound exposing (playSound)

{-| This module is sound interface for PitTouch Pro3.


## Overview

This module provides a standard way to play sound files on PitTouch.


# Play sound

@docs playSound

-}

import Elm.Kernel.ProOperate
import ProOperate.Error as Error exposing (Error)
import Task exposing (Task)


{-| -}
playSound : String -> Task Error Int
playSound filePath =
    Elm.Kernel.ProOperate.playSound filePath
        |> Task.mapError Error.soundErrorFromInt
