ezekiel = require('../src')
sql = ezekiel.sql
{ SqlFormatter, MysqlFormatter } = ezekiel.formatters

sqlFormatter = new SqlFormatter()
mysqlFormatter = new MysqlFormatter()

select = sql.select(
        ['warriors.name', 'warrior']
        'details.details'
        ['weapons.name', 'weapon']
        ['enemy.name', 'enemy']
        ['enemyWeapons.name', 'enemyWeapon']
    ).from('warriors')
    .join('details', { 'details.warriorId': sql.name('warrios.Id') })
    .leftJoin('weapons', { 'weapons.warriorId': sql.name('warriors.id') })
    .rightJoin('battles', { 'batles.warriorId': sql.name('warriors.id') }) #its not a realistic!
    .join('enemies', { 'battles.enemyId': sql.name('enemies.id') }, 'INNER')
    .fullJoin('enemyWeapons', { 'enemyWeapons.enemyId': sql.name('enemies.id') })
    .where({ "warriors.age": { ">": 18, "<": 35 } }).or({ "warriors.type": { "!=": 5 } })
    .groupBy('warrior', 'enemy')
    .orderBy('warrior', 'enemy')

sqlSelect = [
    "SELECT [warriors].[name] as [warrior],"
    "[details].[details], [weapons].[name] as [weapon],"
    "[enemy].[name] as [enemy], [enemyWeapons].[name] as [enemyWeapon]"
    "FROM [warriors]"
    "INNER JOIN [details] ON [details].[warriorId] = [warrios].[Id] "
    "LEFT JOIN [weapons] ON [weapons].[warriorId] = [warriors].[id] "
    "RIGHT JOIN [battles] ON [batles].[warriorId] = [warriors].[id] "
    "INNER JOIN [enemies] ON [battles].[enemyId] = [enemies].[id] "
    "FULL OUTER JOIN [enemyWeapons] ON [enemyWeapons].[enemyId] = [enemies].[id]"
    "WHERE (([warriors].[age] > 18 AND [warriors].[age] < 35) OR [warriors].[type] <> 5)"
    "GROUP BY [warrior], [enemy] ORDER BY [warrior] ASC, [enemy] ASC"
].join(' ')

mysqlSelect = [
    "SELECT `warriors`.`name` as `warrior`,"
    "`details`.`details`, `weapons`.`name` as `weapon`,"
    "`enemy`.`name` as `enemy`, `enemyWeapons`.`name` as `enemyWeapon`"
    "FROM `warriors`"
    "INNER JOIN `details` ON `details`.`warriorId` = `warrios`.`Id` "
    "LEFT JOIN `weapons` ON `weapons`.`warriorId` = `warriors`.`id` "
    "RIGHT JOIN `battles` ON `batles`.`warriorId` = `warriors`.`id` "
    "INNER JOIN `enemies` ON `battles`.`enemyId` = `enemies`.`id` "
    "FULL OUTER JOIN `enemyWeapons` ON `enemyWeapons`.`enemyId` = `enemies`.`id`"
    "WHERE ((`warriors`.`age` > 18 AND `warriors`.`age` < 35) OR `warriors`.`type` <> 5)"
    "GROUP BY `warrior`, `enemy` ORDER BY `warrior` ASC, `enemy` ASC"
].join(' ')

insert = sql.insert("warriors", {
    name: 'Da Man'
    age: 23
})
sqlInsert = "INSERT [warriors] ([name], [age]) VALUES ('Da Man', 23)"
# Yeah, i also dont think its cool/right
mysqlInsert = "INSERT `warriors`\n(`name`, `age`) VALUES ('Da Man', 23);\n"
mysqlInsert += "SELECT LAST_INSERT_ID() as id;"

describe('Quick start', () ->

    it('SqlFormatter: should format a sql select', () ->
        sqlFormatter.format(select).should.be.eql(sqlSelect)
    )

    it('SqlFormatter: should format a sql insert', () ->
        sqlFormatter.format(insert).should.be.eql(sqlInsert)
    )

    it('MysqlFormatter: should format a sql select', () ->
        mysqlFormatter.format(select).should.be.eql(mysqlSelect)
    )

    it('MysqlFormatter: should format a sql insert', () ->
        mysqlFormatter.format(insert).should.be.eql(mysqlInsert)
    )
)