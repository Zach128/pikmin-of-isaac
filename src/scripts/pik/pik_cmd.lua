local helpers = require("scripts/helpers")
local PikBoid = require("scripts/pik/pik_boid")

local PikCmd = {}
local DebugHelpText = [[Pikmin Debug <cmd> [args]
cmd available:
* setvar - Set a debug variable
* getvar - Get a debug variable
]]
local SetVarHelpText = [[setvar <var> <val>
Available variables:
* renderPathTargets - Enable/disable path targets
]]

function PikCmd:OnCmd(cmd, args)
    -- Command module entrypoint
    if CommandIs(cmd, "pikmin") then
        local splitArgs = helpers:strSplit(args, " ")
        
        -- Command detection
        if CommandIs(splitArgs[1], "help") then
            PikCmd:Help()
        elseif CommandIs(splitArgs[1], "DEBUG") then
            PikCmd:Debug(splitArgs)
        end
    end
end

function PikCmd:Help()
    print("Pikmin <cmd> [args]")
end

function PikCmd:Debug(rawArgs)
    return BaseCmdValidate(rawArgs, 2, DebugHelpText, function (args)
        if CommandIs(args[1], "setvar") then
            PikCmd:SetVar(args)
        end
    end)
end

function PikCmd:SetVar(rawArgs)
    return BaseCmdValidate(rawArgs, 2, SetVarHelpText, function (args)
        if CommandIs(args[1], "renderPathTargets") then
            -- Enable rendering of debug targets
            
            if CommandIs(args[2], "true") then
                print("Was: " .. tostring(PikBoid.EnableDebugTargetDestinations) .. " Now: true")
                PikBoid.EnableDebugTargetDestinations = true
            elseif CommandIs(args[2], "false") then
                print("Was: " .. tostring(PikBoid.EnableDebugTargetDestinations) .. " Now: false")
                PikBoid.EnableDebugTargetDestinations = false
            else
                print("Invalid value. Valid values: true, false")
                return
            end
        end
    end)
end

function BaseCmdValidate(args, minArgs, helpText, func)
    -- Check the minimum args are available
    if #args < minArgs then
        print(helpText)
        return
    elseif minArgs > 2 and CommandIs(args[2], "help") then
        print(helpText)
        return
    end

    table.remove(args, 1)
    local parsedArgs = args

    -- Check the unpacking did not result in a string
    if type(parsedArgs) == "string" then
        parsedArgs = { parsedArgs }
    end

    -- Run the main command body
    return func(parsedArgs)
end

function CommandIs(arg, str)
    return string.upper(arg) == string.upper(str)
end

function PikCmd:InjectCallbacks(Mod)
    Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, PikCmd.OnCmd)
end

return PikCmd
