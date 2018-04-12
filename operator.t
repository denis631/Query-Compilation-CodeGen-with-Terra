-- Abstract class - Operator
Operator = {}

function Operator:new()        -- constructor of instance
   self.__index = self
   return setmetatable({}, self)
end

function Operator:newChildClass()  -- constructor of subclass
    self.__index = self
    return setmetatable({ parentClass = self }, self)
 end

function Operator:prepare()
    self.child:prepare(self)
end

 -- abstract methods
function Operator:produce() end
function Operator:consume() end 