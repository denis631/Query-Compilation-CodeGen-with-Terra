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

    local requiredIUs = requiredIUs

    -- add new required ius because of ius that are used by the if predicate
    -- for key, value in pairs(requiredIUs) do
    --     if !contains(requiredIUs, key) then
    --         table.insert(requiredIUs, { key = value })
    --     end
    -- end

    self.child:prepare(requiredIUs, self)
end

predicateCode = macro(function(condition)
    local N = 1

    -- for i = 0,N do

    -- end
    
    return `condition.["_0"] == condition._1 and 1 == 1
end)

function Selection:produce(tupleType)
    return self.child:produce()
end

function Selection:consume()
    -- generate consumer code
    local consumerCode = self.consumer:consume()

    return macro(function(attributes)
        return quote 
            -- destructuring in a nutshell
            var x = attributes._0

            if predicateCode({x, 1}) then 
                consumerCode(attributes)
            end
        end
    end)
end