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

    -- TODO: add new required ius because of ius that are used by the if predicate
    -- for key, value in pairs(requiredIUs) do
    --     if !contains(requiredIUs, key) then
    --         table.insert(requiredIUs, { key = value })
    --     end
    -- end

    self.child:prepare(requiredIUs, self)
end

function Selection:predicate(predicates)
  local attrNames = {}
  local consts = {}

  local N = #self.requiredIUs

  for _, predicatePair in ipairs(predicates) do
    for attrName, const in pairs(predicatePair) do
      table.insert(attrNames, attrName)
      table.insert(consts, const)
    end
  end

  return macro(function(attributes)
      local predicateEval = terralib:newlist()
      local predicateStatus = symbol(bool)

      -- the attributes (in this case c_id and c_first) are implicitly copied. We remove them, for the consumer code to work. Dunno why it's like that
      for i = 1,N do
          predicateEval:remove(1)
      end

      -- initialize the predicateStatus var. By default is true
      predicateEval:insert(quote var [predicateStatus] = true end)

      for i = 0,0 do
        local attrName = attrNames[i+1]

        predicateEval:insert(quote
              var consts = { consts }
              var attr = attributes.["_"..i].[attrName]
              var const = consts.["_"..i]

              [predicateStatus] = [predicateStatus] and attr:equal(const)
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
    local predicateCode = self:predicate(self.predicates)

    return macro(function(attributes)
        return quote
            if predicateCode(attributes) then
                consumerCode(attributes)
            end
        end
    end)
end
