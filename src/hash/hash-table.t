nextPowerOf2 = macro(function(val)
        return quote
                var v = val - 1
                v = v or v >> 1
                v = v or v >> 2
                v = v or v >> 4
                v = v or v >> 8
                v = v or v >> 16
                v = v + 1
                in
                v
        end
end)

function equal(N)
    return macro(function(a,b)
        local stmts = terralib.newlist()
        local eq = symbol(bool)

        stmts:insert(quote var [eq] = true end)

        for i = 0,(N - 1) do
            stmts:insert(quote [eq] = [eq] and a.["_"..i]:eq(b.["_"..i]) end)
        end

        return quote [stmts] in [eq] end
    end)
end

-- Implementation of "Lazy" MultiMap Hashing with Chaining
function HashTable(KeyT, ValueT, N)
    -- HashTableT
    local struct HashTableT {
        data : &NodeT
        dataCount : uint32

        table : &&NodeT
        tableSize : uint32
    }

    local struct NodeT {
        key : KeyT
        value : ValueT
        next : &NodeT
    }

    -- HashTableT.init = terra()
    --     var map : HashTable(KeyT, ValueT)
    --     -- map.data = [&NodeT](C.malloc(sizeof(NodeT) * 20))
    --     return map
    -- end

    terra HashTableT:init()
        self.data = [&NodeT](C.malloc(sizeof(NodeT) * 150000))
        self.dataCount = 0
    end

    terra NodeT:init(key : KeyT, value : ValueT)
        self.key = key
        self.value = value
        self.next = nil
    end

    terra HashTableT:insert(key : KeyT, value : ValueT)
        var node : NodeT
        node:init(key, value)

        self.data[self.dataCount] = node
        self.dataCount = self.dataCount + 1
    end

    local Hash = macro(function(key)
            local stmts = terralib.newlist()
            local hashVal = symbol(uint32)

            stmts:insert(quote var [hashVal] = 0x9e3779b9 end)

            for i = 0,(#KeyT.entries - 1) do
                stmts:insert(quote [hashVal] = hashVal ^ key.["_"..i]:hash() end)
            end

            return quote [stmts] in [hashVal] end
    end)

    terra HashTableT:finalize()
        var numberOfEntries = self.dataCount

        self.tableSize = nextPowerOf2(numberOfEntries)
        self.table = [&&NodeT](C.malloc(sizeof(uint64) * self.tableSize))
        var tableMask = self.tableSize - 1

        for i=0,numberOfEntries do
            var elem = self.data[i]
            var idx = Hash(elem.key) and tableMask

            elem.next = self.table[idx]
            self.table[idx] = &self.data[i]
        end
    end

    -- iterator? vector of results?
    -- how can I utilize SIMD instructions?
    terra HashTableT:find(key : KeyT)
        var tableMask = self.tableSize - 1
        var idx = Hash(key) and tableMask

        var tmp = self.table[idx]

        -- return first match
        while tmp ~= nil do
            if key:equal(tmp.key) then
                return tmp
            else
                tmp = tmp.next
            end
        end

        return nil
    end

    terra KeyT:equal(other : KeyT)
       return [equal(#KeyT.entries)](self, other)
    end

    return HashTableT
end
