require 'vector.vector'

function table.size(t)
    local c = 0
    for k,v in pairs(t) do
        c = c+1
    end
    return c
end

function copy(tab)
    local res = {}

    for key, val in pairs(tab) do
        res[key] = val
    end

    return res
end

function benchmark(f, ...)
    local reps = 1
    local s = os.clock()
    for i=1,reps do
        f(...)
    end
    local average = (os.clock() - s) / reps
    print(string.format("time: %.6f seconds\n", average))
end