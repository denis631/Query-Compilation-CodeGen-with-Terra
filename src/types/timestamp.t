-- Timestamp
struct Timestamp {
    value : uint64
}

terra Timestamp:init(value : uint64)
    self.value = value
end

terra Timestamp:toString()
    var buffer: int8[20] -- max 20 digits
    C.sprintf(buffer, "%lld", self.value)
    return buffer
end
