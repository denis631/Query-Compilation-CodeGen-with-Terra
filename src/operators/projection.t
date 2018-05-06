-- Projection
Projection = Operator:newChildClass()

function Projection:new(child, requiredAttributes)
    local p = Projection.parentClass.new(self)
    p.__type = Projection
    p.child = child
    p.requiredAttributes = requiredAttributes
    return p
end

function Projection:prepare()
    self.child:prepare(copy(self.requiredAttributes), self)

    -- store the attribute symbols from the child
    self.symbolsMap = self.child.symbolsMap
end

function Projection:produce()
    local produceCode = self.child:produce()
    return terra(datastore : &Datastore)
        produceCode(datastore)
    end
end

function Projection:printAttributes()
  return macro(function()
      local stringAttributes = terralib.newlist()

      -- stringify the attributes
      for _, attrName in ipairs(self.requiredAttributes) do
          stringAttributes:insert(quote C.printf("%s | ", [&int8]([self.symbolsMap[attrName]]:toString())) end)
      end

      stringAttributes:insert(quote C.printf("\n") end)

      -- First half of the list is implicitly filled with passed arguments, this is why we remove it
      return quote [stringAttributes] end
  end)
end

function Projection:consume(operator)
    local printify = self:printAttributes()

    return macro(function()
        return quote
            printify()
        end
    end)
end
