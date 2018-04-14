require 'parser.parser'

struct User {
    id : int
    name : rawstring
}

struct Datastore {
    users : &User
    usersCount : int
}

-- TODO: Define structs on the flight while parsing csv?

function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
  
    table.sort(keys, function(a, b)
      return sortFunction(tbl[a], tbl[b])
    end)
  
    return keys
end

function castIfNecessary(value)
    -- Use entries field for smart cast? We know the type we want to cast, but it's a terra type. 
    -- User.entries[index]["field"]
    local num = tonumber(value)
    if num ~= nil then
        return num
    else
        return value
    end
end

function parse(path, class, propertyName)
    local csvRows = load(path, ',')
    local attrs = getKeysSortedByValue(getmetatable(csvRows), function(a, b) return a < b end)
    local csvRowsCount = table.getn(csvRows)

    return macro(function(datastore)
        local l = terralib.newlist()

        -- set the count of the users array
        l:insert(quote
            datastore.[propertyName .. "Count"] = csvRowsCount 
        end)

        -- allocate users array
        l:insert(quote 
            datastore.[propertyName] = [&class](C.malloc(sizeof(class) * csvRowsCount))
        end)

        for i,tuple in ipairs(csvRows) do
            for index, attr in pairs(csvRows[i]) do
                -- cast if possible, since all data read are strings
                attr = castIfNecessary(attr)

                -- assign the property to element in array at index i-1; lua-indices start at 1
                l:insert(quote
                    datastore.[propertyName][i-1].[attrs[index]] = attr
                end)
            end
        end
        
        return quote [l] end
    end)
end

function loadDatastore(parseParams)
    local stmts = terralib.newlist()
    local datastore = symbol(&Datastore)

    stmts:insert(quote
        var [datastore] = [&Datastore](C.malloc(sizeof(Datastore)))
    end)

    for _,params in ipairs(parseParams) do
        local path = params[1]
        local class = params[2]
        local attr = params[3]

        stmts:insert(quote
            [parse(path, class, attr)]([datastore])
        end)
    end

    return terra() 
        [stmts]
        return [datastore]
    end
end