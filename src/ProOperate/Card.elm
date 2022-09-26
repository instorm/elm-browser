module ProOperate.Card exposing
    ( Felica, FelicaService
    , Mifare, MifareService
    , felicaCard
    , sapicaCard
    , suicaCard
    )

{-| This Module is an Interface for Cards supported by PitTouch.


# Card format & structure

@docs Felica, FelicaService
@docs Mifare, MifareService


# Instance of Card

@docs felicaCard
@docs sapicaCard
@docs suicaCard

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
