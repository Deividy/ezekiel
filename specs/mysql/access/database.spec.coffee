h = require('../../test-helper')
ezekiel =  require('../../../src')
async = h.async
config = h.testConfig.databases.mysql

fs = require('fs')

database = null

before (done) ->
    config = {
        processSchema: h.cookSchema
        connection: config
    }
    ezekiel.connect(config, (err, db) ->
        throw new Error(err) if (err)
        database = db
        done()
    )


#tmpTable = """
#DECLARE @names TABLE(
#    FirstName VARCHAR(50),
#    LastName VARCHAR (50)
#)
#
#INSERT INTO @names VALUES ('Vincent','Vega')
#INSERT INTO @names VALUES  ('Jules','Winnfield')
#INSERT INTO @names VALUES  ('Mia','Wallace')
#INSERT INTO @names VALUES  ('Marsellus','Wallace')
#
#"""

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
            done(err) if err
            r.should.eql(42)
            done()
        )
    )

    it('tryScalar should behave as scalar with a unitary resultset', (done) ->
        query = "SELECT 42"
        database.tryScalar(query, (err, r) ->
            done(err) if err
            r.should.eql(42)
            done()
        )
    )

    it('should allow empty resultsets when using tryScalar', (done) ->
        query = "SELECT * FROM Fighters WHERE 1 = 0"
        database.tryScalar(query, (err, r) ->

            done(err) if err
            done("Resultset should be null") if r?
            done()
        )
    )

    #it('should return an error when tryScalar finds more than 1 row', (done) ->
    #    query = "#{tmpTable} SELECT FirstName FROM @names WHERE LastName = 'Wallace'"
    #    database.tryScalar(query, (err, r) ->
    #        err.should.match(/Too many rows returned/)
    #        done()
    #    )
    #)

    it('should get query rows', (done) ->
        stmt = "SELECT 1 AS test"
        database.allRows(stmt, (err, data) ->
            data.should.eql([{test:1}])
            done()
        )
    )

    #it('tryOneRow should behave as oneRow with a unitary resultset', (done) ->
    #    query = "#{tmpTable} SELECT FirstName, LastName FROM @names WHERE LastName = 'Winnfield'"
    #    database.tryOneRow(query, (err, r) ->
    #        done(err) if err
    #        r.should.eql({ FirstName: 'Jules', LastName: 'Winnfield' })
    #        done()
    #    )
    #)

    #it('should allow empty resultsets when using tryOneRow', (done) ->
    #    query = "#{tmpTable} SELECT FirstName, LastName FROM @names WHERE FirstName = 'Pumpkin'"
    #    database.tryOneRow(query, (err, r) ->
    #        done(err) if err
    #        done("Resultset should be null") if r?
    #        done()
    #    )
    #)

    #it('should return an error when tryOneRow finds more than 1 row', (done) ->
    #    query = "#{tmpTable} SELECT FirstName, LastName FROM @names WHERE LastName = 'Wallace'"
    #    database.tryOneRow(query, (err, r) ->
    #        err.should.match(/Too many rows returned/)
    #        done()
    #    )
    #)
)
