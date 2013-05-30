ezekiel
=======

Easy, high-performance SQL in Node.js

## SQL Formatter

Check lots of examples in specs/formatters/

    # include sql
    sql = require('ezekiel/src').sql

    # now we have to get our formatter
    { SqlFormatter, MysqlFormatter } = require('ezekiel/src').formatters

    s = sql.select(...)...
    s = sql.insert(...)...
    s = sql.update(...)
    s = sql.delete(...)
    s = sql.merge(...)

    # then we just have to format it:
    sqlFormatter = new SqlFormatter()
    console.log sqlFormatter.format(s)

## Connect and DB access
    # The processSchema config will build all our table gateways and active records
    # but don't be scary, it's not so ugly, check out a simple example

    # functoids is another beauty that comes with ezekiel
    # https://github.com/gduarte/functoids
    F = require('functoids/src')

    myProcessSchemaHandler = (schema) ->
        for table in schema.tables
           table.one = F.toLowerInitial(F.toSingular(table.name))
           table.many = F.toLowerInitial(F.toPlural(table.name))
           for column in table.columns
               column.property = F.toLowerInitial(column.name)

        return schema.finish()

    # Simple config
    config = {
        processSchema: myProcessSchemaHandler
        connection: {
            "engine": "mssql",
            "host": "localhost",
            "userName": "root",
            "password": "MyPassword",
            "database": "TestDb"
        }
    }
    ezekiel = require('ezekiel/src')
    ezekiel.connect(config, (err, db) ->
        # db, that's the man!
        # DB access commands
        db.execute(query, options, (err, result) ->)
        db.run(query, (err, result) ->)

        db.noData(query, (err) ->)

        db.scalar(query, (err, result) ->)
        db.tryScalar(query, (err, result) ->)

        db.oneRow(query, (err, result) ->)
        db.tryOneRow(query, (err, result) ->)

        db.allRows(query, (err, results) ->)
    )

## Access

The beauty.
Check lots of examples in specs/access/

### Table Gateway

    db.someTables.selectOne(whereObject, (err, result) ->)
    db.someTables.selectMany(whereObject, (err, results) ->)

    db.someTables.findOne(id, (err, result) ->)
    db.someTables.findMany(whereObject, (err, results) ->)

    db.someTables.insertOne(recordObject, (err, activeRecord) ->)
    db.someTables.upsertOne(recordObject, (err, activeRecord) ->)
    db.someTables.updateOne(updateObject, whereArgs..., (err, activeRecord) ->)

    db.someTables.deleteOne(id, (err) ->)
    db.someTables.deleteMany(whereObject, (err) ->)

    db.someTables.merge(objectOrArrayOfObjects, (err) ->)

    db.someTables.all((err, allActiveRecords) ->)

### ActiveRecord

    db.someTable(id, (err, activeRecord) ->
        activeRecord.someProperty = "Changing.."
        actvieRecord.persist((err) ->)
    )

#### Avaliable enginers
  - Microsoft SQL Server
  - MySQL