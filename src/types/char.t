-- Char
function Char(N)
    local struct CharT {
        value : int8[N]
        length : int
    }

    terra CharT:init(value : rawstring)
        C.memcpy(&self.value, value, N);
        self.length = C.strnlen(self.value, N);
    end

    return CharT
end