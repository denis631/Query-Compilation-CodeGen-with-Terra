C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
]]

require 'helper'
require 'datastore'
require 'operators.operator'
require 'operators.selection'
require 'operators.tablescan'
require 'operators.projection'

datastore = loadDatastore({
    -- getting not enough memory when loading tpcc_customer.tbl
    {'../data/tpcc_customer.tbl', Customer, "customers"}
})

query =
    Projection:new(
        Selection:new(
            TableScan:new("customers"),
            {
                { ["c_id"] = 3 },
                --{ ["c_first"] = "5Y3pDQPluD" }
            }
        ),
        {
            --{ ["c_id"] = findFieldTypeForNameInEntries("c_id", Customer.entries) },
            { ["c_first"] = findFieldTypeForNameInEntries("c_first", Customer.entries) }
        }
    )

query:prepare()
code = query:produce()

-- store query exec code as LLVM IR
terralib.saveobj("main", "llvmir", {main = code})

print(code)
code(datastore)
