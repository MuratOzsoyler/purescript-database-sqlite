module Database.SQLite3
  ( all
  , close
  , each
  , exec
  , get
  , module Internal
  , new
  , prepare
  , run
  , stmtAll
  , stmtBind
  , stmtEach
  , stmtFinalize
  , stmtGet
  , stmtReset
  , stmtRun
  ) where

import Prelude

import Control.Monad.Except (runExcept, throwError)
import Data.Either (Either(..))
import Data.Enum (fromEnum)
import Data.Maybe (Maybe)
import Data.Nullable (null)
import Database.SQLite3.Internal (Database, OpenMode(..), SqlQuery, SqlParam, SqlParams, RunResult, Statement, verbose) as Internal
import Database.SQLite3.Internal (Database, OpenMode, RunResult, SqlParam(..), SqlQuery, Statement, allImpl, closeImpl, eachImpl, execImpl, getImpl, newImpl, prepareImpl, runImpl, stmtAllImpl, stmtBindImpl, stmtEachImpl, stmtFinalizeImpl, stmtGetImpl, stmtResetImpl, stmtRunImpl)
import Effect (Effect)
import Effect.Aff (Aff, error)
import Effect.Aff.Compat (fromEffectFnAff, mkEffectFn1)
import Foreign (Foreign, readUndefined, renderForeignError, unsafeToForeign)
import Node.Path (FilePath)
import Prim.TypeError (class Warn, Text)

new :: FilePath -> OpenMode -> Aff Database
new path mode = fromEffectFnAff $ newImpl path $ fromEnum mode

close :: Database -> Aff Unit
close db = fromEffectFnAff $ closeImpl db

run :: Database -> SqlQuery -> Array SqlParam -> Aff RunResult
run db query params = fromEffectFnAff $ runImpl db query $ coerceParams params

coerceParams :: Array SqlParam -> Foreign
coerceParams = unsafeToForeign <<< map coerceParam

coerceParam :: SqlParam -> Foreign
coerceParam = case _ of
  SqlNull -> unsafeToForeign null
  SqlString s -> unsafeToForeign s
  SqlInt i -> unsafeToForeign i
  SqlNumber n -> unsafeToForeign n
  SqlBoolean b -> unsafeToForeign b

get :: Database -> SqlQuery -> Array SqlParam -> Aff (Maybe Foreign)
get db query params = do
  result <- fromEffectFnAff $ getImpl db query $ coerceParams params
  case runExcept $ readUndefined result of
    Left errs -> throwError $ error $ "Not an undefined or result (probably null):" <> show (renderForeignError <$> errs)
    Right r -> pure r

all :: Database -> SqlQuery -> Array SqlParam -> Aff (Array Foreign)
all db query params = fromEffectFnAff $ allImpl db query $ coerceParams params

each :: Database -> SqlQuery -> Array SqlParam -> (Foreign -> Effect Unit) -> Aff Int
each db query params rowFn = fromEffectFnAff $ eachImpl db query (coerceParams params) (mkEffectFn1 rowFn)

exec :: Database -> SqlQuery -> Aff Unit
exec db query = fromEffectFnAff $ execImpl db query

prepare :: Database -> SqlQuery -> Array SqlParam -> Aff Statement
prepare db query params = fromEffectFnAff $ prepareImpl db query $ coerceParams params

stmtFinalize :: Statement -> Aff Unit
stmtFinalize stmt = fromEffectFnAff $ stmtFinalizeImpl stmt

stmtReset :: Statement -> Aff Unit
stmtReset stmt = fromEffectFnAff $ stmtResetImpl stmt

stmtBind :: Statement -> Array SqlParam -> Aff Unit
stmtBind stmt params = fromEffectFnAff $ stmtBindImpl stmt $ coerceParams params

stmtGet :: Statement -> Array SqlParam -> Aff (Maybe Foreign)
stmtGet stmt params = do
  result <- fromEffectFnAff $ stmtGetImpl stmt $ coerceParams params
  case runExcept $ readUndefined result of
    Left errs -> throwError $ error $ "Not an undefined or result (probably null):" <> show (renderForeignError <$> errs)
    Right r -> pure r

stmtRun
  :: Warn (Text "`stmtRun` did never return result at the time of development. Use with care...")
  => Statement
  -> Array SqlParam
  -> Aff RunResult
stmtRun stmt params = fromEffectFnAff $ stmtRunImpl stmt $ coerceParams params

stmtAll :: Statement -> Array SqlParam -> Aff (Array Foreign)
stmtAll stmt params = fromEffectFnAff $ stmtAllImpl stmt $ coerceParams params

stmtEach :: Statement -> Array SqlParam -> (Foreign -> Effect Unit) -> Aff Int
stmtEach stmt params rowFn = fromEffectFnAff $ stmtEachImpl stmt (coerceParams params) (mkEffectFn1 rowFn)
