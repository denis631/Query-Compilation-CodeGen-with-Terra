if io.popen("uname","r"):read("*a") == "Darwin\n" then
    terralib.includepath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/;..;"
end

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
    {"../data/tpcc_5w/tpcc_customer.tbl", "customers"},
    {"../data/tpcc_5w/tpcc_order.tbl", "orders"},
    {"../data/tpcc_5w/tpcc_orderline.tbl", "orderlines"},
    {"../data/tpcc_5w/tpcc_item.tbl", "items"}
})

function benchmark(f, ...)
    local reps = 1
    local s = os.clock()
    for i=1,reps do
        f(...)
    end
    local average = (os.clock() - s) / reps
    print(string.format("time: %.6f seconds\n", average))
end

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
                AlgebraTree.HashJoin(
                    AlgebraTree.TableScan("customers"),
                    AlgebraTree.TableScan("orders"),
                    {
                        { ["c_id"] = "o_c_id" },
                        { ["c_d_id"] = "o_d_id" },
                        { ["c_w_id"] = "o_w_id" }
                    }
                ),
                AlgebraTree.Selection(
                    AlgebraTree.TableScan("orderlines"),
                    {
                        { ["ol_number"] = 1 },
                        { ["ol_o_id"] = 100 }
                    }
                ),
                {
                    { ["o_id"] = "ol_o_id" },
                    { ["o_d_id"] = "ol_d_id" },
                    { ["o_w_id"] = "ol_w_id" }
                }
            ),
            AlgebraTree.TableScan("items"),
            {
                { ["ol_i_id"] = "i_id" }
            }
        ),
        {
            "c_last", "o_id", "i_id", "ol_dist_info"
        }
    ),

    ["SELECT+JOIN"] = AlgebraTree.Projection(
        AlgebraTree.HashJoin(
            AlgebraTree.TableScan("customers"),
            AlgebraTree.HashJoin(
                AlgebraTree.TableScan("orders"),
                AlgebraTree.Selection(
                    AlgebraTree.TableScan("orderlines"),
                    {
                        { ["ol_number"] = 1 },
                        { ["ol_o_id"] = 100 }
                    }
                ),
                {
                    { ["o_d_id"] = "ol_d_id" },
                    { ["o_w_id"] = "ol_w_id" },
                    { ["o_id"] = "ol_o_id" }
                }
            ),
            {
                { ["c_id"] = "o_c_id"}
            }
        ),
        {
            "c_last", "o_id", "ol_dist_info"
        }
    ),

    ["SELECT"] = 
    AlgebraTree.Projection(
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

keys = {}
keys[1] = "SELECT"
keys[2] = "SELECT+JOIN"
keys[3] = "SELECT+3JOINS"
keys[4] = "SORT"

readInput = function()
    print("-------------------")
    print("Enter integer corresponding to index of the query you want to execute")
    print("1: Select")
    print("2: Select + Join")
    print("3: Select + 3 Joins")
    print("4: Sort")
    return tonumber(io.read())
end

idx = readInput()
while idx >= 1 and idx <= 4 do
    query = queries[keys[idx]]

    query:prepare()
    code = query:produce()

    benchmark(function()
        code:getpointer()
    end)

    -- store query exec code as LLVM IR
    -- terralib.saveobj("main.ll", "llvmir", {main = code})
    -- print(string.format("query code generated and stored as LLVM IR in %.6f seconds\n", os.clock() - x))

    print(code)

    benchmark(function()
        code(datastore)
    end)

    idx = readInput()
end