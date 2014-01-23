{ A, _ } = h = require('../test-helper')
require('../live-db')

TableGateway = h.requireSrc('access/table-gateway')
ActiveRecord = h.requireSrc('access/active-record')

data = [
    {
        firstName: 'Anderson',
        lastName: 'Silva',
        dOB: new Date('1975-04-13'),
        country: 'Brazil',
        heightInCm: 188,
        reachInCm: 197,
        weightInLb: 185
    },
    {
        firstName: 'Wanderlei',
        lastName: 'Silva',
        dOB: new Date("1976-07-01"),
        country: 'Brazil',
        heightInCm: 180,
        reachInCm: 188,
        weightInLb: 204
    },
    {
        firstName: 'Jon',
        lastName: 'Jones',
        country: 'USA',
        heightInCm: 193,
        reachInCm: 215,
        weightInLb: 205 },
    {
        firstName: 'Cain',
        lastName: 'Velasquez',
        country: 'USA',
        heightInCm: 185,
        reachInCm: 196,
        weightInLb: 240
    }
]

shapes = [ [ data[0], data[1] ], [ data[2], data[3] ] ]

db = schema = tables = null

before () ->
    db = h.liveDb
    schema = db.schema
    tables = schema.tablesByMany

describe('Merge', () ->
    it('merges an array of data breaking in 2 shapes', (done) ->
        A.series([
            (cb) -> db.fighters.merge(data, cb)
            (cb) -> db.fighters.all(cb)
        ], (err, results) ->
            return done(err) if (err?)

            done()
        )
    )
)
