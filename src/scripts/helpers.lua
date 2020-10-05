local helpers = {}

function helpers:ResolveTableKey(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then return k end
    end
    return nil
end

function helpers:strSplit (inputstr, sep)
    -- Split a string by a given separator substring.

    -- Default to whitespace if the separator is nil.
    if sep == nil then
            sep = "%s"
    end

    local t={}
    
    for str in string.gmatch(inputstr, "(%g+)") do
            table.insert(t, str)
    end
    return t
end

return helpers