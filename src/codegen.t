C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
]]

require 'datastore'
require 'operators.operator'
require 'operators.selection'
require 'operators.tablescan'
require 'operators.projection'

datastore = loadDatastore()

-- TODO: do an table in table, so that the order won't be random, because of the key hash position
local query = Projection:new(Selection:new(TableScan:new("users"), {}), { 
    { ["id"] = User.entries[1]["type"] },
    { ["name"] = User.entries[2]["type"] }
})
query:prepare()
code = query:produce()

code:printpretty()
code(datastore)