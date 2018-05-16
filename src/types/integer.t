-- Integer
struct Integer {
    value : int32
}

Integer.rawType = int32

terra Integer:init(value : int32)
    self.value = value
end

terra Integer:toString()
    var buffer: int8[10] -- max 11 digits (including -)
    C.sprintf(buffer, "%d", self.value)
    return buffer
end

terra Integer:equal(other : int32)
  return self.value == other
end

terra Integer:eq(other : Integer)
    return self:compare(other) == 0
end

terra Integer:compare(other: Integer)
    return self.value - other.value
end

terra Integer:hash()
    var r = 88172645463325252ull ^ self.value
    r = r ^ (r << 13)
    r = r ^ (r >> 7)
    return (r ^ (r << 17))
end