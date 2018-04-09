terralib.includepath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include"

C = terralib.includecstring [[
    #include <stdio.h>
    #include <stdlib.h>
]]

function projectionConsume()
    return terra(a : int)
        C.printf("%d\n", a)
    end
end

function projectionProduce()
    return selectionProduce()
end

function selectionConsume()
    local consumerCode = projectionConsume()

    return terra(a : int)
        if a % 2 == 0 then
            consumerCode(a)
        end
    end
end

function selectionProduce()
    return tableScanProduce()
end

function tableScanProduce()
    local consumerCode = selectionConsume()

    return terra(data : &int, N: int)
        for i = 0, N do
            consumerCode(data[i])
        end
    end
end

init = terra()
    var d = [&int](C.malloc(sizeof(int) * 10))

    for i = 0, 10 do
        d[i] = i
    end

    return d
end

data = init()

query = projectionProduce()
query(data, 10)
print(query)