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
require 'operators.sort'

datastore = loadDatastore({
        {'../data/tpcc_customer.tbl', "customers"},
        {'../data/tpcc_order.tbl', "orders"},
        {"../data/tpcc_orderline.tbl", "orderlines"}
})

--[=====[ Query ]]
select c_first, c_last, o_all_local, ol_amount
from customer, order, orderline
where
o_w_id = c_w_id and
o_d_id = c_d_id and
o_c_id = c_id and
o_w_id = ol_w_id and
o_d_id = ol_d_id and
o_id = ol_o_id and
c_id = 322 and
c_w_id = 1 and
c_d_id = 1
--]=====]

query =
    AlgebraTree.Projection(
        AlgebraTree.Sort(
            AlgebraTree.Selection(
                AlgebraTree.TableScan("customers"),
                {
                    -- { ["c_id"] = 322 },
                    -- { ["c_w_id"] = 1 },
                    { ["c_d_id"] = 1 }
                }
            ),
            {
                "c_id"
            },
            AlgebraTree.Descending
        ),
        {
            "c_id", "c_first", "c_last"
        }
    )

print(query)

local x = os.clock()
query:prepare()
code = query:produce()
print(string.format("query code generated in %.6f seconds\n", os.clock() - x))

-- store query exec code as LLVM IR
terralib.saveobj("main", "llvmir", {main = code})
--print(string.format("query code generated and stored as LLVM IR in %.6f seconds\n", os.clock() - x))

print(code)
code(datastore)