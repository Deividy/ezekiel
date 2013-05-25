_ = require('underscore')
sql = require('../../sql')
{ SqlJoin, SqlFrom, SqlToken, SqlRawName, SqlFullName } = sql
MysqlFormatter = require('./mysql-formatter')

schema = {
    createTempTable: (table) ->
        throw new Error('createTempTable: you must provide a table') unless table?

        lines = Array(table.columns.length + 2)
        i = 0

        lines[i++] = "CREATE TEMPORARY TABLE #{@delimit(table.name)} ("

        for c in table.columns
            lines[i++] = "  #{@defineColumn(c)},"

        pk = table.pk
        if pk?
            cluster = if pk.isClustered then 'CLUSTERED ' else ''
            key = "  PRIMARY KEY #{cluster}(#{@doNameList(pk.columns)})"
            lines[i++] = key
        else
            lines[i-1] = lines[i-1].slice(0, -1)

        lines[i++] = ");\n"
        return lines.join('\n')

    defineColumn: (c) ->
        throw new Error('defineColumn: you must provide a column') unless c?

        type = c.dbDataType
        if c.maxLength?
            type += "(#{c.maxLength})"

        nullable = if c.isNullable then "NULL" else "NOT NULL"

        extra = c.extra ? ""

        return "#{@delimit(c.name)} #{type} #{nullable} #{extra}"

    nameTempTable: (baseName) ->
        throw new Error('nameTempTable: you must provide a baseName') unless baseName?
        return baseName
}

_.extend(MysqlFormatter.prototype, schema)
