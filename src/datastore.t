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
    local tab = load(path, ',')
    local attrs = getKeysSortedByValue(getmetatable(tab), function(a, b) return a < b end)
    local tableCount = table.getn(tab)

    return macro(function(datastore)
        local l = terralib.newlist()

        -- set the count of the users array
        l:insert(quote
            datastore.[propertyName .. "Count"] = tableCount 
        end)

        -- allocate users array and save the symbol, since this is the value, which we are going to return
        local dataArray = symbol(&class)
        l:insert(quote 
            var [dataArray] = [&class](C.malloc(sizeof(class) * tableCount))
        end)

        for i,tuple in ipairs(tab) do
            for index, attr in pairs(tab[i]) do
                -- cast if possible, since all data read are strings
                attr = castIfNecessary(attr)

                l:insert(quote
                    [dataArray][i-1].[attrs[index]] = attr
                end)
            end
        end
        
        return quote [l] in [dataArray] end
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
            [datastore].[attr] = [parse(path, class, attr)]([datastore])
        end)
    end

    return terra() 
        [stmts]
        return [datastore]
    end
end