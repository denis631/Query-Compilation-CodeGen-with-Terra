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
        parentClass = self
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

function TableScan:new(tupleType)
    local t = TableScan.parentClass.new(self)
    t.tupleType = tupleType
    return t
end

function TableScan:prepare(parent)
    self.parent = parent

    self.attrTypes = {}
    self.attrNames = {}
    
    -- getting the IUs to produce
    for attrName, attrType in pairs(parent.requiredIUs) do
        -- TODO: remove this code, when more than one type can be used
        self.attrType = attrType
        self.attrName = attrName
        
        table.insert(self.attrNames, attrName)
        table.insert(self.attrTypes, attrType)
    end
end

function TableScan:produce()
    -- generating consumer code, while also telling which attributes are going to be used, 
    -- so that terra function can be generated
    -- TODO: generate an exotype (aka new type/struct on the flight)
    local consumerCode = self.parent:consume(self.attrTypes)

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

function Projection:new(child, requiredIUs)
    local p = Projection.parentClass.new(self)
    p.child = child
    p.requiredIUs = requiredIUs
    return p
end

function Projection:produce()
    return self.child:produce()
end

function Projection:consume(attrTypes)
    local formatString = "| "

    for _,attrType in ipairs(attrTypes) do
        -- add more cases for other types if needed, strings, dates, doubles, etc.
        if attrType ==  int then
            formatString = formatString .. "%d | "
        elseif attrType == double then
            formatString = formatString .. "%f | "
        elseif attrType == rawstring then
            formatString = formatString .. "%s | "
        end
    end

    formatString = formatString .. "\n"

    print(formatString)

    return terra(a: attrTypes)
        C.printf(formatString, a)
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
        u[i].name = "TEST"
    end

    return u
end

data = init()

-- desired interface -> new:(tableName / tableType?)
-- TableScan:new("users")
-- Projection:new(childOperator, printIUs) -> How to represent printIUs?
-- Map tableName -> type?
-- HashMap of tables? Datastore struct with different tables?

local query = Projection:new(TableScan:new(User), { ["name"] = rawstring })
query:prepare()
code = query:produce()

code:printpretty()
code(data, 2)