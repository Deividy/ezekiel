_ = require('underscore')
F = require('functoids/src')
sql = require('../sql')
{ SqlJoin, SqlFrom, SqlToken, SqlRawName, SqlFullName } = sql
SqlFormatter = require('./sql-formatter')
schemer = require('../schema')

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

        shapes = @table.shapesFromRows(merge.rows)
        @bulkMergeCount = 0

        sql = [ ]
        for shape in shapes
            sql.push(@sqlMergeFor(shape))

        console.log(sql.join('\n'))

        return sql.join('\n')

    sqlMergeFor: (rows) ->
        o = @table.classifyRowsForMerging(rows)
        @idx = 0
        size = o.cntRows + 16
        @lines = Array(size)
        @_addBulkInserts(o.inserts)

        for keyName, rows of o.updatesByKey
            @_addBulkMerges(keyName, rows)

        for keyName, rows of o.mergesByKey
            @_addBulkMerges(keyName, rows)

        @lines.length = @idx

        return @lines.join('\n')

    _addBulkInserts: (rows) ->
        return if _.isEmpty(rows)
        F.throw("not implemented")

    _addBulkUpdates: (keyName, rows) ->
        return if _.isEmpty(rows)
        F.throw("not implemented")

    _addBulkMerges: (keyName, rows) ->
        return if _.isEmpty(rows)
        key = @table.db.constraintsByName[keyName]

        # get first row to check columns, all the rows in data set will
        # have the same column
        shapeColumnsArray = _.keys(rows[0])
        shapeColumns = { }
        for c in shapeColumnsArray
            shapeColumns[c] = true

        columns = []

        for c in @table.columns
            if c.isReadOnly && !key.contains(c)
                continue

            columns.push(c)

        tempTableColumns = []

        for c in columns
            continue if !(shapeColumns[c.property]?)

            tempColumn = {
                name: c.name, property: c.property, isNullable: false,
                dbDataType: c.dbDataType, maxLength: c.maxLength
            }
            tempTableColumns.push(tempColumn)

        tempTableName = @nameTempTable("BulkMerge#{@bulkMergeCount++}")

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

    # insertColumns
    # updateColumns
    # insertValues
    # updateVlues

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
            "MERGE #{@delimit(target.name)} as target",
            "USING #{@delimit(source.name)} as source"
            "ON (#{onClauses})"
            "WHEN MATCHED THEN"
            "  UPDATE SET #{updates}"
            "WHEN NOT MATCHED THEN"
            "  INSERT (#{@doNameList(source.columns)})"
            "  VALUES (#{insertValues});"
        ]

        return a.join('\n')

    _firstInsertLine: (table) ->
        columns = _.pluck(table.columns, 'property').join(',')
        "INSERT #{@delimit(table.name)} (#{columns}) VALUES"

    _insertValues: (table, row) ->
        values = Array(table.columns.length)
        for c, i in table.columns
            v = row[c.property]
            values[i] = if v? then @f(v) else 'NULL'

        return "(#{values.join(',')}),"
}

_.extend(SqlFormatter.prototype, bulk)
