_ = require('underscore')
async = require('async')
DbUtils = require('../db-utils')

# http://dev.mysql.com/doc/refman/5.5/en/information-schema.html

class MysqlUtils extends DbUtils
    constructor: (@db) ->
        @stmts = {
            dbNow: 'SELECT CURRENT_TIMESTAMP()'
            dbUtcNow: 'SELECT UTC_TIMESTAMP()'
            dbUtcOffset: "SELECT DATEDIFF(UTC_TIMESTAMP(), CURRENT_TIMESTAMP())"
        }

    getTables: (callback) ->
        query = "
        SELECT TABLE_NAME name FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE' #{@_addSqlDb('AND')}"

        @db.allRows(query, (err, rows) ->
            if err then callback(err, null)
            callback(null, _.sortBy(rows, (r) -> r.name))
        )

    getColumns: (callback) ->
        query = "
        SELECT
            TABLE_NAME tableName, COLUMN_NAME name, ORDINAL_POSITION position,
            (COLUMN_KEY = 'PRI' AND EXTRA LIKE '%auto_increment%') isIdentity, EXTRA extra,
            (PRIVILEGES NOT LIKE '%insert,update%') isComputed,
            IS_NULLABLE isNullable, DATA_TYPE dbDataType, CHARACTER_MAXIMUM_LENGTH maxLength
        FROM
            INFORMATION_SCHEMA.COLUMNS

        #{@_addSqlDb('WHERE')}

        ORDER BY
            TABLE_NAME, ORDINAL_POSITION"

        @db.allRows(query, (err, rows) =>
            callback(err, null) if err
            for r in rows
                r.isNullable = r.isNullable == 'YES'
                if r.maxLength == -1
                    r.maxLength = 'max'
            callback(null, rows)
        )

    getKeys: (callback) ->
        query = "
        SELECT #{@_addPkCase('CONSTRAINT_NAME', 'TABLE_NAME')} name,
        TABLE_NAME tableName, CONSTRAINT_TYPE type
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
            INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                USING(CONSTRAINT_NAME, TABLE_SCHEMA, TABLE_NAME)
        WHERE TABLE_NAME IS NOT NULL AND CONSTRAINT_TYPE <> 'FOREIGN KEY'
        #{@_addSqlDb('AND')}
        GROUP BY name, tableName, type" # We need GROUP BY to handle composite keys
        @db.allRows(query, callback)

    getForeignKeys: (callback) ->
        query = "
        SELECT
            FK.CONSTRAINT_NAME name,
            #{@_addPkCase('UNIQUE_CONSTRAINT_NAME', 'REFERENCED_TABLE_NAME')} parentKeyName,
            C.TABLE_NAME tableName, 'FOREIGN KEY' type
        FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS FK
        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS C ON FK.CONSTRAINT_NAME = C.CONSTRAINT_NAME
        #{@_addSqlDb('WHERE')}"
        @db.allRows(query, callback)

    getKeyColumns: (callback) ->
        query = "
        SELECT
        #{@_addPkCase('CONSTRAINT_NAME', 'TABLE_NAME')} constraintName,
        TABLE_NAME tableName, COLUMN_NAME columnName,
            ORDINAL_POSITION position
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        #{@_addSqlDb('WHERE')}
        ORDER BY constraintName, position"

        @db.allRows(query, callback)

    buildFullSchema: (callback) ->
        async.parallel({
            tables: (cb) => @getTables(cb)
            columns: (cb) => @getColumns(cb)
            keys: (cb) => @getKeys(cb)
            foreignKeys: (cb) => @getForeignKeys(cb)
            keyColumns: (cb) => @getKeyColumns(cb)
        }, callback)

    _addSqlDb: (before) -> "#{before} TABLE_SCHEMA = '#{@db.config.database}'"

    ###
        We can't give a name for a primary key in MySQL, it will be always called PRIMARY

        '(...)A PRIMARY KEY is a unique index where all key columns must be defined as NOT NULL.
        If they are not explicitly declared as NOT NULL, MySQL declares them so implicitly
        (and silently). A table can have only one PRIMARY KEY.
        The name of a PRIMARY KEY is always PRIMARY, which thus cannot be used as the name for
        any other kind of index. (...)'
        '(...)In MySQL, the name of a PRIMARY KEY is PRIMARY. For other indexes(...)'

        http://dev.mysql.com/doc/refman/5.1/en/create-table.html
    ###
    _addPkCase: (constraint, table) ->
        return "CASE
                    WHEN #{constraint} = 'PRIMARY' THEN CONCAT(#{table}, '.PRIMARY')
                    ELSE #{constraint}
                END"

module.exports = MysqlUtils
