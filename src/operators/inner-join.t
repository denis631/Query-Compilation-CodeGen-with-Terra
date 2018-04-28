require 'hash.hash-table'
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

    local leftAndRightRequiredAttrs = copy(requiredAttributes)

    for _,predicatePair in ipairs(self.predicates) do
        for leftAttrName,rightAttrName in pairs(predicatePair) do
            table.insert(leftAndRightRequiredAttrs, leftAttrName)
            table.insert(leftAndRightRequiredAttrs, rightAttrName)
        end
    end

    local leftRequiredAttributes = {}
    local rightRequiredAttributes = {}

    local leftIUs = self.leftOperator:collectIUs()
    local rightIUs = self.rightOperator:collectIUs()

    for _,requiredAttr in ipairs(leftAndRightRequiredAttrs) do
        if leftIUs[requiredAttr] ~= nil then
            table.insert(leftRequiredAttributes, requiredAttr)
        else
            table.insert(rightRequiredAttributes, requiredAttr)
        end
   end

    self.leftOperator:prepare(leftRequiredAttributes, self)
    self.rightOperator:prepare(rightRequiredAttributes, self)

    self.symbolsMap = {}

    -- copy left symbols
    for attrName, sym in pairs(self.leftOperator.symbolsMap) do
        self.symbolsMap[attrName] = sym
    end

    -- copy right symbols
    for attrName, sym in pairs(self.rightOperator.symbolsMap) do
        self.symbolsMap[attrName] = sym
    end
end

function InnerJoin:produce(tupleType)
    local leftOperatorProduceCode = self.leftOperator:produce()
    local rightOperatorProduceCode = self.rightOperator:produce()

    return macro(function(datastore)
            local keyT = {}
            local valueT = {}

            -- generate key type for the HashMap
            for _,predicatePair in ipairs(self.predicates) do
                for leftAttrName,_ in pairs(predicatePair) do
                    table.insert(keyT, datastoreIUs[leftAttrName])
                end
            end

            -- generate value type for the HashMap. The types are the types of the required attributes produced by the left operand
            local leftIUs = self.leftOperator:collectIUs()
            for _, attrName in ipairs(self.requiredAttributes) do
                if leftIUs[attrName] ~= nil then
                    table.insert(valueT, datastoreIUs[attrName])
                end
            end

            -- create map symbol for easy access
            self.mapSymbol = symbol(HashTable(tuple(unpack(keyT)), tuple(unpack(valueT))))

            return quote
                -- Declare map
                var [self.mapSymbol]
                [self.mapSymbol]:init()

                -- produce left tuples
                leftOperatorProduceCode(datastore)

                -- finalize map construction
                [self.mapSymbol]:finalize()

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
            local key = terralib.newlist()

            local leftIUs = self.leftOperator:collectIUs()

            if operator == self.leftOperator then
                local value = terralib.newlist()

                -- create key tuple
                for _,predicatePair in ipairs(self.predicates) do
                    for leftAttrName,_ in pairs(predicatePair) do
                        local attrSym = self.symbolsMap[leftAttrName]
                        key:insert(quote in [attrSym] end)
                    end
                end

                -- create value tuple
                for _,attrName in ipairs(self.requiredAttributes) do
                    if leftIUs[attrName] ~= nil then
                        local attrSym = self.symbolsMap[attrName]
                        value:insert(quote in [attrSym] end)
                    end
                end

                -- insertion in map
                stmts:insert(quote [self.mapSymbol]:insert({[key]},{[value]}) end)
            else
                -- create key
                for _,predicatePair in ipairs(self.predicates) do
                    for _,rightAttrName in pairs(predicatePair) do
                        local attrSym = self.symbolsMap[rightAttrName]
                        key:insert(quote in [attrSym] end)
                    end
                end

                -- produce the symbols for the consumer to use
                local produceSymbols = macro(function(val)
                        local stmts = terralib.newlist()
                        local i = 0
                        for _,attrName in ipairs(self.requiredAttributes) do
                            if leftIUs[attrName] ~= nil then
                                local attrSym = self.symbolsMap[attrName]
                                stmts:insert(quote var [attrSym] = val.["_"..i] end)
                                i = i + 1
                            end
                        end

                        return quote [stmts] end
                end)

                -- probe
                stmts:insert(quote
                            var val = [self.mapSymbol]:find({[key]})
                        if val ~= nil then
                            -- produce symbols for the consumer
                            [produceSymbols](val.value)
                            consumerCode()
                        end
                end)
            end

            return quote [stmts] end
    end)
end
