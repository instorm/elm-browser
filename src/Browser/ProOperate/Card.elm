module Browser.ProOperate.Card exposing
    ( Felica, Mifare
    , FelicaService, MifareService
    , felica, sapica, suica
    )

{-| Card (Felica/Mifare)


# Card Types

@docs Felica, Mifare


# Card ConfigTypes

@docs FelicaService, MifareService


# Card Constructor

@docs felica, sapica, suica

-}

-- Type


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



-- CARD


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
