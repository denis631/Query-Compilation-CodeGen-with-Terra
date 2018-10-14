terralib.includepath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/;..;"

C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <time.h>
]]

require 'helper'
require 'datastore'
require 'operators.operator'
require 'operators.selection'
require 'operators.tablescan'
require 'operators.projection'
require 'operators.hash-join'
require 'operators.sort'

datastore = loadDatastore({
        {'../data/tpcc/tpcc_customer.tbl', "customers"},
        -- {'../data/tpcc/tpcc_order.tbl', "orders"},
        -- {"../data/tpcc/tpcc_orderline.tbl", "orderlines"},
        -- {"../data/tpcc/tpcc_item.tbl", "items"}
})

function benchmark(f, ...)
    local reps = 10
    local s = os.clock()
    for i=1,reps do
        f(...)
    end
    local average = (os.clock() - s) / reps
    print(string.format("average time %.6f seconds\n", average))
end

--[=====[Select query]]
select c_id, c_first, c_middle, c_last
from customer
where c_last = 'BARBARBAR';
--]=====]

--[=====[SELECT+JOIN]]
select o_id, ol_dist_info
from order, orderline
where o_id = ol_o_id
    and o_d_id = ol_d_id
    and o_w_id = ol_w_id
    and ol_number = 1
    and ol_o_id = 100;
--]=====]

--[=====[SELECT + 3 JOINS]]
select c_last, o_id, i_id, ol_dist_info
from customer, order, orderline, item
where c_id = o_c_id
    and c_d_id = o_d_id
    and c_w_id = o_w_id

    and o_id = ol_o_id
    and o_d_id = ol_d_id
    and o_w_id = ol_w_id

    and ol_number = 1
    and ol_o_id = 100

    and ol_i_id = i_id;
--]=====]

--[=====[SORT]]
select c_last, o_id
    from customer, order
    where c_id = o_c_id
    and c_d_id = o_d_id
    and c_w_id = o_w_id

    and c_id = 100

    sort by c_id, o_id
--]=====]

queries = {
        ["SORT"] = AlgebraTree.Projection(
            AlgebraTree.Sort(
                AlgebraTree.HashJoin(
                    AlgebraTree.Selection(
                        AlgebraTree.TableScan("customers"),
                        {
                            { ["c_id"] = 100 }
                        }
                    ),
                    AlgebraTree.TableScan("orders"),
                    {
                        { ["c_id"] = "o_c_id" },
                        { ["c_d_id"] = "o_d_id" },
                        { ["c_w_id"] = "o_w_id" }
                    }
                ),
                {
                    "c_id", "o_id"
                },
                AlgebraTree.Ascending
            ),
            {
                "c_last", "o_id"
            }
        ),

        ["SELECT+3JOINS"] =  AlgebraTree.Projection(
            AlgebraTree.HashJoin(
                AlgebraTree.HashJoin(
                    AlgebraTree.TableScan("customers"),
                    AlgebraTree.TableScan("orders"),
                    {
                        { ["c_id"] = "o_c_id" },
                        { ["c_d_id"] = "o_d_id" },
                        { ["c_w_id"] = "o_w_id" }
                    }
                ),
                AlgebraTree.HashJoin(
                    AlgebraTree.Selection(
                        AlgebraTree.TableScan("orderlines"),
                        {
                            { ["ol_number"] = 1 },
                            { ["ol_o_id"] = 100 }
                        }
                    ),
                    AlgebraTree.TableScan("items"),
                    {
                        { ["ol_i_id"] = "i_id" }
                    }
                ),
                {
                    { ["o_id"] = "ol_o_id" },
                    { ["o_d_id"] = "ol_d_id" },
                    { ["o_w_id"] = "ol_w_id" }
            }),
            {
                "c_last", "o_id", "i_id", "ol_dist_info"
            }
        ),

        ["SELECT+JOIN"] = AlgebraTree.Projection(
            AlgebraTree.HashJoin(
                AlgebraTree.Selection(
                    AlgebraTree.TableScan("orderlines"),
                    {
                        { ["ol_number"] = 1 },
                        { ["ol_o_id"] = 100 }
                    }
                ),
                AlgebraTree.TableScan("orders"),
                {
                    { ["ol_d_id"] = "o_d_id" },
                    { ["ol_w_id"] = "o_w_id" },
                    { ["ol_o_id"] = "o_id" }
                }
            ),
            {
                "o_id", "ol_dist_info"
            }
        ),

        ["SELECT"] = AlgebraTree.Projection(
            AlgebraTree.Selection(
                AlgebraTree.TableScan("customers"),
                {
                    { ["c_last"] = "BARBARBAR" }
                }
            ),
            {
                "c_id", "c_first", "c_middle", "c_last"
            }
        )
}

query = queries["SELECT"]

-- time = benchmark(function()
--     query:prepare()
--     local code = query:produce()
--     code:getpointer()
--     code(datastore)
-- end)

local x = os.clock()
query:prepare()
code = query:produce()
code:getpointer()
print(string.format("query code generated in %.6f seconds\n", os.clock() - x))

-- store query exec code as LLVM IR
terralib.saveobj("main.ll", "llvmir", {main = code})
--print(string.format("query code generated and stored as LLVM IR in %.6f seconds\n", os.clock() - x))

print(code)
code(datastore)
