-- Numeric
function Numeric(len, precision)
    local struct NumericT {
        value : int64
    }

    NumericT.rawType = rawstring

    terra NumericT:init(value : rawstring)
        self.value = 1
    end

    return NumericT
end