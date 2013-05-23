SqlFormatter = require('../sql-formatter')
_ = require('underscore')

class MysqlFormatter extends SqlFormatter

    delimit: (s) -> "`#{s}`"

    joinNameParts: (names) -> _.map(names, (p) -> "`#{p}`").join(".")

    insert: (stmt) ->
        columns = [ ]
        values = [ ]
        @fillNamesAndValues(stmt.values, columns, values)

        # we dont have anyway to output columns in an insert in mysql
        # what we can do is run another sql, like LAST_INSERT_ID(), but, it doesnt
        # works with oneRow and our actual ezekiel table gateway, so today we dont have a good
        # way to output the id from one sql
        #
        # https://dev.mysql.com/doc/refman/5.5/en/insert.html
        # http://dev.mysql.com/doc/refman/5.0/en/information-functions.html#function_last-insert-id

        return "INSERT #{@_doTargetTable(stmt.targetTable)} (#{columns.join(', ')})
                                                        VALUES (#{values.join(', ')})"

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

        ret = [
            "INSERT #{@_doTargetTable(stmt.targetTable)} (#{columns.join(', ')})",
            "VALUES (#{values.join(', ')})"
            "ON DUPLICATE KEY UPDATE"
        ]
        ret.push ("#{c} = VALUES (#{c})" for c in columns).join(", ")
        return ret.join(' ')

module.exports = MysqlFormatter