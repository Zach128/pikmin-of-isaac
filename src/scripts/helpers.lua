local Helpers = {}

function Helpers:ResolveTableKey(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then return k end
    end
    return nil
end

function Helpers:strSplit (inputstr, sep)
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

-- Higher-order iterator for boid calculations which iterates over every element NOT equal to the given filter.
function Helpers:NotEqualIterator(target,arr)
    local index = 0
    local count = #arr -- Get the total length of the collection.

    return function ()
        index = index + 1
        
        -- If we still have elements left to iterate over
        if index <= count then
            -- If the element is not equal to the filter value, return it.
            if arr[index] ~= target then
                return arr[index], index
            -- If the element matches, and there are still elements after this one to loop over,
            -- increment and return the element.
            elseif arr[index] == target and index < count then
                index = index + 1
                return arr[index], index
            end
        end
    end
end

return Helpers