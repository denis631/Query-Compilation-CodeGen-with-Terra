-- TableScan
TableScan = Operator:newChildClass()

function TableScan:new(tableName)
    local t = TableScan.parentClass.new(self)
    t.tableName = tableName
    return t
end

function TableScan:prepare(requiredIUs, consumer)
    self.consumer = consumer
    self.attrNames = {}

    -- getting the IUs to produce
    for _, iu in ipairs(requiredIUs) do
        for attrName, attrType in pairs(iu) do
            table.insert(self.attrNames, attrName)
        end
    end
end

function TableScan:getAttributes()
    return macro(function(table)
        local attributes = terralib:newlist()

        for _,attribute in pairs(self.attrNames) do
            if self.consumer.__type == Projection then
                -- generate strings if the consumer is projection, so that we can just print the strings
                -- cast to [&int8] aka char* so that printf works as expected
                attributes:insert(quote in [&int8](table.[attribute]:toString()) end)
            else
                -- if consumer is not projection, then pass the attribute as it is
                attributes:insert(quote in table.[attribute] end)
            end
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
