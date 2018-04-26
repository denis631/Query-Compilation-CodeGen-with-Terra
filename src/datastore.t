require 'parser.parser'

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

function loadDatastore(parseParams)
    local datastoreInit = terra()
        return [&Datastore](C.malloc(sizeof(Datastore)))
    end
    local datastore = datastoreInit()

    for _,params in ipairs(parseParams) do
        local path = params[1]
        local attr = params[2]

        parse(path, attr, datastore)
    end

    return datastore
end

function parse(path, propertyName, datastore)
    local csvRows = load(path, '|')
    local csvRowsCount = #csvRows
    local class = relationClassMap[propertyName]

    local init = terra()
        -- set property count
        datastore.[propertyName .. "Count"] = csvRowsCount
        -- allocate array
        datastore.[propertyName] = [&class](C.malloc(sizeof(class) * csvRowsCount))
    end
    init()

    local propertySetter = {}

    for i, iu in ipairs(class.entries) do
        local fieldName = iu["field"]
        local fieldType = iu["type"]

        -- generate setter func
        propertySetter[fieldName] = terra(idx : int, param : fieldType.rawType)
            datastore.[propertyName][idx].[fieldName]:init(param)
        end
    end

    for i,tuple in ipairs(csvRows) do
        local stmts = terralib.newlist()

        for index, attr in pairs(csvRows[i]) do
            -- find the field type of attribute to be set
            local fieldName = class.entries[index]["field"]
            local fieldType = class.entries[index]["type"]

            -- cast if necessary, since all data read are strings
            attr = castIfNecessary(fieldType, attr)

            propertySetter[fieldName](i - 1, attr)
        end
    end
end

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

relationClassMap = {
    ["customers"] = Customer
}

function castIfNecessary(fieldType, value)
    if fieldType == Integer or fieldType == Timestamp then
        return tonumber(value)
    else
        return value
    end
end
