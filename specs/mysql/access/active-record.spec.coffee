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
        db.run("DELETE FROM Fighters", (err) ->
            throw new Error(err) if (err)
            initFighters(done)
        )
    )

initFighters = (done) ->
    addFighter = (fighter) ->
        return (ret, cb) =>
            cb = ret if (!cb)
            db.fighters.insertOne(fighter, cb)

    tasks = (addFighter(fighter) for fighter in testData.fighters)

    async.waterfall(tasks, (err) ->
        throw new Error(err) if (err)
        db.fighters.all((err, res) ->
            throw new Error(err) if (err)
            fighters = res
            done()
        )

    )

# SHOULD: move this into live-db.coffee, share. It's currently repeated.
cntFighters = testData.cntFighters
assertCount = (cntExpected, done, fn = (cb) -> cb()) ->
    fn (err) ->
        return done(err) if err
        db.fighters.count (err, cnt) ->
            return done(err) if err
            cnt.should.eql(cntExpected)
            done()
            #h.cleanTestData(done)

assertIdOne = (rowAssert, done) ->
    fn (err) ->
        return done(err) if err
        db.fighters.findOne 1, (err, row) ->
            return done(err) if err
            rowAssert(row)
            done()
            #h.cleanTestData(done)

describe 'ActiveRecord', () ->
    it 'can be instantiated via TableGateway.newObject()', ->
        for t in schema.tables
            o = db.getTableGateway(t.many).newObject()
            o.should.be.an.instanceof(ActiveRecord)
            o.toString().should.include(t.one)

    it 'can be instantiated via db[table.one]()', ->
        for t in schema.tables
            o = db[t.one]()
            o.should.be.an.instanceof(ActiveRecord)
            o.toString().should.include(t.one)

    it 'can be loaded from DB via db[table.one](id)', (done) ->
        db.fighter fighters[0].id, (err, row) ->
            return done(err) if err
            row.id.should.eql(fighters[0].id)
            done()

    it 'can insert a row', (done) ->
        o = db.fighter(testData.newFighter())
        o._stateName().should.eql('new')

        o.persist (err) ->
            return done(err) if err
            o._stateName().should.eql('persisted')
            o.id.should.be.a('number')
            cntFighters++
            assertCount cntFighters, done

    it 'can update a row', (done) ->
        db.fighter fighters[0].id, (err, o) ->
            return done(err) if err
            o._stateName().should.eql('persisted')
            o.firstName = 'The Greatest' # No wind or waterfall could stall me
            o._isDirty().should.be.true

            o.persist (err) ->
                return done(err) if err
                o._isDirty().should.be.false
                o._stateName().should.eql('persisted')
                _.isEmpty(o._changed).should.be.true
                o.firstName.should.eql('The Greatest')
                done()

    it 'can delete a row', (done) ->
        db.fighter fighters[3].id, (err, o) ->
            return done(err) if err
            o.id.should.eql(fighters[3].id)
            o._stateName().should.eql('persisted')

            o.destroy (err) ->
                return done(err) if err
                o._stateName().should.eql('destroyed')
                cntFighters--
                assertCount cntFighters, done
