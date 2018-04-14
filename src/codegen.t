C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
]]

require 'datastore'
require 'operators.operator'
require 'operators.tablescan'
require 'operators.projection'

loadDatastore = loadDatastore({
    {'../data/users.csv', User, "users"}
})
print(loadDatastore)

datastore = loadDatastore()

-- TODO: do an table in table, so that the order won't be random, because of the key hash position
local query = Projection:new(TableScan:new("users"), { 
    { ["id"] = User.entries[1]["type"] },
    { ["name"] = User.entries[2]["type"] }
})
query:prepare()
code = query:produce()

code:printpretty()
code(datastore)