local error = error
local setmetatable = setmetatable
local lines = io.lines
local insert = table.insert
local ipairs = ipairs
local string = string

string.split = function (str, pattern)
    pattern = pattern or "[^%s]+"
    if pattern:len() == 0 then pattern = "[^%s]+" end
    local parts = {__index = insert}
    setmetatable(parts, parts)
    str:gsub(pattern, parts)
    setmetatable(parts, nil)
    parts.__index = nil
    return parts
end

local function parse_title(title, sep)
    local desc = title:split("[^" .. sep .. "]+")
    local class_mt = {}
    for k, v in ipairs(desc) do
        class_mt[v] = k
    end
    return class_mt
end

local function parse_line(mt, line, sep) 
    local data = line:split("[^" .. sep .. "]+")
    setmetatable(data, mt)
    return data
end

function load(path, sep)
    local tag, sep, mt, data = false, sep or '|', nil, {}
    for line in lines(path) do
        if not tag then
            tag = true
            mt = parse_title(line, sep)
            -- mt.__index = function(t, k) if mt[k] then return t[mt[k]] else return nil end end
            -- mt.__newindex = function(t, k, v) error('attempt to write to undeclare variable "' .. k .. '"') end
        else
            insert(data, parse_line(mt, line, sep))
        end
    end

    setmetatable(data, mt)
    return data
end

local class_mt = {
    __newindex = function(t, k, v)
        error('attempt to write to undeclare variable "' .. k .. '"')
    end
}