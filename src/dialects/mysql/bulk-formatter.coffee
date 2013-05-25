_ = require('underscore')
F = require('functoids/src')
sql = require('../../sql')
{ SqlJoin, SqlFrom, SqlToken, SqlRawName, SqlFullName } = sql
MysqlFormatter = require('./mysql-formatter')
schemer = require('../../schema')

bulk = {
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
        @_addBulkInserts(o.inserts)

        for keyName, rows of o.updatesByKey
            @_addBulkUpdates(keyName, rows)

        for keyName, rows of o.mergesByKey
            @_addBulkMerges(keyName, rows)

        @lines.length = @idx
        console.log @lines.join('\n')

        return @lines.join('\n')

    _addBulkInserts: (rows) ->
        return if _.isEmpty(rows)
        F.throw("not implemented")

    _addBulkUpdates: (keyName, rows) ->
        return if _.isEmpty(rows)
        F.throw("not implemented")

    _addBulkMerges: (keyName, rows) ->
        return if _.isEmpty(rows)
        key = @table.db.constraintsByName[@table.name + ".PRIMARY"]

        cntValuesByColumn = {}
        columns = []

        for c in @table.columns
            if c.isReadOnly && !key.contains(c)
                continue

            columns.push(c)
            cntValuesByColumn[c.property] = 0

        for r in rows
            for c in columns
                cntValuesByColumn[c.property]++ if c.property of r

        tempTableColumns = []
        for c in columns
            cntValues = cntValuesByColumn[c.property]
            #continue if cntValues == 0

            nullable = cntValues < rows.length
            tempColumn = {
                name: c.name, property: c.property, isNullable: nullable,
                dbDataType: c.dbDataType, maxLength: c.maxLength
            }
            tempTableColumns.push(tempColumn)

        tempTableName = @nameTempTable('BulkMerge')

        tempTable = schemer.table(name: tempTableName).addColumns(tempTableColumns)
        tempTable.primaryKey(columns: _.pluck(key.columns, 'name'), isClustered: true)

        @addLine(@createTempTable(tempTable))
        @addLine(@_firstInsertLine(tempTable))

        for r in rows
           @addLine(@_insertValues(tempTable, r))

        n = @idx-1
        @lines[n] = @lines[n].slice(0, -1) + ';\n'

        @addLine(@doTableMerge(@table, tempTable))
        @addLine("DROP TABLE " + @delimit(tempTableName) + ";")

    addLine: (l) -> @lines[@idx++] = l

    # http://dev.mysql.com/doc/refman/5.6/en/merge-storage-engine.html
    doTableMerge: (target, source) ->
        t = (c) => "target." + @delimit(c.name)
        s = (c) => "source." + @delimit(c.name)
        eq = (c) =>
            lhs = t(c)
            rhs = if c.isNullable then "COALESCE(#{s(c)}, #{t(c)})" else s(c)
            return lhs + " = " + rhs

        onClauses = (eq(c) for c in source.pk.columns).join(" AND ")
        updates = (eq(c) for c in source.columns when !c.isPartOfKey).join(", ")
        insertValues = (s(c) for c in source.columns).join(", ")

        a = [
            "ALTER TABLE #{@delimit(target.name)}"
            "UNION=(#{@delimit(target.name)}, #{@delimit(source.name)});"
        ]
        return a.join('\n')

    _firstInsertLine: (table) ->
        columns = _.pluck(table.columns, 'property')[1..].join(',')
        return "INSERT #{@delimit(table.name)} (#{columns}) VALUES"

    _insertValues: (table, row) ->
        values = Array(table.columns.length-1)
        for c, i in table.columns[1..]
            v = row[c.property]
            values[i] = if v? then @f(v) else 'NULL'

        return "(#{values.join(',')}),"
}

_.extend(MysqlFormatter.prototype, bulk)
