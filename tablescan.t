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
    for attrName, attrType in pairs(parent.requiredIUs) do
        -- TODO: remove this code, when more than one type can be used
        self.attrName = attrName
        
        table.insert(self.attrNames, attrName)
        table.insert(self.attrTypes, attrType)
    end
end

function TableScan:produce()
    -- generating consumer code, while also telling which attributes are going to be used, so that terra function can be generated
    local consumerCode = self.parent:consume(self.attrTypes)

    return terra(datastore : &(Datastore))
        -- access required table and it's count
        var table = datastore.[self.tableName]
        var tableCount = datastore.[self.tableName .. "Count"]

        for i = 0, tableCount do
            -- access field with the name attrName
            var attr = (&table[i]).[self.attrName]
            consumerCode(attr)
        end
    end
end