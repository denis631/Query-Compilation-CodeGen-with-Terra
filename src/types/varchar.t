-- Varchar
function Varchar(N)
    local struct VarcharT {
        value : int8[N]
        length : int
    }

    VarcharT.rawType = rawstring

    terra VarcharT:init(value : rawstring)
        C.strncpy(self.value, value, N);
        self.length = C.strnlen(value, N);
    end

    terra VarcharT:equal(value : rawstring)
        return C.strncmp(self.value, value, N) == 0
    end

    terra VarcharT:eq(other : VarcharT)
        return self:compare(other) == 0   
    end

    terra VarcharT:compare(other : VarcharT)
        return C.strncmp(self.value, other.value, N)
    end

    terra VarcharT:toString()
        return self.value
    end

    return VarcharT
end