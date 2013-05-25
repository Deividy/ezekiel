Formatter = require('./mysql-formatter')
Utils = require('./mysql-utils')

TableGateway = require('../../access/table-gateway')
sql = require('../../sql')

TableGateway.prototype.doOutputQuery = (q, cb) ->
    return @db.bindOrCall(q, 'noData', cb) if !@schema.hasReadOnly()

    # we dont have anyway to output columns in an insert in mysql
    # what we can do is run another sql, like LAST_INSERT_ID()
    #
    # https://dev.mysql.com/doc/refman/5.5/en/insert.html
    # http://dev.mysql.com/doc/refman/5.0/en/information-functions.html#function_last-insert-id

    # TODO: Find a more elegant way to do this
    @db.bindOrCall(q, 'noData', (err) =>
        return cb(err) if (err)
        # TODO: transform it in a method, we dont want to put sql here NEVER
        # SHOULD: return the id as the PK name
        @db.bindOrCall(sql.select(["LAST_INSERT_ID()", 'id']), 'oneRow', cb)
    )

module.exports = { Formatter, Utils }
