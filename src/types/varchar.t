-- Varchar
function Varchar(N)
    local struct VarcharT {
        value : int8[N]
        length : int
    }

    terra VarcharT:init(value : rawstring)
        C.strncpy(self.value, value, N);
        self.length = C.strnlen(value, N);
    end

    return VarcharT
end
