local repo = "https://raw.githubusercontent.com/nasnf504-pixel/Rexta/main/"
local req = request or http_request

if not req then return end

local function fetch(f)
    local s, r = pcall(req, {Url = repo .. f, Method = "GET"})
    if s and type(r) == "table" and r.StatusCode == 200 then
        return r.Body
    end
end

local c_code = fetch("c.lua")
if not c_code then return end

local c_fn = loadstring(c_code)
if c_fn and c_fn() then
    local i_code = fetch("p/i.lua")
    if i_code then
        local i_fn = loadstring(i_code)
        if i_fn then pcall(i_fn) end
    end
end
