# PureScript SQLite3 Bindings

Yet another SqLite3 bindings to be future (almost) complete and to support latest compiler version.

## Installation

Enter the following command to install:

    spago install purescript-database-sqlite

Don't forget to build afterwards.

## Usage

The library is created to be used with a qualified import. Import it as the following:

```purescript
import Database.Sqlite3 as Sqlite3
```

`Database` object must be created first using `":memory:"` designator or giving a `FilePath`. You can use various `Database` related functions to query or modify the database.    

`Statement` object is created using `prepare` `Database` function. You can use this object on functions prefixed with `stmt` to query or modify the database.

For further information refer to `node-sqlite3` [documentation](https://github.com/mapbox/node-sqlite3/wiki). 

```purescript
main :: Effect Unit
main = launchAff_ do
    db <- Sqlite3.new ":memory:" Sqlite3.OpenReadWriteCreate
    liftEffect $ Console.log "Database created"

    result <- Sqlite3.run db "create table A (id integer not null primary key autoincrement, name varchar(30) not null)" []
    liftEffect $ Console.log $ "table created: " <> show result

    insertResult <- Sqlite3.run db "insert into A (name) values('Murat')" []
    liftEffect $ Console.log $ "item inserted: " <> show insertResult
    -- item inserted: {changes: 1, lastID: 1}

    queryResult <- Sqlite3.get db "select * from A" []
    case runExcept $ decodeMbRow queryResult of
        Left errors -> liftEffect $ Console.log $ "errors: " <> show errors -- map renderForeignError errors
        Right row -> liftEffect $ Console.log $ "first item fetched: " <> show row
    -- first item fetched: {id: 1, name: "Murat"}

decodeMbRow :: forall m. Monad m => Maybe Foreign -> FT m MyRow
decodeMbRow Nothing = throwError $ NEL.singleton $ ForeignError "Row does not exist"
decodeMbRow (Just f) = decodeRow f

decodeRow :: forall m. Monad m => Foreign -> FT m MyRow
decodeRow f = do
  id <- f ! "id" >>= readInt
  name <- f ! "name" >>= readString
  pure { id, name }
```

## Caveats

Given the library is in its first versions and is not used extensively and author's inexperience in writing PuseScript FFI (or PureScript to be honest), there may be bugs or misunderstandings in both `node-sqlite3` and PureScript side. So use with care. 

`stmtRun` did not return any result at the time of development. I think this is a `node-sqlite3` bug but does not confirm it. The function can work or don't work regarding your `node-sqlite3` version so be aware. `Database` `run` function works anyways.

## Alternative Libraries

[`purescript-node-sqite3`](https://pursuit.purescript.org/packages/purescript-sqlite/3.0.0) supports latest compiler versions. But only a small part of the API is implemented. As it is being used for such a long time this library is your first choice to go.

[`purescript-sqlite`](https://pursuit.purescript.org/packages/purescript-node-sqlite3/6.0.0) is future rich as it is implemented most of the API. Also it contains some monad transformers to make usage more convenient. But unfortunately it is not maintained any more and does not support current version of compiler.

## Acknowlegments

I thank to both Justin Woo and Risto Stevcev for their works on `node-sqlite3` bindings. I inspired from their work and even copied some of them.

I also want to thank to PureScript maintainers as they constantly develop and maintain such an ecosystem. A huge undertaking in my opinion.