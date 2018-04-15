-- Integer
struct Integer {
    value : int32
}

terra Integer:init(value : int32)
    self.value = value
end

terra Integer:toString()
    var buffer: int8[10] -- max 11 digits (including -)
    C.sprintf(buffer, "%d", self.value)
    return buffer
end
