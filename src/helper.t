require 'vector.vector'

function table.size(t)
    local c = 0
    for k,v in pairs(t) do
        c = c+1
    end
    return c
end

function copy(tab)
    local res = {}

    for key, val in pairs(tab) do
        res[key] = val
    end

    return res
end