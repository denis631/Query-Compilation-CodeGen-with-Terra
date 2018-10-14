require 'hash.hash-table'

local leftSide, rightSide = 1, 2

-- HashJoin
function AlgebraTree.HashJoin:collectIUs()
    local res = {}

    for attrName, attrType in pairs(self.leftOperator:collectIUs()) do
        res[attrName] = attrType
    end

    for attrName, attrType in pairs(self.rightOperator:collectIUs()) do
        res[attrName] = attrType
    end

    return res
end

function AlgebraTree.HashJoin:prepare(requiredAttributes, consumer)
    self.consumer = consumer
    self.requiredAttributes = copy(requiredAttributes)

    self.keyAttrs = {}

    self.leftRequiredAttributes = {}
    self.rightRequiredAttributes = {}

    for _,predicatePair in ipairs(self.predicates) do
        for leftAttrName,rightAttrName in pairs(predicatePair) do
            self.keyAttrs[leftAttrName] = true
            table.insert(self.leftRequiredAttributes, leftAttrName)
            table.insert(self.rightRequiredAttributes, rightAttrName)
        end
    end

    local leftIUs = self.leftOperator:collectIUs()

    for _,requiredAttr in ipairs(copy(requiredAttributes)) do
        if leftIUs[requiredAttr] ~= nil then
            table.insert(self.leftRequiredAttributes, requiredAttr)
        else
            table.insert(self.rightRequiredAttributes, requiredAttr)
        end
    end

    self.leftOperator:prepare(self.leftRequiredAttributes, self)
    self.rightOperator:prepare(self.rightRequiredAttributes, self)

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

function AlgebraTree.HashJoin:buildKeyType()
    local keyT = {}

    -- generate key type for the HashMap
    for _,predicatePair in ipairs(self.predicates) do
        for leftAttrName,_ in pairs(predicatePair) do
            table.insert(keyT, &datastoreIUs[leftAttrName])
        end
    end

    return keyT
end

function AlgebraTree.HashJoin:buildValueType()
    local valueT = {}

    -- generate value type for the HashMap. 
    -- The types are the types of the required attributes produced by the left operand
    local leftIUs = self.leftOperator:collectIUs()
    for _, attrName in ipairs(self.requiredAttributes) do
        if leftIUs[attrName] ~= nil then
            table.insert(valueT, &datastoreIUs[attrName])
        end
    end

    return valueT
end

function AlgebraTree.HashJoin:produce(tupleType)
    local leftOperatorProduceCode = self.leftOperator:produce()
    local rightOperatorProduceCode = self.rightOperator:produce()

    return macro(function(datastore)
        local keyT = self:buildKeyType()
        local valueT = self:buildValueType()

        -- create map symbol for access to the map variable
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

function AlgebraTree.HashJoin:buildKeyFromTuple(side)
    local key = terralib.newlist()

    for _,predicatePair in ipairs(self.predicates) do
        for leftAttrName,rightAttrName in pairs(predicatePair) do
            local attrSym

            if side == leftSide then 
                attrSym = self.symbolsMap[leftAttrName]
            else
                attrSym = self.symbolsMap[rightAttrName]
            end

            key:insert(quote in [attrSym] end)
        end
    end

    return key
end

function AlgebraTree.HashJoin:buildValueFromTuple()
    local value = terralib.newlist()
    local leftIUs = self.leftOperator:collectIUs()

    -- create value tuple
    for _,attrName in ipairs(self.requiredAttributes) do
        if leftIUs[attrName] ~= nil then
            local attrSym = self.symbolsMap[attrName]
            value:insert(quote in [attrSym] end)
        end
    end

    return value
end

function AlgebraTree.HashJoin:unpackAttributes()
    -- produce the symbols for the consumer to use
    return macro(function(iter)
        local stmts = terralib.newlist()
        local i = 0

        for leftAttrName,_ in pairs(self.keyAttrs) do
            local attrSym = self.symbolsMap[leftAttrName]
            stmts:insert(quote var [attrSym] = iter.key.["_"..i] end)
            i = i + 1
        end

        i = 0
        for _,attrName in ipairs(self.leftRequiredAttributes) do
            if self.keyAttrs[attrName] == nil then
                local attrSym = self.symbolsMap[attrName]
                stmts:insert(quote var [attrSym] = iter.value.["_"..i] end)
                i = i + 1
            end
        end

        return quote [stmts] end
    end)
end

function AlgebraTree.HashJoin:consume(operator)
    -- generate consumer code
    local consumerCode = self.consumer:consume(self)

    return macro(function()
        if operator == self.leftOperator then
            -- create key and value tuples and insert it
            local key = self:buildKeyFromTuple(leftSide)
            local value = self:buildValueFromTuple()
            return quote [self.mapSymbol]:insert({[key]},{[value]}) end
        else
            -- create key to probe with
            local key = self:buildKeyFromTuple(rightSide)

            -- call consumer on all matches
            return quote
                var iterator = [self.mapSymbol]:find({[key]})
                while iterator:hasNext() do
                    var tuple = iterator:next()

                    -- produce symbols for the consumer
                    [self:unpackAttributes()](tuple)
                    consumerCode()
                end
            end
        end
    end)
end
