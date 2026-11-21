local cloneref = cloneref or function(x) return x end
local rs = cloneref(game:GetService("ReplicatedStorage"))
local modules = rs:WaitForChild("Modules", 10)
if not modules then return end
local assetContainer = modules:FindFirstChild("AssetContainer")
if not assetContainer then return end

local getgc = getgc or get_gc
local getupvalues = debug.getupvalues or debug_getupvalues
local getconstants = debug.getconstants or debug_getconstants
local setupvalue = debug.setupvalue or debug_setupvalue
local getrawmetatable = getrawmetatable
local setrawmetatable = setrawmetatable
local setreadonly = setreadonly

if not getgc then return end

local bannedTableUpvalue = 2
local foundBypass = false

for _, obj in next, getgc(true) do
    if type(obj) == "function" and getconstants(obj) then
        local consts = getconstants(obj)
        local hasWalkSpeed = false
        for _, c in next, consts do
            if c == "WalkSpeed" then
                hasWalkSpeed = true
                break
            end
        end
        
        if hasWalkSpeed then
            local ups = getupvalues(obj)
            local banTable = ups[bannedTableUpvalue]
            
            if type(banTable) == "table" then
                local selfIdx, valIdx
                for k, v in next, banTable do
                    if type(k) == "number" then
                        if v == banTable then selfIdx = k 
                        elseif type(v) == "number" then valIdx = k end
                    end
                end
                
                if selfIdx and valIdx then
                    local rawset = rawset
                    local originalTable = table.clone(banTable)
                    
                    setmetatable(banTable, {
                        __index = originalTable,
                        __newindex = function(t, k, v)
                            if type(v) == "table" then
                                if v[5] or v[4] then return end 
                            end
                            rawset(originalTable, k, v)
                        end
                    })
                    foundBypass = true
                    break
                end
            end
        end
    end
end
