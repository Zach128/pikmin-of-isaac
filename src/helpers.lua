local helpers = {}

function helpers:ResolveTableKey(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then return k end
    end
    return nil
end

return helpers