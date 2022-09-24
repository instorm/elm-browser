module Browser.ProOperate.Error exposing
    ( Error
    , new
    )

{-| Error


# Types

@docs Error


# Constructor

@docs new

-}


{-| -}
type alias Error =
    { name : String
    , message : String
    }


{-| -}
new : String -> String -> Error
new name message =
    { name = name
    , message = message
    }
