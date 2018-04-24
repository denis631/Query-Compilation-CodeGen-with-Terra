function table.size(t)
    local c = 0
    for k,v in pairs(t) do
        c = c+1
    end
    return c
end

function copy(tab)
    local res = {}

    for _, val in ipairs(tab) do
        table.insert(res, val)
    end

    return res
end

cplist = {}
function getshadow (tab)
    if cplist[tab] then 
        return cplist[tab] -- don't make multiple copies of the same table
    end
    local mt = {cpfrom = tab}
    local shadow = {}
    local cp = {}
    setmetatable(shadow,mt)
    cplist[tab] = shadow

    function mt:__index (key)
        local val = cp[key]
        if val == nil then 
            val = tab[key]
            if type(val)=="table" then
                val = getshadow(val)
                cp[key] = val
            end
        elseif type(val)=="table" and 
				getmetatable(val).cpfrom~=cp[key] then
            cp[key] = nil
            return self[key]
        end
        return val
    end

    mt.__newindex = cp

    return shadow
end
