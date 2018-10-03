-- Vector
function Vector(T)
    local struct VectorT {
        data: &T
        count: uint32
        capacity: uint32
    }

    terra VectorT:init()
        self:initWithCapacity(32)
    end

    terra VectorT:initWithCapacity(capacity : uint32)
        self.count = 0
        self.capacity = capacity
        self.data = [&T](C.calloc(self.capacity, sizeof(T)))
    end

    terra VectorT:resize()
        self.capacity = self.capacity * 2
        var tmp = [&T](C.calloc(self.capacity, sizeof(T)))

        for i = 0,self.count do
            tmp[i] = self.data[i]
        end

        C.free(self.data)
        self.data = tmp
    end

    terra VectorT:push(val : T)
        if self.count == self.capacity then
            self:resize()
        end

        self.data[self.count] = val
        self.count = self.count + 1
    end

    terra VectorT:get(idx : int)
        return self.data[idx]
    end

    terra VectorT:getPtr(idx : int)
        return self.data + idx
    end

    terra VectorT:count()
        return self.count
    end

    -- in place qsort sorting
    terra VectorT:sort(comparator : {&opaque, &opaque} -> int)
        return C.qsort(self.data, self.count, sizeof(T), comparator)
    end

    return VectorT
end
