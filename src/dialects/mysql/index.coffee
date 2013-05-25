Formatter = require('./mysql-formatter')
Utils = require('./mysql-utils')

TableGateway = require('../../access/table-gateway')
sql = require('../../sql')

TableGateway.prototype.doOutputQuery = (q, cb) ->
    return @db.bindOrCall(q, 'noData', cb) if !@schema.hasReadOnly()

    # https://dev.mysql.com/doc/refman/5.5/en/insert.html
    # http://dev.mysql.com/doc/refman/5.0/en/information-functions.html#function_last-insert-id

    # TODO: Find a more elegant way to do this
    @db.bindOrCall(q, 'allRows', (err, res) =>
        return cb(err) if (err)
        cb(null, res[res.length-1])
    )

module.exports = { Formatter, Utils }
