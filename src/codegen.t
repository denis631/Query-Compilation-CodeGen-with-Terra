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
    {'../data/tpcc_customer.tbl', "customers"}
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
            "c_first", "c_last"
        }
    )

local x = os.clock()
query:prepare()
code = query:produce()
print(string.format("query code generated in %.6f seconds\n", os.clock() - x))

-- store query exec code as LLVM IR
terralib.saveobj("main", "llvmir", {main = code})

print(code)
code(datastore)
