{ A, _ } = h = require('../test-helper')
require('../live-db')

TableGateway = h.requireSrc('access/table-gateway')
ActiveRecord = h.requireSrc('access/active-record')

testData = h.testData
db = schema = tables = null

before () ->
    db = h.liveDb
    schema = db.schema
    tables = schema.tablesByMany

describe('Merge', () ->
    it('merges an array of data', (done) ->
        A.series([
            (cb) -> db.fighters.deleteMany(id: ">": 0, cb)
            (cb) -> db.fighters.merge(testData.fighters, cb)
            (cb) -> db.fighters.all(cb)
        ], (err, results) ->
            return done(err) if err?
            fighters = results[2]
            fighters.length.should.eql(4)
            done()
        )
    )
)
