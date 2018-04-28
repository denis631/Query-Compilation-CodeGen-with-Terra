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
require 'operators.inner-join'

datastore = loadDatastore({
        {'../data/tpcc/tpcc_customer.tbl', "customers"},
        {'../data/tpcc/tpcc_order.tbl', "orders"}
})


-- select c_first, c_last, o_all_local
-- from customer, order
-- where o_w_id = c_w_id
-- and o_d_id = c_d_id
-- and o_c_id = c_id
-- and c_id = 322
-- and c_w_id = 1
-- and c_d_id = 1
query =
    Projection:new(
        InnerJoin:new(
            Selection:new(
                TableScan:new("customers"),
                {
                    { ["c_id"] = 322 },
                    { ["c_w_id"] = 1 },
                    { ["c_d_id"] = 1 }
                }
            ),
            TableScan:new("orders"),
            {
                { ["o_w_id"] = "c_w_id" },
                { ["o_d_id"] = "c_d_id" },
                { ["o_c_id"] = "c_id"   }
            }
        ),
        {
            "c_first", "c_last", "o_all_local"
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
