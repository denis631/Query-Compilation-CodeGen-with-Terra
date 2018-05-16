-- Projection
function AlgebraTree.Projection:prepare()
    self.child:prepare(self.requiredAttrs, self)

    -- store the attribute symbols from the child
    self.symbolsMap = self.child.symbolsMap
end

function AlgebraTree.Projection:collectIUs()
    return self.child:collectIUs()
end

function AlgebraTree.Projection:produce()
    local produceCode = self.child:produce()
    return terra(datastore : &Datastore)
        produceCode(datastore)
    end
end

function AlgebraTree.Projection:printAttributes()
  return macro(function()
      local stringAttributes = terralib.newlist()

      -- stringify the attributes
      for _, attrName in ipairs(self.requiredAttrs) do
          stringAttributes:insert(quote C.printf("%s | ", [&int8]([self.symbolsMap[attrName]]:toString())) end)
      end

      stringAttributes:insert(quote C.printf("\n") end)

      -- First half of the list is implicitly filled with passed arguments, this is why we remove it
      return quote [stringAttributes] end
  end)
end

function AlgebraTree.Projection:consume(operator)
    local printify = self:printAttributes()

    return macro(function()
        return quote
            printify()
        end
    end)
end
