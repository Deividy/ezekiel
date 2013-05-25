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
            done()
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

fighterGateway = () -> new TableGateway(db, tables.fighters)
assertFighterOne = (done) -> (err, row) ->
    return done(err) if err
    row.lastName.should.be.eql(testData.fighters[0].lastName)
    done()

# SHOULD: move this into live-db.coffee, share. It's currently repeated.
assertCount = (cntExpected, done, fn) ->
    fn (err) ->
        return done(err) if err
        db.fighters.count (err, cnt) ->
            return done(err) if err
            cnt.should.eql(cntExpected)
            done()
            #h.cleanTestData(done)

assertIdOne = (rowAssert, done, fn) ->
    fn (err) ->
        return done(err) if err
        db.fighters.findOne fighters[0].id, (err, row) ->
            return done(err) if err
            rowAssert(row)
            done()
            #h.cleanTestData(done)

describe 'MySQL Table gateway', () ->
    it 'can be instantiated', () -> fighterGateway()

    it 'is accessible via database property', () ->
        db.fighters.should.be.instanceof(TableGateway)


    it 'can count rows', (done) ->
        db.fighters.count (err, cnt) ->
            return done(err) if err
            cnt.should.eql(0)
            done()

    it 'can insert rows', (done) ->
        initFighters(done)

    it 'can count rows', (done) ->
        db.fighters.count (err, cnt) ->
            return done(err) if err
            cnt.should.eql(cntFighters)
            done()

    it 'can postpone query execution', (done) ->
        g = fighterGateway()
        g.findOne(fighters[0].id).run(assertFighterOne(done))


    it 'allows query manipulation', (done) ->
        expected = _.filter(testData.fighters, (f) -> f.lastName == 'Silva').length
        db.fighters.count().where( { lastName: 'Silva' }).run (err, cnt) ->
            return done(err) if err
            cnt.should.eql(expected)
            done()


    it 'selects one row', (done) ->
        g = fighterGateway()
        g.findOne(fighters[0].id, assertFighterOne(done))


    it 'inserts one row', (done) ->
        f = testData.newFighter()
        cntExpected = cntFighters + 1
        db.fighters.insertOne f, (err, inserted) ->
            return done(err) if err
            inserted.id.should.be.a('number')
            assertCount cntFighters + 1, done, (cb) ->  cb()


    it 'updates one row by object predicate', (done) ->
        assert = (row) -> row.lastName.should.eql('Da Silva')
        op = (cb) -> db.fighters.updateOne({ lastName: 'Da Silva' }, { id: fighters[0].id }, cb)
        assertIdOne assert, done, op


    it 'updates one row by direct key value', (done) ->
        assert = (row) -> row.lastName.should.eql('Aldo')
        op = (cb) -> db.fighters.updateOne({ firstName: 'Jose', lastName: 'Aldo' }, fighters[0].id, cb)
        assertIdOne assert, done, op


    it 'updates one row via single object containing keys and values', (done) ->
        assert = (row) -> row.country.should.eql('Brasas')
        op = (cb) -> db.fighters.updateOne({ id: fighters[0].id, country: 'Brasas' }, cb)
        assertIdOne assert, done, op


    it 'refuses to updates one row via single object without key coverage', () ->
        db.fighters.updateOne { firstName: 'Anderson', country: 'Brasas' }, (err) ->
            err.should.match(/it must include values for at least one key/)

    it 'refuses to updateOne() without key coverage', () ->
        db.fighters.updateOne { lastName: 'Huxley' }, { firstName: 'Mauricio' }, (err) ->
            err.should.match(/please use updateMany/)


    it 'upserts one row', (done) ->
        f = testData.newFighter()
        cntFighters++
        db.fighters.upsertOne f, (err, inserted) ->
            return done(err) if err
            inserted.id.should.be.a('number')
            assertCount cntFighters, done, (cb) ->  cb()


    it 'deletes one row by object predicate', (done) ->
        cntFighters--
        assertCount cntFighters, done, (cb) -> db.fighters.deleteOne({ id: fighters[1].id }, cb)


    it 'deletes one row by direct key value', (done) ->
        cntFighters--
        assertCount cntFighters, done, (cb) -> db.fighters.deleteOne(fighters[2].id, cb)


    it 'selects many objects', (done) ->
        db.fighters.findMany { lastName: 'Silva' }, (err, objects) ->
            return done(err) if err
            for o in objects
                o.should.be.instanceof(ActiveRecord)
                o.lastName.should.eql('Silva')
            done()

    it 'deletes many rows', (done) ->
        cntFighters = 0
        assertCount cntFighters, done, (cb) -> db.fighters.deleteMany(id: ">": 0, cb)

    it 'merges an array of data', (done) ->
        db.fighters.merge(testData.fighters, (err) ->
            return done(err) if (err)
            done()
        )

    it 'merges an array of data', (done) ->
        async.series([
            (cb) -> db.fighters.deleteMany(id: ">": 0, cb)
            (cb) -> db.fighters.merge(testData.fighters, cb)
            (cb) -> db.fighters.all(cb)
        ], (err, results) ->
            return done(err) if err?
            fighters = results[2]
            fighters.length.should.eql(4)
            done()
        )
