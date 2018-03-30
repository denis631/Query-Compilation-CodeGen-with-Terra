terralib.includepath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include"

C = terralib.includecstring [[
    #include <stdio.h>
]]

local datastore = {}
datastore["users"] = { 
    {
        id=1,
        name="Denis"
    },
    {
        id=2,
        name="Denisok"
    }
}

-- TableScan
function tableScan(tableName, requiredIUs)
    local table = datastore[tableName]

    local function produce(data)
        -- The list of statements 
        local stmts = terralib.newlist()

        -- Iterate through all rows
        for _,row in ipairs(data) do

            -- Go through all required-ius
            for _,requiredIU in ipairs(requiredIUs) do

                local value = row[requiredIU]
                -- TODO: error handling if value == nil
                if not (value == nil) then
                    local stmt = quote C.printf("%d\n", value) end
                    stmts:insert(stmt)
                end
            end
        end
        
        return stmts
    end

    return terra()
        --generate the code for the body
        [ produce(table) ]
    end
end

code = tableScan("users", {"id"})
code:printpretty()
code()