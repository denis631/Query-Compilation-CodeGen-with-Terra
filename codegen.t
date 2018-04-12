terralib.includepath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include"

C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
]]

-- Abstract class - Operator
Operator = {}

function Operator:new()        -- constructor of instance
   self.__index = self
   return setmetatable({}, self)
end

function Operator:newChildClass()  -- constructor of subclass
    self.__index = self
    return setmetatable({
        parentClass = self,
    }, self)
 end

function Operator:prepare()
    self.child:prepare(self)
end

 -- abstract methods
function Operator:produce() end
function Operator:consume() end 

 -- TableScan
TableScan = Operator:newChildClass()

function TableScan:new(attrType, attrName, tupleType)
    local t = TableScan.parentClass.new(self)
    t.attrType = attrType
    t.attrName = attrName
    t.tupleType = tupleType
    return t
end

function TableScan:prepare(parent)
    self.parent = parent
end

function TableScan:produce()
    -- find type for attribute? -> need to know tables -> can generate IUs dynamically on demand!
    local consumerCode = self.parent:consume(self.attrType)

    return terra(data : &(self.tupleType), N : int)
        for i = 0, N do
            -- access field with the name attrName
            var attr = (&data[i]).[self.attrName]
            consumerCode(attr)
        end
    end
end

-- Projection
Projection = Operator:newChildClass()

function Projection:new(child)
    local p = Projection.parentClass.new(self)
    p.child = child
    return p
end

function Projection:produce()
    return self.child:produce()
end

function Projection:consume(attrType)
    -- we can pass the type in the consume function and have a terra function with the passed type. 
    return terra(a : attrType)
        C.printf("%d\n", a)
    end
end
--

struct User {
    id : int
    name : rawstring
}

init = terra()
    -- Read & parse the data from disk
    var u = [&User](C.malloc(sizeof(User) * 2))

    for i = 0, 2 do
        u[i].id = i
    end

    return u
end

data = init()

-- desired interface -> new:(tableName / tableType?)
-- TableScan:new("users")
-- Projection:new(childOperator, printIUs) -> How to represent printIUs?
-- Map tableName -> type?
-- HashMap of tables? Datastore struct with different tables?

local query = Projection:new(TableScan:new(int, "id", User))
query:prepare()
code = query:produce()

print(code)
code(data, 2)