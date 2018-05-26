require 'parser.parser'
require 'schema.schema'

struct Datastore {
    customers : Vector(Customer)
    orders : Vector(Order)
    orderlines : Vector(Orderline)
    items : Vector(Item)
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
        -- init with known capacity
        datastore.[propertyName]:initWithCapacity(csvRowsCount)
        var tmp : relationClassMap[propertyName]

        for i = 0,csvRowsCount do
            -- push default values
            datastore.[propertyName]:push(tmp)
        end
    end

    init()

    local propertySetter = {}

    for i, iu in ipairs(class.entries) do
        local fieldName = iu["field"]
        local fieldType = iu["type"]

        -- generate setter func
        propertySetter[fieldName] = terra(idx : int, param : fieldType.rawType)
            datastore.[propertyName]:getPtr(idx).[fieldName]:init(param)
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

relationClassMap = {
    ["customers"] = Customer,
    ["orders"] = Order,
    ["orderlines"] = Orderline,
    ["items"] = Item
}

function collectDatastoreIUs()
    local ius = {}

    for _,class in pairs(relationClassMap) do
        for _,tuple in ipairs(class.entries) do
            local attrName = tuple["field"]
            local attrType = tuple["type"]

            ius[attrName] = attrType
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
