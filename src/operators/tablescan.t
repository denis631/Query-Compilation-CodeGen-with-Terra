-- TableScan
TableScan = Operator:newChildClass()

function TableScan:new(tableName)
    local t = TableScan.parentClass.new(self)
    t.tableName = tableName
    return t
end

function TableScan:prepare(parent)
    self.parent = parent

    self.attrTypes = {}
    self.attrNames = {}
    
    -- getting the IUs to produce
    for _, iu in ipairs(parent.requiredIUs) do
        for attrName, attrType in pairs(iu) do
            table.insert(self.attrNames, attrName)
            table.insert(self.attrTypes, attrType)
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
    -- generating consumer code, while also telling which attributes are going to be used, so that terra function can be generated
    local consumerCode = self.parent:consume(self.attrTypes)
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