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

function AlgebraTree.Projection:consume(operator)
    return macro(function()
        local stringAttributes = terralib.newlist()

        -- print all required attributes
        for _, attrName in ipairs(self.requiredAttrs) do
            stringAttributes:insert(quote C.printf("%s | ", [&int8]([self.symbolsMap[attrName]]:toString())) end)
        end

        stringAttributes:insert(quote C.printf("\n") end)

        return quote [stringAttributes] end
    end)
end
