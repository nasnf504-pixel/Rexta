local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Utility",
    Footer = "v1.0",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Visuals = Window:AddTab("Visuals", "eye"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- Вот тут создаём группу, внутри которой будут кнопки
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

local Workspace = cloneref and cloneref(workspace) or workspace
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Drawing = Drawing
local WorldToViewportPoint = Camera.WorldToViewportPoint

local ESPState = {
    Enabled = false,
    ShowNames = true,
    ShowDistance = true,
    ShowBox = true,
    ShowHealth = true,
    MaxDistance = 1000,
    Color = Color3.new(1, 0, 0),
}

local ActiveDrawings = {}

local function Cleanup()
    for _, obj in pairs(ActiveDrawings) do
        pcall(function() obj:Remove() end)
    end
    table.clear(ActiveDrawings)
end

local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetTargetData(obj, isPlayer)
    local char = obj.Character or obj
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > ESPState.MaxDistance then return end
    local screenPos, onScreen = WorldToViewportPoint(Camera, hrp.Position)
    if not onScreen then return end
    local name = isPlayer and obj.Name or (obj.Name or "NPC")
    if head then
        local headPos, headOnScreen = WorldToViewportPoint(Camera, head.Position + Vector3.new(0, 0.5, 0))
        if headOnScreen then
            local boxHeight = math.abs(screenPos.Y - headPos.Y)
            local boxWidth = boxHeight / 2
            return {
                x = screenPos.X, y = screenPos.Y, headY = headPos.Y,
                width = boxWidth, height = boxHeight, distance = dist,
                name = name, health = hum and hum.Health or 100, maxHealth = hum and hum.MaxHealth or 100
            }
        end
    end
end

local function Render()
    if not ESPState.Enabled then return end
    Cleanup()
    local drawn = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr.Character) then
            local data = GetTargetData(plr, true)
            if data then table.insert(drawn, data) end
        end
    end
    local bases = Workspace:FindFirstChild("Bases")
    if bases then
        for _, base in pairs(bases:GetChildren()) do
            for _, child in pairs(base:GetChildren()) do
                if child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                    if not Players:GetPlayerFromCharacter(child) then
                        local data = GetTargetData(child, false)
                        if data then table.insert(drawn, data) end
                    end
                end
            end
        end
    end
    local military = Workspace:FindFirstChild("Military")
    if military then
        for _, child in pairs(military:GetChildren()) do
            if child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                local data = GetTargetData(child, false)
                if data then table.insert(drawn, data) end
            end
        end
    end
    for _, data in pairs(drawn) do
        if ESPState.ShowBox then
            local box = CreateDrawing("Square", {
                Thickness = 1, Color = ESPState.Color, Filled = false, Visible = true
            })
            box.Size = Vector2.new(data.width, data.height)
            box.Position = Vector2.new(data.x - (data.width / 2), data.headY)
            table.insert(ActiveDrawings, box)
        end
        if ESPState.ShowHealth and data.maxHealth > 0 then
            local bar = CreateDrawing("Square", {
                Thickness = 1, Color = Color3.new(0, 1, 0), Filled = true, Visible = true
            })
            local barHeight = (data.health / data.maxHealth) * data.height
            bar.Size = Vector2.new(2, barHeight)
            bar.Position = Vector2.new(data.x - (data.width / 2) - 4, data.headY + (data.height - barHeight))
            table.insert(ActiveDrawings, bar)
        end
        if ESPState.ShowNames then
            local nameText = data.name
            if ESPState.ShowDistance then
                nameText = string.format("%s [%dm]", nameText, math.floor(data.distance))
            end
            local text = CreateDrawing("Text", {
                Size = 14, Center = true, Outline = true, Color = Color3.new(1, 1, 1), Visible = true, Font = 2
            })
            text.Text = nameText
            text.Position = Vector2.new(data.x, data.headY - 16)
            table.insert(ActiveDrawings, text)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if tick() - (ESPState.LastTick or 0) > 0.06 then
        Render()
        ESPState.LastTick = tick()
    end
end)

ESPGroup:AddToggle("EspToggle", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(Value)
        ESPState.Enabled = Value
        if not Value then Cleanup() end
    end
})

ESPGroup:AddToggle("EspNames", {
    Text = "Show Names",
    Default = true,
    Callback = function(Value)
        ESPState.ShowNames = Value
    end
})

ESPGroup:AddToggle("EspBox", {
    Text = "Show Boxes",
    Default = true,
    Callback = function(Value)
        ESPState.ShowBox = Value
    end
})

ESPGroup:AddSlider("EspDist", {
    Text = "Max Distance",
    Default = 1000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Callback = function(Value)
        ESPState.MaxDistance = Value
    end,
})

ESPGroup:AddLabel("Color Picker"):AddColorPicker("EspColor", {
    Default = Color3.new(1, 0, 0),
    Title = "ESP Color",
    Transparency = 0,
    Callback = function(Value)
        ESPState.Color = Value
    end,
})
