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

function formatForType(type)
    -- TODO: add more cases for other types if needed, strings, dates, doubles, etc.
    if type ==  int then
        return "%d"
    elseif type == double then
        return "%f"
    elseif type == rawstring then
        return "%s"
    end
end

function Projection:consume(attrTypes)
    local formatString = "| "

    for _,attrType in ipairs(attrTypes) do
        formatString = formatString .. formatForType(attrType) .. " | "
    end

    formatString = formatString .. "\n"

    return macro(function(attributes)
        return quote 
            C.printf(formatString, attributes)
        end
    end)
end