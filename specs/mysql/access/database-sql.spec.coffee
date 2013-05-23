h = require('../../test-helper')
sql = h.requireSrc('sql')
ezekiel =  require('../../../src')
async = h.async
config = h.testConfig.databases.mysql

fs = require('fs')

db = null

before (done) ->
    config = {
        processSchema: h.cookSchema
        connection: config
    }
    ezekiel.connect(config, (err, d) ->
        throw new Error(err) if (err)
        db = d
        done()
    )


describe('Database using sql.* tokens', () ->
    it 'performs a SELECT query against Fighters', (done) ->
        s = sql.select('id', 'firstName').from('fighters')
        db.allRows(s, (err, rows) ->
            return done(err) if err
            rows.should.be.instanceOf(Array)
            done()
        )


    it('returns an error when oneRow finds no rows', (done) ->
        s = sql.select('id').from('fighters').where(id: -1)
        db.oneRow(s, (err, r) ->
            err.should.match(/No data returned for query SELECT \`Id\`/)
            done()
        )
    )
)
