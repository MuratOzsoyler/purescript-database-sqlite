module Database.SQLite3.Internal
  ( Database
  , OpenMode(..)
  , RunResult
  , SqlParam(..)
  , SqlParams
  , SqlQuery
  , Statement
  , allImpl
  , closeImpl
  , eachImpl
  , execImpl
  , getImpl
  , newImpl
  , prepareImpl
  , runImpl
  , stmtAllImpl
  , stmtBindImpl
  , stmtEachImpl
  , stmtFinalizeImpl
  , stmtGetImpl
  , stmtResetImpl
  , stmtRunImpl
  , verbose
  ) where

import Prelude

import Data.Bounded.Generic (genericBottom, genericTop)
import Data.Enum (class BoundedEnum, class Enum)
import Data.Enum.Generic (genericCardinality, genericPred, genericSucc)
import Data.Generic.Rep (class Generic)
import Data.Int.Bits (or)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Aff.Compat (EffectFn1, EffectFnAff)
import Foreign (Foreign)
import Node.Path (FilePath)

foreign import oPEN_READONLY :: Int
foreign import oPEN_READWRITE :: Int
foreign import oPEN_CREATE :: Int

data OpenMode = OpenReadOnly | OpenReadWrite | OpenCreate | OpenReadOnlyCreate | OpenReadWriteCreate

derive instance Eq OpenMode
derive instance Ord OpenMode
derive instance Generic OpenMode _
instance Show OpenMode where
  show = genericShow

instance Enum OpenMode where
  pred = genericPred
  succ = genericSucc

instance Bounded OpenMode where
  bottom = genericBottom
  top = genericTop

instance BoundedEnum OpenMode where
  cardinality = genericCardinality
  fromEnum OpenReadOnly = oPEN_READONLY
  fromEnum OpenReadWrite = oPEN_READWRITE
  fromEnum OpenCreate = oPEN_CREATE
  fromEnum OpenReadOnlyCreate = oPEN_READONLY `or` oPEN_CREATE
  fromEnum OpenReadWriteCreate = oPEN_READWRITE `or` oPEN_CREATE
  toEnum mode
    | mode == oPEN_READONLY = Just OpenReadOnly
    | mode == oPEN_READWRITE = Just OpenReadWrite
    | mode == oPEN_CREATE = Just OpenCreate
    | mode == oPEN_READONLY `or` oPEN_CREATE = Just OpenReadOnlyCreate
    | mode == oPEN_READONLY `or` oPEN_CREATE = Just OpenReadWriteCreate
  toEnum _ = Nothing

foreign import data Database :: Type

type SqlQuery = String
data SqlParam = SqlNull | SqlString String | SqlInt Int | SqlNumber Number | SqlBoolean Boolean

derive instance Eq SqlParam
derive instance Ord SqlParam
derive instance Generic SqlParam _
instance Show SqlParam where
  show = genericShow

type SqlParams = Array SqlParam

foreign import newImpl :: FilePath -> Int -> EffectFnAff Database

foreign import closeImpl :: Database -> EffectFnAff Unit

type RunResult = { lastID :: Int, changes :: Int }

foreign import runImpl :: Database -> SqlQuery -> Foreign -> EffectFnAff RunResult

foreign import getImpl :: Database -> SqlQuery -> Foreign -> EffectFnAff Foreign

foreign import allImpl :: Database -> SqlQuery -> Foreign -> EffectFnAff (Array Foreign)

foreign import eachImpl :: Database -> SqlQuery -> Foreign -> EffectFn1 Foreign Unit -> EffectFnAff Int

foreign import execImpl :: Database -> SqlQuery -> EffectFnAff Unit

foreign import data Statement :: Type

foreign import prepareImpl :: Database -> SqlQuery -> Foreign -> EffectFnAff Statement

foreign import stmtFinalizeImpl :: Statement -> EffectFnAff Unit

foreign import stmtResetImpl :: Statement -> EffectFnAff Unit

foreign import stmtBindImpl :: Statement -> Foreign -> EffectFnAff Unit

foreign import stmtGetImpl :: Statement -> Foreign -> EffectFnAff Foreign

foreign import stmtRunImpl :: Statement -> Foreign -> EffectFnAff RunResult

foreign import stmtAllImpl :: Statement -> Foreign -> EffectFnAff (Array Foreign)

foreign import stmtEachImpl :: Statement -> Foreign -> EffectFn1 Foreign Unit -> EffectFnAff Int

foreign import verbose :: Effect Unit
