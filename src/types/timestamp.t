-- Timestamp
struct Timestamp {
    value : uint64
}

terra Timestamp:init(value : uint64)
    self.value = value
end