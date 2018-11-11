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
require 'queries'

datastore = loadDatastore({
    {"../data/tpcc_5w/tpcc_customer.tbl", "customers"},
    {"../data/tpcc_5w/tpcc_order.tbl", "orders"},
    {"../data/tpcc_5w/tpcc_orderline.tbl", "orderlines"},
    {"../data/tpcc_5w/tpcc_item.tbl", "items"}
})

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