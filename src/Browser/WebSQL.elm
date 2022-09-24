module Browser.WebSQL exposing
    ( Database, Transaction, Param(..), Error(..)
    , openDatabase
    , transaction, executeSql, executeQuery
    )

{-| WebSQL Dtababase binding


# Types

@docs Database, Transaction, Param, Error


# Constructor

@docs openDatabase


# Operation

@docs transaction, executeSql, executeQuery

-}

import Elm.Kernel.WebSQL
import Json.Decode as Json exposing (Decoder)
import Task exposing (Task)


{-| Error
-}
type Error
    = SQLError String
    | DecodeError String


{-| Transaction
-}
type Transaction
    = Transaction


{-| Database
-}
type Database
    = Database


{-| -}
type Param
    = String String
    | Int Int


{-| -}
type alias ResultSet =
    String


{-| Open Database


# Examples

    openDatabase "documents" "1.0" "Offline document storage" (5 * 1024 * 1024)
        |> Task.andThen transaction
        |> Task.andThen (executeSql "CREATE TABLE docids (id, name)")

-}
openDatabase : String -> String -> String -> Int -> Task Error Database
openDatabase name version desc size =
    Elm.Kernel.WebSQL.openDatabase name version desc size
        |> Task.mapError SQLError


{-| Transaction
-}
transaction : Database -> Task Error Transaction
transaction db =
    Elm.Kernel.WebSQL.transaction db
        |> Task.mapError SQLError


{-| -}
decode : Json.Decoder a -> ResultSet -> Task Error a
decode decoder encoded =
    let
        resultToTask result =
            case result of
                Ok a ->
                    Task.succeed a

                Err x ->
                    Task.fail x
    in
    Json.decodeString decoder encoded
        |> Result.mapError (DecodeError << Json.errorToString)
        |> resultToTask


{-| Execute SQL
-}
executeSql :
    String
    -> List Param
    -> Transaction
    -> Task Error Transaction
executeSql sql param tx =
    Elm.Kernel.WebSQL.executeSql sql param tx
        |> Task.mapError SQLError
        |> Task.map (always tx)


{-| Execute Query
-}
executeQuery :
    Decoder a
    -> String
    -> List Param
    -> Transaction
    -> Task Error a
executeQuery decoder sql param tx =
    Elm.Kernel.WebSQL.executeSql sql param tx
        |> Task.mapError SQLError
        |> Task.andThen (decode decoder)
