SqlFormatter = require('../sql-formatter')
_ = require('underscore')

class MysqlFormatter extends SqlFormatter

    delimit: (s) -> "`#{s}`"

    joinNameParts: (names) -> _.map(names, (p) -> "`#{p}`").join(".")

    insert: (stmt) ->
        # we dont have anyway to output columns in an insert in mysql
        # what we can do is run another sql, like LAST_INSERT_ID(), but, it doesnt
        # works with oneRow and our actual ezekiel table gateway, so today we dont have a good
        # way to output the id from one sql
        #
        # https://dev.mysql.com/doc/refman/5.5/en/insert.html
        # http://dev.mysql.com/doc/refman/5.0/en/information-functions.html#function_last-insert-id
        names = [ ]
        values = [ ]
        @fillNamesAndValues(stmt.values, names, values)

        ret = ["INSERT #{@_doTargetTable(stmt.targetTable)} (#{names.join(', ')})"]
        ret.push "VALUES (#{values.join(', ')});"

        if stmt.outputColumns?
            @addOutputColumns(ret, stmt.targetTable, stmt.outputColums)
        else if (@.schema)
            ret.push "SELECT LAST_INSERT_ID() as id; "

        return ret.join(" ")

    upsert: (stmt) ->
        columns = [ ]
        values = [ ]
        @fillNamesAndValues(stmt.values, columns, values)

        # in mysql world we dont have a way to specific the key that we want to check
        # if is duplicate
        # we just have to say ON DUPLICATE KEY UPDATE, then it will update when any
        # of our table keys is duplicate, and we dont have to repeat the values
        # we just have to say VALUES(columnName) and it will take the VALUES() we're
        # passing to INSERT
        #
        # http://dev.mysql.com/doc/refman/5.0/en/insert-on-duplicate.html

        onColumns = (@doColumnAtom(c) for c in stmt.onColumns)
        updates = ("#{c} = VALUES (#{c})" for c in columns when !_.contains(onColumns, c))

        ret = [
            "INSERT #{@_doTargetTable(stmt.targetTable)} (#{columns.join(', ')})",
            "VALUES (#{values.join(', ')})"
            "ON DUPLICATE KEY UPDATE"
        ]
        ret.push updates.join(", ") + ";"

        if stmt.outputColumns?
            @addOutputColumns(ret, stmt.targetTable, stmt.outputColums)
        else
            ret.push "SELECT LAST_INSERT_ID() as id;"

        return ret.join('\n')

    addOutputColumns: (a, targetTable, outputColumns) ->
        F.demandGoodArray(a, 'a')
        return unless outputColumns?

        outputs = (@doOutputColumn(o, 'inserted') for o in [].concat(stmt.outputColumns))
        ret.push "SELECT #{outputs.join(', ')} FROM #{@_doTargetTable(targetTable)} "
        ret.push "WHERE LAST_INSERT_ID();"

module.exports = MysqlFormatter

require('./bulk-formatter')
require('./schema-formatter')