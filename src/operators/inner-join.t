-- InnerJoin
InnerJoin = Operator:newChildClass()

function InnerJoin:new(leftOperator, rightOperator, predicates)
    local t = TableScan.parentClass.new(self)
    t.leftOperator = leftOperator
    t.rightOperator = rightOperator
    t.predicates = predicates
    return t
end

function InnerJoin:prepare(requiredAttributes, consumer)
    self.consumer = consumer
    self.requiredAttributes = copy(requiredAttributes)

    for _,predicatePair in ipairs(self.predicates) do
        for leftAttrName,rightAttrName in pairs(predicatePair) do
            table.insert(self.requiredAttributes, leftAttrName)
            table.insert(self.requiredAttributes, rightAttrName)
        end
    end

    local leftRequiredAttributes = {}
    local rightRequiredAttributes = {}

    local leftIUs = self.leftOperator:collectIUs()
    local rightIUs = self.rightOperator:collectIUs()

    for _,requiredAttr in ipairs(self.requiredAttributes) do
        if leftIUs[requiredAttr] ~= nil then
            table.insert(leftRequiredAttributes, requiredAttr)
        else
            table.insert(rightRequiredAttributes, requiredAttr)
        end
    end

    self.leftOperator:prepare(leftRequiredAttributes, self)
    self.rightOperator:prepare(rightRequiredAttributes, self)

    self.symbolsMap = copy(self.leftOperator.symbolsMap)
    -- copy righy symbols
    for attrName, sym in pairs(self.rightOperator.symbolsMap) do
        self.symbolsMap[attrName] = sym
    end
end

function InnerJoin:produce(tupleType)
    local leftOperatorProduceCode = self.leftOperator:produce()
    local rightOperatorProduceCode = self.rightOperator:produce()

    return macro(function(datastore)
            -- local keyT = terralib:newlist()
            -- for _,predicatePair in ipairs(predicates) do
            --     for leftAttrName,rightAttrName in pairs(predicatePair) do
            --         keyT:insert(quote in datastoreIUs[leftAttrName]
            --         end)
            --     end
            -- end

            return quote
                    -- Declare map
                var map : HashTable(Integer, Integer)
                map:init()

                -- produce left tuples
                leftOperatorProduceCode(datastore)

                -- finalize map construction
                map:finalize()

                -- produce right tuples
                rightOperatorProduceCode(datastore)
        end
    end)
end

function InnerJoin:consume(operator)
    -- generate consumer code
    local consumerCode = self.consumer:consume(self)

    return macro(function()
            local stmts = terralib.newlist()

            if operator == self.leftOperator then
                -- insertion in map
                stmts:insert(quote
                        var x = 1
                end)
            else
                -- probing
                stmts:insert(quote var x = 2 end)
            end


            return quote
                    [stmts]
            -- consumerCode()
        end
    end)
end
