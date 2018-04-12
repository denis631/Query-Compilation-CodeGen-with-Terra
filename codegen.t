terralib.includepath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include"

C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
]]

require 'operator'
require 'datastore'
require 'tablescan'
require 'projection'

datastore = loadDatastore()

-- desired interface -> new:(tableName / tableType?)
-- TableScan:new("users")
-- Projection:new(childOperator, printIUs) -> How to represent printIUs?
-- Map tableName -> type?
-- HashMap of tables? Datastore struct with different tables?

local query = Projection:new(TableScan:new("users"), { ["name"] = rawstring })
query:prepare()
code = query:produce()

code:printpretty()
code(datastore)