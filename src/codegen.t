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
    -- getting not enough memory when loading tpcc_customer.tbl
    {'../data/tpcc_customer.tbl', Customer, "customers"}
})
-- print(loadDatastore)
datastore = loadDatastore()

query = Projection:new(TableScan:new("customers"), {
                           { ["c_id"] = findFieldTypeForNameInEntries("c_id", Customer.entries) },
                           { ["c_first"] = findFieldTypeForNameInEntries("c_first", Customer.entries) }
})

query:prepare()
code = query:produce()

print(code)
code(datastore)
