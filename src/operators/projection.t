-- Projection
Projection = Operator:newChildClass()

function Projection:new(child, requiredIUs)
    local p = Projection.parentClass.new(self)
    p.__type = Projection
    p.child = child
    p.requiredIUs = requiredIUs
    return p
end

function Projection:prepare()
    self.attrTypes = {}

    for _, iu in ipairs(self.requiredIUs) do
        for attrName, attrType in pairs(iu) do
            table.insert(self.attrTypes, attrType)
        end
    end

    self.child:prepare(self.requiredIUs, self)
end

function Projection:produce()
    return self.child:produce()
end

function createFormatString(attrTypes)
    local formatString = "| "

    for _,attrType in ipairs(attrTypes) do
        formatString = formatString .. "%s | "
    end

    return formatString .. "\n"
end

function removeFirstHalf(list)
  local res = terralib:newlist()

  for i = 1,(#list)/2 do
    res:remove(1)
  end

  return res
end

function stringAttributes(N)
  return macro(function(attributes)
      local stringAttributes = terralib:newlist()

      for i = 0,N-1 do
        stringAttributes:insert(quote in [&int8](attributes.["_"..i]:toString()) end)
      end

      -- First half of the list is implicitly filled with passed arguments, this is why we remove it
      return quote in [removeFirstHalf(stringAttributes)] end
  end)
end

function Projection:consume()
    local formatString = createFormatString(self.attrTypes)
    local stringify = stringAttributes(#self.attrTypes)

    return macro(function(attributes)
        return quote
            var stringAttrs = stringify(attributes)
            C.printf(formatString, stringAttrs)
        end
    end)
end
