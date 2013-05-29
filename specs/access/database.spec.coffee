h = require('../test-helper')
require('../live-db')
async = h.async

fs = require('fs')

database = null

before () ->
    database = h.liveDb

describe('Database', () ->
    it('should execute a simple query', (done) ->
        query = "SELECT 1"
        database.run(query, (data) ->
            done()
        )
    )

    it('should execute a simple query as scalar', (done) ->
        query = "SELECT 42"
        database.scalar(query, (err, r) ->
            return done(err) if err
            r.should.eql(42)
            done()
        )
    )

    it('tryScalar should behave as scalar with a unitary resultset', (done) ->
        query = "SELECT 42"
        database.tryScalar(query, (err, r) ->
            return done(err) if err
            r.should.eql(42)
            done()
        )
    )

    it('should allow empty resultsets when using tryScalar', (done) ->
        query = "SELECT * FROM Fighters WHERE 1 = 0"
        database.tryScalar(query, (err, r) ->
            return done(err) if err
            return done("Resultset should be null") if r?
            done()
        )
    )

    it('should return an error when tryScalar finds more than 1 row', (done) ->
        query = "SELECT FirstName FROM Fighters WHERE LastName = 'Silva'"
        database.tryScalar(query, (err, r) ->
            err.should.match(/Too many rows returned/)
            done()
        )
    )

    it('should get query rows', (done) ->
        stmt = "SELECT 1 AS test"
        database.allRows(stmt, (err, data) ->
            data.should.eql([{test:1}])
            done()
        )
    )

    it('tryOneRow should behave as oneRow with a unitary resultset', (done) ->
        query = "SELECT FirstName, LastName FROM Fighters
                                WHERE FirstName = 'Anderson' AND LastName = 'Silva'"
        database.tryOneRow(query, (err, r) ->
            return done(err) if err
            r.should.eql({ FirstName: 'Anderson', LastName: 'Silva' })
            done()
        )
    )

    it('should allow empty resultsets when using tryOneRow', (done) ->
        query = "SELECT FirstName, LastName FROM Fighters WHERE FirstName = 'Pumpkin'"
        database.tryOneRow(query, (err, r) ->
            return done(err) if err
            done("Resultset should be null") if r?
            done()
        )
    )

    it('should return an error when tryOneRow finds more than 1 row', (done) ->
        query = "SELECT FirstName, LastName FROM Fighters WHERE LastName = 'Silva'"
        database.tryOneRow(query, (err, r) ->
            err.should.match(/Too many rows returned/)
            done()
        )
    )
)
