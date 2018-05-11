-- Selection
function AlgebraTree.Selection:prepare(requiredAttributes, consumer)
    self.consumer = consumer
    self.requiredAttributes = requiredAttributes

    local childRequiredAttributes= copy(requiredAttributes)

    for _, predicate in ipairs(self.predicates) do
        for attrName, _ in pairs(predicate) do
            if childRequiredAttributes[attrName] == nil then
                table.insert(childRequiredAttributes, attrName)
            end
        end
    end

    self.child:prepare(childRequiredAttributes, self)

    self.symbolsMap = self.child.symbolsMap
end

function AlgebraTree.Selection:collectIUs()
    return self.child:collectIUs()
end

function AlgebraTree.Selection:predicate()
    local attrNames = {}
    local consts = {}

    -- split predicates into attrNames and consts
    for _, predicatePair in ipairs(self.predicates) do
        for attrName, const in pairs(predicatePair) do
            table.insert(attrNames, attrName)
            table.insert(consts, const)
        end
    end

    -- codegen vars
    local predicateStatus = symbol(bool)
    local predicateEval = terralib.newlist()

    -- initialize the predicateStatus var. By default is true
    predicateEval:insert(quote var [predicateStatus] = true end)

    return macro(function()
        -- evaluate all the predicates
        for i = 0,(#self.predicates - 1) do
            local attrName = attrNames[i+1]
            local const = consts[i+1]

            predicateEval:insert(quote
                [predicateStatus] = [predicateStatus] and (@[self.symbolsMap[attrName]]):equal(const)
            end)
        end

        return quote [predicateEval] in [predicateStatus] end
    end)
end

function AlgebraTree.Selection:produce(tupleType)
    return self.child:produce()
end

function AlgebraTree.Selection:consume(operator)
    -- generate consumer code
    local consumerCode = self.consumer:consume(self)
    local predicateCode = self:predicate()

    return macro(function()
        return quote
            if predicateCode() then
                consumerCode()
            end
        end
    end)
end
