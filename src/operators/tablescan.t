-- TableScan
TableScan = Operator:newChildClass()

function TableScan:new(tableName)
    local t = TableScan.parentClass.new(self)
    t.tableName = tableName
    return t
end

function TableScan:prepare(consumer)
    self.consumer = consumer
    self.attrNames = {}
    
    -- getting the IUs to produce
    for _, iu in ipairs(consumer.requiredIUs) do
        for attrName, attrType in pairs(iu) do
            table.insert(self.attrNames, attrName)
        end
    end
end

function TableScan:getAttributes()
    return macro(function(table)
        local attributes = terralib:newlist()

        for _,attribute in pairs(self.attrNames) do
            attributes:insert(quote in table.[attribute] end)
        end
    
        return quote in [attributes] end
    end)
end

function TableScan:produce()
    -- generating consumer code
    local consumerCode = self.consumer:consume()
    local getAttributesFrom = self:getAttributes()

    return terra(datastore : &Datastore)
        -- access required table and it's count
        var table = datastore.[self.tableName]
        var tableCount = datastore.[self.tableName .. "Count"]

        for i = 0, tableCount do
            -- access required attributes
            var tuple = &table[i]
            var attrs = getAttributesFrom(tuple)
            consumerCode(attrs)
        end
    end
end