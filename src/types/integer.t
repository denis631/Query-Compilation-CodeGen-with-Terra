-- Integer
struct Integer {
    value : int32
}

terra Integer:init(value : int32)
    self.value = value
end