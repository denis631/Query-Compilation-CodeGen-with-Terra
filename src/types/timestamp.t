-- Timestamp
struct Timestamp {
    value : uint64
}

Timestamp.rawType = uint64

terra Timestamp:init(value : uint64)
    self.value = value
end

terra Timestamp:hash()
    var r = 88172645463325252ull ^ self.value
    r = r ^ (r << 13)
    r = r ^ (r >> 7)
    return (r ^ (r << 17))
end

terra Timestamp:toString()
    var buffer: int8[20] -- max 20 digits
    C.sprintf(buffer, "%lld", self.value)
    return &buffer[0]
end
