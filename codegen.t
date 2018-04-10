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

function TableScan:new()
    local t = TableScan.parentClass.new(self)
    return t
end

function TableScan:prepare(parent)
    self.parent = parent
end

function TableScan:produce()
    local consumerCode = self.parent:consume()

    return terra(data : &int, N: int)
        for i = 0, N do
            consumerCode(data[i])
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

function Projection:consume()
    -- we can pass the type in the consume function and have a terra function with the passed type. 
    return terra(a : int)
        C.printf("%d\n", a)
    end
end
--

init = terra()
    var d = [&int](C.malloc(sizeof(int) * 10))

    for i = 0, 10 do
        d[i] = i
    end

    return d
end

data = init()

local query = Projection:new(TableScan:new())
query:prepare()
code = query:produce()

print(code)
code(data, 10)