require 'parser.parser'

-- TODO: require types
require 'types.integer'
require 'types.varchar'
require 'types.char'
require 'types.timestamp'
require 'types.numeric'

struct Customer {
    c_id : Integer
    c_d_id : Integer
    c_w_id : Integer
    c_first : Varchar(16)
    c_middle : Char(2)
    c_last : Varchar(16)
    c_street_1 : Varchar(20)
    c_street_2 : Varchar(20)
    c_city : Varchar(20)
    c_state : Char(2)
    c_zip : Char(9)
    c_phone : Char(16)
    c_since : Timestamp
    c_credit : Char(2)
    c_credit_lim : Numeric(12, 2)
    c_discount : Numeric(4, 4)
    c_balance : Numeric(12, 2)
    c_ytd_paymenr : Numeric(12, 2)
    c_payment_cnt : Numeric(4, 0)
    c_delivery_cnt : Numeric(4, 0)
    c_data : Varchar(500)
}

struct Datastore {
    customers : &Customer
    customersCount : int
}

function collectDatastoreIUs()
    local ius = {}

    for _, datastoreAttr in ipairs(Datastore.entries) do
        if datastoreAttr["type"]:ispointer() then
            for _,tuple in ipairs(datastoreAttr["type"].type.entries) do
                local attrName = tuple["field"]
                local attrType = tuple["type"]

                ius[attrName] = attrType
            end
        end
    end

    return ius
end

datastoreIUs = collectDatastoreIUs()

function castIfNecessary(fieldType, value)
    if fieldType == Integer or fieldType == Timestamp then
        return tonumber(value)
    else
        return value
    end
end

function findFieldTypeForNameInEntries(fieldName, entries)
    for _,tuple in ipairs(entries) do
        if tuple["field"] == fieldName then
            return tuple["type"]
        end
    end
end

function parse(path, class, propertyName)
    local csvRows = load(path, '|')
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
                -- find the field type of attribute to be set
                local fieldName = class.entries[index]["field"]
                local fieldType = class.entries[index]["type"]

                -- cast if necessary, since all data read are strings
                attr = castIfNecessary(fieldType, attr)

                -- assign the property to element in array at index i-1; lua-indices start at 1
                l:insert(quote
                    -- call init method in order to initialize the property
                    datastore.[propertyName][i-1].[fieldName]:init(attr)
                end)
            end
        end

        return quote [l] end
    end)
end

-- TODO: try iterative loading per row
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
