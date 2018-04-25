-- Selection
Selection = Operator:newChildClass()

function Selection:new(child, predicates)
    local t = TableScan.parentClass.new(self)
    t.child = child
    t.predicates = predicates
    return t
end

function Selection:prepare(requiredIUs, consumer)
    self.consumer = consumer
    self.requiredIUs = requiredIUs

    local childRequiredIUs = copy(requiredIUs)

    for _, iu in ipairs(self.predicates) do
        for key, _ in pairs(iu) do
            if childRequiredIUs[key] == nil then
                table.insert(childRequiredIUs, { [key] = datastoreIUs[key]})
            end
        end
    end

    self.child:prepare(childRequiredIUs, self)

    self.symbolsMap = self.child.symbolsMap
end

function Selection:predicate()
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
    local predicateEval = terralib:newlist()

    -- initialize the predicateStatus var. By default is true
    predicateEval:insert(quote var [predicateStatus] = true end)

    return macro(function()
        -- remove implicitly inserted entries
        for i = 1,#predicateEval do
            predicateEval:remove(1)
        end

        -- evaluate all the predicates
        for i = 0,(#self.predicates - 1) do
            local attrName = attrNames[i+1]
            local const = consts[i+1]

            predicateEval:insert(quote
                [predicateStatus] = [predicateStatus] and [self.symbolsMap[attrName]]:equal(const)
            end)
        end

        return quote [predicateEval] in [predicateStatus] end
    end)
end

function Selection:produce(tupleType)
    return self.child:produce()
end

function Selection:consume()
    -- generate consumer code
    local consumerCode = self.consumer:consume()
    local predicateCode = self:predicate()

    return macro(function()
        return quote
            if predicateCode() then
                consumerCode()
            end
        end
    end)
end
