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

predicateCode = macro(function(predicates, attributes)
    -- TODO: create a function which return a macro. But before creating a macro, this function creates labels for accessing the properties
    local predicateEval = terralib:newlist()
    local predicateStatus = symbol(bool)

    -- the attributes (in this case c_id and c_first) are implicitly copied. We remove them, for the code to work
    predicateEval:remove(1)
    predicateEval:remove(1)

    predicateEval:insert(quote var [predicateStatus] = true end)

    local i = 0
    local N = 2
    while i < N do
      predicateEval:insert(quote
          var attr = attributes.["_"..i]
          var const = predicates.["_"..(i+1)]

          [predicateStatus] = [predicateStatus] and attr:equal(const)
      end)

      i = i + 2
    end

    return quote [predicateEval] in [predicateStatus] end
end)

function Selection:produce(tupleType)
    return self.child:produce()
end

function Selection:consume()
    -- generate consumer code
    local consumerCode = self.consumer:consume()

    return macro(function(attributes)
        return quote
            if predicateCode({ self.predicates }, attributes) then
                consumerCode(attributes)
            end
        end
    end)
end
