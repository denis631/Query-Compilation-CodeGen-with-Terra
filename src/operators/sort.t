-- Sort
function AlgebraTree.Sort:collectIUs()
    return self.child:collectIUs()
end

function AlgebraTree.Sort:prepare(requiredAttrs, consumer)
    self.requiredAttrs = copy(requiredAttrs)
    self.consumer = consumer

    -- check for duplicates
    for _,sortAttrName in ipairs(self.sortedAttrs) do
        local exists = false
        for _,attrName in ipairs(self.requiredAttrs) do
            if attrName == sortAttrName then
                exists = true
            end

            if exists == false then
                table.insert(self.requiredAttrs, attrName)
            end
        end
    end

    self.child:prepare(self.requiredAttrs, self)

    -- copy generated symbols
    self.symbolsMap = self.child.symbolsMap
end

function AlgebraTree.Sort:produce()
    local producerCode = self.child:produce()
    local consumerCode = self.consumer:consume(self)

    return macro(function(datastore)
        -- define vector type
        local vectorDataT = {}
        for _,attrName in ipairs(self.requiredAttrs) do
            table.insert(vectorDataT, &datastoreIUs[attrName])
        end

        local vectorDataTerraT = tuple(unpack(vectorDataT))
        self.vectorSym = symbol(Vector(vectorDataTerraT))

        local produceSymbols = macro(function(item)
            local stmts = terralib.newlist()
            local i = 0

            for _,attrName in ipairs(self.requiredAttrs) do
                local attrSym = self.symbolsMap[attrName]
                stmts:insert(quote var [attrSym] = item.["_"..i] end)
                i = i + 1
            end

            return quote [stmts] end
        end)

        local comparator = macro(function(a,b) 
            local stmts = terralib.newlist()

            local eval = symbol(int)
            stmts:insert(quote var [eval] = 0 end)

            for i,attrName in ipairs(self.requiredAttrs) do
                for _,sortAttrName in ipairs(self.sortedAttrs) do
                    if attrName == sortAttrName then

                        local multiplier = 1
                        if self.order.kind == "Descending" then
                            multiplier = -1
                        end

                        stmts:insert(quote 
                            var l = @a.["_"..(i-1)]
                            var r = @b.["_"..(i-1)]

                            var comp = l:compare(r)

                            if [eval] == 0 then
                                [eval] = multiplier * comp
                            end
                        end)
                    end
                end
            end

            return quote [stmts] in [eval] end
        end)

        local comparatorFunc = terra(a : &opaque, b : &opaque)
            var left = [&vectorDataTerraT](a)
            var right = [&vectorDataTerraT](b)
            return [comparator](left, right)
        end

        return quote
            -- declare vector
            var [self.vectorSym]
            [self.vectorSym]:init()

            -- produce values
            producerCode(datastore)

            -- sort vector
            [self.vectorSym]:sort(comparatorFunc)

            for idx = 0,[self.vectorSym]:count() do
                -- produce symbols by unpacking them from vector tuple
                var item = [self.vectorSym]:get(idx)
                [produceSymbols](item)
                consumerCode()
            end
        end
    end)
end

function AlgebraTree.Sort:consume(operator)
    return macro(function()
        local tuple = terralib.newlist()

        -- create tuple to insert in a vector
         for _,attrName in ipairs(self.requiredAttrs) do
            local attrSym = self.symbolsMap[attrName]
            tuple:insert(quote in [attrSym] end)
        end

        return quote
            -- insert tuple in vector
            [self.vectorSym]:push({[tuple]})
        end
    end)
end