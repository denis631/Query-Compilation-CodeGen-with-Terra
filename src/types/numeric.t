-- Numeric
function Numeric(len, precision)
    local struct NumericT {
        value : int64
    }

    NumericT.rawType = rawstring

    terra NumericT:init(str : rawstring)
        var iter = str
        var limit = str + C.strlen(str)

        -- Trim WS
        var whitespace = [int8]((' ')[0])
        while iter ~= limit and @iter == whitespace do
            iter = iter + 1
        end

        while iter ~= limit and @(limit - 1) == whitespace do
            limit = limit - 1
        end

        -- Check for a sign
        var neg = false
        if iter ~= limit then
            if @iter == (('-')[0]) then
                neg = true
                iter = iter + 1
            elseif @iter == (('+')[0]) then
                iter = iter + 1
            end
        end

        -- Parse
        if iter == limit then
            self.value = -1
            return
        end

        var result = 0
        var fraction = false
        var digitsSeen = 0
        var digitsSeenFraction = 0

        while iter ~= limit do

            var c = @iter
            var zero = (('0')[0])

            if c >= zero and c <= (('9')[0]) then
                if fraction then
                    digitsSeenFraction = digitsSeenFraction + 1
                else
                    digitsSeen = digitsSeen + 1
                end

                result = (result * 10) + (c - zero)
            else
                while iter ~= limit and @(limit - 1) == zero do
                    limit = limit - 1
                end
            end

            iter = iter + 1
        end

        var tens = precision - digitsSeenFraction

        for i = 1,tens do
            result = result * 10
        end

        if neg then
            self.value = -result
        else
            self.value = result
        end
    end

    terra NumericT:hash()
        var r = 88172645463325252ull ^ self.value
        r = r ^ (r << 13)
        r = r ^ (r >> 7)
        return (r ^ (r << 17))
    end

    terra NumericT:toString()
        var i = 1
        var tenth = 10

        while i < precision do
            tenth = tenth * 10
            i = i + 1
        end

        var upper = self.value / tenth
        var lower = self.value % tenth

        var buffer: int8[32] -- max ?? digits (including -)
        C.sprintf(buffer, "%d.%d", upper, lower)
        return &buffer[0]
    end

    return NumericT
end
