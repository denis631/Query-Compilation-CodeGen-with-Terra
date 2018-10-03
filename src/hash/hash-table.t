terra nextPowerOf2(val: uint32)
    var v = val - 1
    v = v or v >> 1
    v = v or v >> 2
    v = v or v >> 4
    v = v or v >> 8
    v = v or v >> 16
    v = v + 1
    return v
end

function equal(N)
    return macro(function(a,b)
        local stmts = terralib.newlist()
        local eq = symbol(bool)

        stmts:insert(quote var [eq] = true end)

        for i = 0,(N - 1) do
            stmts:insert(quote [eq] = [eq] and (@a.["_"..i]):eq(@b.["_"..i]) end)
        end

        return quote [stmts] in [eq] end
    end)
end

-- Implementation of "Lazy" MultiMap Hashing with Chaining
function HashTable(KeyT, ValueT)
    -- NodeT
    local struct NodeT {
        key : KeyT
        value : ValueT
        next : &NodeT
    }

    -- HashTableT
    local struct HashTableT {
        data : Vector(NodeT)

        table : &&NodeT
        tableSize : uint32
    }

    -- Iterator
    local struct Iterator {
        key : KeyT
        ptr : &NodeT
    }

    terra HashTableT:init()
        self.data:init()
        self.tableSize = 0
    end

    terra NodeT:init(key : KeyT, value : ValueT)
        self.key = key
        self.value = value
        self.next = nil
    end

    terra HashTableT:insert(key : KeyT, value : ValueT)
        var node : NodeT
        node:init(key, value)

        self.data:push(node)
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
        var numberOfEntries = self.data:count()

        var tmp = nextPowerOf2(numberOfEntries)
        if tmp == 0 then
            tmp = 1
        end

        self.tableSize = tmp
        self.table = [&&NodeT](C.calloc(self.tableSize, sizeof(uint64)))
        var tableMask = self.tableSize - 1

        for i=0,numberOfEntries do
            var elem = self.data:getPtr(i)
            var idx = Hash(elem.key) and tableMask

            elem.next = self.table[idx]
            self.table[idx] = elem
        end
    end

    terra KeyT:equal(other : KeyT)
        return [equal(#KeyT.entries)](@self, other)
    end

    terra HashTableT:find(key : KeyT)
        var tableMask = self.tableSize - 1
        var idx = Hash(key) and tableMask

        -- return iterator
        return Iterator { key, self.table[idx] }
    end

    terra Iterator:hasNext()
        while self.ptr ~= nil and (not self.ptr.key:equal(self.key)) do
            self.ptr = self.ptr.next
        end

        return self.ptr ~= nil
    end

    terra Iterator:next()
        -- dereference the pointer
        var res = self.ptr

        -- point to the next item
        self.ptr = self.ptr.next

        return res
    end

    return HashTableT
end
