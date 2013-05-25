Formatter = require('./mysql-formatter')
Utils = require('./mysql-utils')

TableGateway = require('../../access/table-gateway')
sql = require('../../sql')

# TODO: Find a more elegant way to do this
# i'm not to sure if rewrite the prototype is the best way
TableGateway.prototype.doOutputQuery = (q, cb) ->
    return @db.bindOrCall(q, 'noData', cb) if !@schema.hasReadOnly()

    @db.bindOrCall(q, 'allRows', (err, res) =>
        return cb(err) if (err)

        # we always wants to return the result of last stmt. if we execute a stmt like:
        # INSERT () VALUES ()..; SELECT LAST_INSERT_ID(); we want the return of LAST_INSERT_ID()
        # not the INSERT, i can't see one case that we need to return all rows, or another
        # stmt that isnt the last, even if we need that we can implement in another place
        cb(null, res[res.length-1])
    )

module.exports = { Formatter, Utils }
