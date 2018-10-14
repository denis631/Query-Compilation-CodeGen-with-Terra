-- Char
function Char(N)
    local struct CharT {
        value : int8[N]
        length : int
    }

    CharT.rawType = rawstring

    terra CharT:init(value : rawstring)
        C.memcpy(&self.value, value, N);
        self.length = C.strnlen(self.value, N);
    end

    terra CharT:equal(value : rawstring)
        return C.strncmp(self.value, value, N) == 0
    end

    terra CharT:eq(other : CharT)
        return self:compare(other) == 0   
    end

    terra CharT:compare(other : CharT)
        return C.strncmp(self.value, other.value, N)
    end

    terra CharT:toString()
        return &self.value[0]
    end

    return CharT
end
