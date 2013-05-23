mysql = require('mysql')
h = require('../../test-helper')
async = require('async')
ezekiel =  require('../../../src')
_ = require('underscore')

config = h.testConfig.databases.mysql
adapter = db = tables = schema = fighters = null

TableGateway = h.requireSrc('access/table-gateway')
ActiveRecord = h.requireSrc('access/active-record')

testData = h.testData
cntFighters = h.testData.cntFighters

before (done) ->
    config = {
        processSchema: h.cookSchema
        connection: config
    }
    ezekiel.connect(config, (err, d) ->
        throw new Error(err) if (err)
        db = d
        schema = db.schema
        tables = schema.tablesByMany
        done()
    )

fighterGateway = () -> new TableGateway(db, tables.fighters)
assertFigherOne = (done) -> (err, row) ->
    return done(err) if err
    row.id.should.eql(1)
    done()

assertGetTableGateway = (many) ->
    gw = db.getTableGateway(many)
    assertGateway(gw, many)

assertGatewayProperty = (many) ->
    gw = db[many]
    assertGateway(gw, many)

assertGateway = (gw, many) ->
    gw.should.be.an.instanceof(TableGateway)
    gw.db.should.eql(db)
    gw.schema.many.should.eql(many)
    gw.schema.should.eql(tables[many])

assertNewObject = (one) ->
    o = db[one]()
    o.should.be.an.instanceof(ActiveRecord)

describe 'Database with loaded schema', () ->
    it 'Returns Table Gateways via getTableGateway()', () ->
        assertGetTableGateway(many) for many of tables

    it 'Exposes gateways via property', () ->
        assertGatewayProperty(many) for many of tables

    it 'Supports creation of a new context', () ->
        c = { loginId: 100 }
        newDb = db.newContext(c)
        newDb.context.should.eql(c)
        for k, v of db
            if k in ['context', 'tableGateways']
                v.should.not.eql(newDb[k])
            else
                v.should.eql(newDb[k])

    it 'Exposes active records via entity()', () ->
        assertNewObject(one) for one of schema.tablesByOne
