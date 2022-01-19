module Test.Main
  ( MyRow
  , main
  ) where

import Prelude

import Control.Monad.Except (runExcept, throwError)
import Data.Either (Either(..))
import Data.List.NonEmpty as NEL
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse)
import Database.Sqlite3 as Sqlite3
import Database.Sqlite3.Internal (SqlParam(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Foreign (FT, Foreign, ForeignError(..), readInt, readString)
import Foreign.Index ((!))

type MyRow = { id :: Int, name :: String }

main :: Effect Unit
main = do
  Console.log "About to create database"
  launchAff_ do
    db <- Sqlite3.new ":memory:" Sqlite3.OpenReadWriteCreate
    liftEffect $ Console.log "Database created"

    result <- Sqlite3.run db "create table A (id integer not null primary key autoincrement, name varchar(30) not null)" []
    liftEffect $ Console.log $ "table created: " <> show result

    insertResult <- Sqlite3.run db "insert into A (name) values('Murat')" []
    liftEffect $ Console.log $ "item inserted: " <> show insertResult

    insertResult1 <- Sqlite3.run db "insert into A (name) values(?)" [ SqlString "Canan" ]
    liftEffect $ Console.log $ "2. item inserted: " <> show insertResult1

    queryResult <- Sqlite3.get db "select * from A" []
    case runExcept $ decodeMbRow queryResult of
      Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
      Right row -> liftEffect $ Console.log $ "first item fetched: " <> show row

    queryResult1 <- Sqlite3.all db "select * from A" []
    case runExcept $ decodeRows queryResult1 of
      Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
      Right rows -> liftEffect $ Console.log $ "items fetched: " <> show rows

    rowNum <- Sqlite3.each db "select * from A" []
      ( \row -> case runExcept $ decodeRow row of
          Left errors -> liftEffect $ Console.log $ "errors: " <> show errors
          Right r -> liftEffect $ Console.log $ "item fetched: " <> show r
      )
    liftEffect $ Console.log $ "num items fetched: " <> show rowNum

    Sqlite3.exec db
      """insert into A (name) values('Doğa');
insert into A (name) values('Gayruguppak')"""
    liftEffect $ Console.log "exec executed"

    queryResult2 <- Sqlite3.all db "select * from A" []
    case runExcept $ decodeRows queryResult2 of
      Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
      Right rows -> liftEffect $ Console.log $ "items fetched after exec: " <> show rows

    stmt <- Sqlite3.prepare db "select * from A" []
    liftEffect $ Console.log "no parameter statement prepared"

    stmt1 <- Sqlite3.prepare db "select * from A where id = ?" [ SqlInt 2 ]
    liftEffect $ Console.log "One bound parameter statement prepared"

    stmt2 <- Sqlite3.prepare db "select * from A where id = ?" []
    liftEffect $ Console.log "One unbound parameter statement prepared"

    -- stmt3 <- Sqlite3.prepare db "insert into A values(?)" []
    -- liftEffect $ Console.log "One unbound parameter insert statement prepared"

    Sqlite3.stmtReset stmt
    liftEffect $ Console.log "Statement reset"

    Sqlite3.stmtBind stmt2 [ SqlInt 4 ]
    liftEffect $ Console.log "Statement2 bound"

    stmt2Row <- Sqlite3.stmtGet stmt2 []
    case runExcept $ decodeMbRow stmt2Row of
      Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
      Right row -> liftEffect $ Console.log $ "item fetched wit stmt2: " <> show row

    stmt2Row1 <- Sqlite3.stmtGet stmt2 [ SqlInt 2 ]
    case runExcept $ decodeMbRow stmt2Row1 of
      Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
      Right row -> liftEffect $ Console.log $ "item re-fetched with stmt2: " <> show row

    -- liftEffect $ Console.log "about to run stmt3: "
    -- stmt3Result <- Sqlite3.stmtRun stmt3 [ SqlString "Dilek" ]
    -- liftEffect $ Console.log $ "item inserted via stmt3: " <> show stmt3Result

    stmtRows <- Sqlite3.stmtAll stmt []
    case runExcept $ decodeRows stmtRows of
      Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
      Right rows -> liftEffect $ Console.log $ "items fetched via stmt: " <> show rows

    stmtEachResult <- Sqlite3.stmtEach stmt []
      \row -> case runExcept $ decodeRow row of
        Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
        Right r -> liftEffect $ Console.log $ "item fetched via stmt#each: " <> show r
    liftEffect $ Console.log $ "Statement each fetched row: " <> show stmtEachResult

    liftEffect $ Console.log "About to finalize statements"
    Sqlite3.stmtFinalize stmt
    liftEffect $ Console.log "About to finalize stmt1"
    Sqlite3.stmtFinalize stmt1
    liftEffect $ Console.log "About to finalize stmt2"
    Sqlite3.stmtFinalize stmt2
    -- liftEffect $ Console.log "About to finalize stmt3"
    -- Sqlite3.stmtFinalize stmt3
    --   `catchError` (\e -> liftEffect $ Console.log $ "error finalizing stmt3" <> show e)
    liftEffect $ Console.log "Statements finalized"

    Sqlite3.close db
    liftEffect $ Console.log "Database closed"
    pure unit

decodeRows :: forall m. Monad m => Array Foreign -> FT m (Array MyRow)
decodeRows af = traverse decodeRow af

decodeRow :: forall m. Monad m => Foreign -> FT m MyRow
decodeRow f = do
  id <- f ! "id" >>= readInt
  name <- f ! "name" >>= readString
  pure { id, name }

decodeMbRow :: forall m. Monad m => Maybe Foreign -> FT m MyRow
decodeMbRow Nothing = throwError $ NEL.singleton $ ForeignError "Row does not exist"
decodeMbRow (Just f) = decodeRow f
