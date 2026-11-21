local repo = "https://raw.githubusercontent.com/nasnf504-pixel/Rexta/main/"
local req = request or http_request

local function loadModule(file)
    local s, r = pcall(req, {Url = repo .. "p/" .. file, Method = "GET"})
    if s and type(r) == "table" and r.StatusCode == 200 then
        local f = loadstring(r.Body)
        if f then
            local suc, err = pcall(f)
            if not suc then warn("Err " .. file .. ": " .. tostring(err)) end
            return suc
        end
    end
    return false
end

local cloneref = cloneref or function(x) return x end
local Players = cloneref(game:GetService("Players"))
local LP = Players.LocalPlayer
if not LP then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

if loadModule("o.lua") then
    if loadModule("b.lua") then
        loadModule("f.lua")
    end
end
