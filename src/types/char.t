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

    terra CharT:toString()
        return &self.value[0]
    end

    return CharT
end
