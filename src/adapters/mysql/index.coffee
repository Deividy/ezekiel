mysql = require('mysql')
_ = require('underscore')
poolModule = require('generic-pool')

class MySqlAdapter
    constructor: (config) ->
        @config = _.clone(config)
        @config.user = config.userName
        delete @config.userName
        @config.database ?= 'master'

        @pool = poolModule.Pool({
            name: 'mysql'
            create: (cb) => @_createConnection(@config, cb)
            destroy: (conn) -> conn.end()
        })

    _createConnection: (options, callback) ->
        conn = mysql.createConnection(@config)

        conn.connect((err) =>
            if (err)
                callback(err)
            else
                conn.on('error', options.onError ? @onConnectionError)
                # we dont have such event with node-mysql
                # https://github.com/felixge/node-mysql
                #conn.on('message', options.onMessage ? @onConnectionMessage)
                callback(null, conn)
        )

    execute: (options) ->
        fnErr = options.onError ? @onExecuteError

        @pool.acquire((err, conn) =>
            if(err)
                fnErr(err)
                return

            stmt = conn.query(options.stmt)

            doRow = options.onRow?
            doAllRows = options.onAllRows?
            rows = [] if doAllRows

            if (doRow || doAllRows)
                columns = [ ]
                stmt.on('fields', (fields) ->
                    columns = fields
                )
                stmt.on('result', (row) ->
                    rowShape = options.rowShape ? 'object'

                    # MUST: convert SQL bit to JS boolean
                    if (rowShape == 'array')
                        out = (row[col.name] for col in columns)
                    else
                        out = {}
                        for col in columns
                            v = row[col.name]
                            out[col.name] = v

                            if (rowShape == 'mixed')
                                out[col.name] = v

                    if doRow
                        options.onRow(out, options)

                    if doAllRows
                        rows.push(out)

                    return
                )

            stmt.on('end', () =>
                # MUST: ensure done is called even if there's an error, otherwise
                # we'll leak the connection
                if doAllRows
                    options.onAllRows(rows, options)

                if options.onDone?
                    options.onDone()

                @pool.release(conn)
            )

            stmt.on('error', fnErr)
        )


    onConnectionMessage: (msg) ->

    onConnectionError: (err) ->
        throw new Error(err)

    onExecuteError: (err) ->
        throw new Error(err)

    doesDatabaseExist: (name, callback) ->
        done = false;

        @execute(
            {
                rowShape: 'array'
                master: true
                stmt:"SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA
                            WHERE SCHEMA_NAME = '#{name}';"
                onRow: (row) ->
                    done = true
                    callback(row?[0]?)
                onDone: (row) ->
                    callback(false) if (!done)
            }
        )

    createDatabase: (name, callback) ->
        @execute(
            {
                master: true
                stmt: "CREATE DATABASE IF NOT EXISTS #{name};"
                onAllRows: (done) -> callback(true)
            }
        )

    dropDatabase: (name, callback) ->
        @execute(
            {
                master:true
                stmt:"DROP DATABASE IF EXISTS #{name};"
                onRow: (dn) ->
                    return callback(dn)
            }
        )


    _killProcess: (id, callback) ->
        engine.execute(
            {
                master:true
                stmt:"KILL #{id}"
                onDone: (done) -> callback(done)
            }
        )

module.exports = MySqlAdapter
