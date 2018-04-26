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
    {'../data/tpcc/tpcc_customer.tbl', Customer, "customers"}
})

query =
    Projection:new(
        Selection:new(
            TableScan:new("customers"),
            {
                { ["c_id"] = 322 },
                { ["c_w_id"] = 1 },
                { ["c_d_id"] = 1 }
            }
        ),
        {
            { ["c_first"] = findFieldTypeForNameInEntries("c_first", Customer.entries) },
            { ["c_last"] = findFieldTypeForNameInEntries("c_last", Customer.entries) }
        }
    )

query:prepare()
code = query:produce()

-- store query exec code as LLVM IR
terralib.saveobj("main", "llvmir", {main = code})

print(code)
code(datastore)
