-- Projection
Projection = Operator:newChildClass()

function Projection:new(child, requiredIUs)
    local p = Projection.parentClass.new(self)
    p.child = child
    p.requiredIUs = requiredIUs
    return p
end

function Projection:test(t)
    return terra(a: t)
    end
end

function Projection:produce()
    return self.child:produce()
end

function formatForType(type)
    if attrType ==  int then
        return "%d"
    elseif attrType == double then
        return "%f"
    elseif attrType == rawstring then
        return "%s"
    end
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

    return terra(a: attrTypes)
        C.printf(formatString, a)
    end
end