-- TableScan
function AlgebraTree.TableScan:prepare(requiredAttributes, consumer)
    self.consumer = consumer
    self.symbolsMap = {}

    -- generating attribute symbols
    for _, attrName in ipairs(requiredAttributes) do
        self.symbolsMap[attrName] = symbol(&datastoreIUs[attrName], attrName)
    end
end

function AlgebraTree.TableScan:collectIUs()
    local ius = {}

    for _, iu in ipairs(relationClassMap[self.tableName].entries) do
        ius[iu["field"]] = iu["type"]
    end

    return ius
end

function AlgebraTree.TableScan:getAttributes()
    return macro(function(row)
        local attributes = terralib.newlist()

        -- initialize symbol vars with row attributes
        for attrName, attrSymbol in pairs(self.symbolsMap) do
            attributes:insert(quote var [attrSymbol] = &row.[attrName] 
            -- C.printf("%s\n", row.[attrName]:toString())
        end)
        end

        return quote [attributes] end
    end)
end

function AlgebraTree.TableScan:produce()
    -- generating consumer code and load attributes code
    local consumerCode = self.consumer:consume(self)
    local loadAttributesFrom = self:getAttributes()

    return macro(function(datastore)
        return quote
            -- access required table and it's count
            var table = datastore.[self.tableName]

            for i = 0, datastore.[self.tableName]:count() do
                -- access required attributes
                var tuple = table:getPtr(i)
                loadAttributesFrom(tuple)

                -- run consumer code
                consumerCode()
            end
        end
    end)
end