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

function Projection:consume()
    local formatString = createFormatString(self.attrTypes)

    return macro(function(attributes)
        return quote
            C.printf(formatString, attributes)
        end
    end)
end
