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

-- Implementation of "Lazy" MultiMap Hashing with Chaining
function HashTable(KeyT, ValueT, N)
    -- HashTableT
    local struct HashTableT {
        data : &NodeT
        dataCount : uint32

        hash_table_ : &&NodeT
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
        self.data = [&NodeT](C.malloc(sizeof(NodeT) * 20))
    end

    terra NodeT:init(key : KeyT, value : ValueT)
        self.key = key
        self.value = value
    end

    terra HashTableT:insert(key : KeyT, value : ValueT)
        var node : NodeT
        node:init(key, value)

        self.data[self.dataCount] = node
        self.dataCount = self.dataCount + 1
    end

    local Hash = macro(function(key)
            return quote
                    in
                    1
                   end
    end)

    terra HashTableT:finalize()
        var numberOfEntries = self.dataCount

        self.tableSize = nextPowerOf2(numberOfEntries)
        self.hash_table_ = [&&NodeT](C.malloc(sizeof(uint64) * self.tableSize))
        var tableMask = self.tableSize - 1

        for i=0,numberOfEntries do
            var elem = self.data[i]
            var idx = Hash(elem.key) and tableMask

            elem.next = self.hash_table_[idx]
            self.hash_table_[idx] = &self.data[i]
        end
    end

    -- iterator? vector of results?
    -- how can I utilize SIMD instructions?
    terra HashTableT:find(key : KeyT)
        var tableMask = self.tableSize - 1
        var idx = Hash(key) and tableMask

        var tmp = self.hash_table_[idx]

        -- return first match
        if tmp ~= nil then
            return &tmp.value
        else
            return nil
        end
    end

    return HashTableT
end
