-- TableScan
TableScan = Operator:newChildClass()

function TableScan:new(tableName)
    local t = TableScan.parentClass.new(self)
    t.tableName = tableName
    return t
end

function TableScan:prepare(requiredIUs, consumer)
    self.consumer = consumer
    self.symbolsMap = {}

    -- generating attribute symbols
    for _, iu in ipairs(requiredIUs) do
        for attrName, attrType in pairs(iu) do
            self.symbolsMap[attrName] = symbol(attrType)
        end
    end
end

--TODO: implement
function TableScan:collectIUs()
    local ius = {}



    return ius
end

function TableScan:getAttributes()
    return macro(function(row)
        local attributes = terralib:newlist()

        -- initialize symbol vars with row attributes
        for attrName, attrSymbol in pairs(self.symbolsMap) do
            attributes:insert(quote var [attrSymbol] = row.[attrName] end)
        end

        return quote [attributes] end
    end)
end

function TableScan:produce()
    -- generating consumer code and load attributes code
    local consumerCode = self.consumer:consume()
    local loadAttributesFrom = self:getAttributes()

    return terra(datastore : &Datastore)
        -- access required table and it's count
        var table = datastore.[self.tableName]
        var tableCount = datastore.[self.tableName .. "Count"]

        for i = 0, tableCount do
            -- access required attributes
            var row = &table[i]
            loadAttributesFrom(row)

            -- run consumer code
            consumerCode()
        end
    end
end
