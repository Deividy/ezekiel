_ = require('underscore')
F = require('functoids/src')
sql = require('../../sql')
{ SqlJoin, SqlFrom, SqlToken, SqlRawName, SqlFullName } = sql
MysqlFormatter = require('./mysql-formatter')
schemer = require('../../schema')

bulk = {
    # SHOULD: use merge storage engine

    # http://dev.mysql.com/doc/refman/5.6/en/merge-storage-engine.html
    merge: (merge) ->
        unless merge?.targetTable?
            throw new Error('you must provide a targetTable')

        rows = merge.rows
        F.demandNonEmptyArray(rows, 'merge.rows')

        target = @tokenizeTable(merge.targetTable)
        @table = target._schema
        unless @table?
            e = "merge: could not find schema for table #{target}."
            throw new Error(e)

        o = @table.classifyRowsForMerging(rows)
        @idx = 0
        size = o.cntRows + 16
        @lines = Array(size)

        tableColumns = _.reject(@table.columns, (c) -> c.extra.match(/auto_increment/))
        columns = _.pluck(tableColumns, 'property')

        @addLine "INSERT #{@delimit(@table.name)} (#{columns.join(', ')}) VALUES"
        values = [ ]
        for r in rows
            values.push @_insertValues(tableColumns, r)

        @addLine values.join(',')

        @addLine "ON DUPLICATE KEY UPDATE"
        @addLine ("#{c} = VALUES (#{c})" for c in columns).join(", ")

        return @lines.join('\n')

    addLine: (l) -> @lines[@idx++] = l

    _insertValues: (columns, row) ->
        values = [ ]
        for c, i in columns
            v = row[c.property]
            values.push if v? then @f(v) else 'NULL'

        return "(#{values.join(',')})"
}

_.extend(MysqlFormatter.prototype, bulk)
