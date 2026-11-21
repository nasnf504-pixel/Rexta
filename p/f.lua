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

local ESPObjects = {}

local function CreateObject(className, properties)
    local obj = Drawing.new(className)
    for k, v in pairs(properties) do obj[k] = v end
    return obj
end

local function DestroyObject(obj)
    if obj then
        pcall(function() obj:Remove() end)
    end
end

local function GetTargetData(char)
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not head or not hum then return nil end
    if hum.Health <= 0 then return nil end

    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > ESPState.MaxDistance then return nil end

    local screenPos, onScreen = WorldToViewportPoint(Camera, hrp.Position)
    local headPos, headOnScreen = WorldToViewportPoint(Camera, head.Position + Vector3.new(0, 0.5, 0))
    
    if not onScreen or not headOnScreen then return nil end

    local boxHeight = math.abs(screenPos.Y - headPos.Y)
    local boxWidth = boxHeight / 2

    return {
        x = screenPos.X,
        y = screenPos.Y,
        headY = headPos.Y,
        width = boxWidth,
        height = boxHeight,
        distance = dist,
        name = char.Name,
        health = hum.Health,
        maxHealth = hum.MaxHealth,
        hum = hum,
        char = char
    }
end

local function UpdateESP()
    local activeTargets = {}

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(activeTargets, plr.Character)
        end
    end

    local bases = Workspace:FindFirstChild("Bases")
    if bases then
        for _, base in pairs(bases:GetChildren()) do
            for _, child in pairs(base:GetChildren()) do
                if child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                    if not Players:GetPlayerFromCharacter(child) then
                        table.insert(activeTargets, child)
                    end
                end
            end
        end
    end

    local military = Workspace:FindFirstChild("Military")
    if military then
        for _, child in pairs(military:GetChildren()) do
            if child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                table.insert(activeTargets, child)
            end
        end
    end

    for char, data in pairs(ESPObjects) do
        if not table.find(activeTargets, char) or not ESPState.Enabled then
            DestroyObject(data.Box)
            DestroyObject(data.HealthBar)
            DestroyObject(data.NameText)
            DestroyObject(data.DistanceText)
            ESPObjects[char] = nil
        end
    end

    if not ESPState.Enabled then return end

    for _, char in pairs(activeTargets) do
        local data = GetTargetData(char)
        if data then
            if not ESPObjects[char] then
                ESPObjects[char] = {
                    Box = CreateObject("Square", { Thickness = 1, Color = ESPState.Color, Filled = false }),
                    HealthBar = CreateObject("Square", { Thickness = 1, Color = Color3.new(0, 1, 0), Filled = true }),
                    NameText = CreateObject("Text", { Size = 14, Center = true, Outline = true, Color = Color3.new(1, 1, 1), Font = 2 }),
                    DistanceText = CreateObject("Text", { Size = 12, Center = true, Outline = true, Color = Color3.new(0, 1, 0), Font = 2 })
                }
            end

            local objects = ESPObjects[char]

            if ESPState.ShowBox then
                objects.Box.Visible = true
                objects.Box.Color = ESPState.Color
                objects.Box.Size = Vector2.new(data.width, data.height)
                objects.Box.Position = Vector2.new(data.x - (data.width / 2), data.headY)
            else
                objects.Box.Visible = false
            end

            if ESPState.ShowHealth and data.maxHealth > 0 then
                objects.HealthBar.Visible = true
                local barHeight = (data.health / data.maxHealth) * data.height
                objects.HealthBar.Size = Vector2.new(2, barHeight)
                objects.HealthBar.Position = Vector2.new(data.x - (data.width / 2) - 4, data.headY + (data.height - barHeight))
            else
                objects.HealthBar.Visible = false
            end

            if ESPState.ShowNames then
                objects.NameText.Visible = true
                objects.NameText.Text = data.name
                objects.NameText.Position = Vector2.new(data.x, data.headY - 16)
            else
                objects.NameText.Visible = false
            end

            if ESPState.ShowDistance then
                objects.DistanceText.Visible = true
                objects.DistanceText.Text = string.format("[%dm]", math.floor(data.distance))
                objects.DistanceText.Position = Vector2.new(data.x, data.headY - 28)
            else
                objects.DistanceText.Visible = false
            end
        else
            if ESPObjects[char] then
                local objects = ESPObjects[char]
                if objects.Box then objects.Box.Visible = false end
                if objects.HealthBar then objects.HealthBar.Visible = false end
                if objects.NameText then objects.NameText.Visible = false end
                if objects.DistanceText then objects.DistanceText.Visible = false end
            end
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

ESPGroup:AddToggle("EspToggle", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(Value)
        ESPState.Enabled = Value
    end
})

ESPGroup:AddToggle("EspNames", {
    Text = "Show Names",
    Default = true,
    Callback = function(Value)
        ESPState.ShowNames = Value
    end
})

ESPGroup:AddToggle("EspDistance", {
    Text = "Show Distance",
    Default = true,
    Callback = function(Value)
        ESPState.ShowDistance = Value
    end
})

ESPGroup:AddToggle("EspBox", {
    Text = "Show Boxes",
    Default = true,
    Callback = function(Value)
        ESPState.ShowBox = Value
    end
})

ESPGroup:AddToggle("EspHealth", {
    Text = "Show Health",
    Default = true,
    Callback = function(Value)
        ESPState.ShowHealth = Value
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
