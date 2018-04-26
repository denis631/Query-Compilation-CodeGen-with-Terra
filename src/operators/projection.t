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
    return self.child:produce()
end

function createFormatString(N)
    local formatString = "| "

    for i = 1,N do
        formatString = formatString .. "%s | "
    end

    return formatString .. "\n"
end

function Projection:stringAttributes()
  return macro(function()
      local stringAttributes = terralib:newlist()

      -- remove implicitly inserted entries
      for i = 1,#stringAttributes do
          stringAttributes:remove(1)
      end

      -- stringify the attributes
      for _, attrName in ipairs(self.requiredAttributes) do
          stringAttributes:insert(quote in [&int8]([self.symbolsMap[attrName]]:toString()) end)
      end

      -- First half of the list is implicitly filled with passed arguments, this is why we remove it
      return quote in [stringAttributes] end
  end)
end

function Projection:consume()
    local formatString = createFormatString(table.size(self.requiredAttributes))
    local stringify = self:stringAttributes()

    return macro(function()
        return quote
            var stringAttrs = stringify()
            C.printf(formatString, stringAttrs)
        end
    end)
end
