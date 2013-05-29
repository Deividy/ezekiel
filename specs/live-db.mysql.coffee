fs = require('fs')
h = require('./test-helper')
DbSchema = h.requireSrc('schema/db-schema')
SqlFormatter = h.requireSrc('dialects/mysql/mysql-formatter')
sql = h.requireSrc('sql')
ezekiel = h.requireSrc()

data = require('./data/test-data.coffee')

cleanTestData = (cb) ->
    q = fs.readFileSync("./data/mysql.sql").toString() + " \n "

    for f in data.fighters
        formatter = new SqlFormatter(h.getCookedSchema())
        insert = sql.insert('fighters', f)
        q += (formatter.format(insert))

    h.liveDb.noData(q, cb)

before (done) ->
    h.cleanTestData = cleanTestData

    config = {
        processSchema: h.cookSchema
        connection: h.defaultDbConfig
    }

    ezekiel.connect config, (err, freshDb) ->
        return done(err) if err?
        h.liveDb = h.db = freshDb
        cleanTestData(done)

describe 'Live DB test helper', () ->
    it 'Cleans test data', () ->