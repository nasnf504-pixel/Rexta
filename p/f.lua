local Workspace = cloneref and cloneref(workspace) or workspace
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Drawing = Drawing
local Vector2 = Vector2.new
local Color3 = Color3.new
local WorldToViewportPoint = Camera.WorldToViewportPoint

local ESP = {
    Players = {},
    NPCs = {},
    Objects = {},
    Settings = {
        Enabled = true,
        TeamCheck = true,
        ShowNames = true,
        ShowDistance = true,
        ShowBox = true,
        ShowHealth = true,
        MaxDistance = 1000,
        Color = Color3.fromRGB(255, 0, 0),
        TextColor = Color3.fromRGB(255, 255, 255)
    }
}

local function CreateDrawing(class, properties)
    local obj = Drawing.new(class)
    for k, v in pairs(properties) do
        obj[k] = v
    end
    return obj
end

local function CleanupDrawing(tbl)
    for _, v in pairs(tbl) do
        if v.Remove then
            pcall(function() v:Remove() end)
        end
    end
end

local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function IsTeammate(plr)
    if not ESP.Settings.TeamCheck or plr == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = plr.Team
    if myTeam and theirTeam and myTeam == theirTeam then
        return true
    end
    return false
end

local function GetTargetData(obj, isPlayer)
    local char = obj.Character or obj
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    if not hrp then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    
    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > ESP.Settings.MaxDistance then return end

    local screenPos, onScreen = WorldToViewportPoint(Camera, hrp.Position)
    if not onScreen then return end

    local name = isPlayer and obj.Name or (obj.Name or "NPC")
    
    if head then
        local headPos, headOnScreen = WorldToViewportPoint(Camera, head.Position + Vector3.new(0, 0.5, 0))
        if headOnScreen then
            local boxHeight = math.abs(screenPos.Y - headPos.Y)
            local boxWidth = boxHeight / 2
            return {
                x = screenPos.X,
                y = screenPos.Y,
                headY = headPos.Y,
                width = boxWidth,
                height = boxHeight,
                distance = dist,
                name = name,
                health = hum and hum.Health or 100,
                maxHealth = hum and hum.MaxHealth or 100
            }
        end
    end
end

local function RenderESP()
    if not ESP.Settings.Enabled then return end
    
    local currentTime = tick()
    if ESP._lastRender and currentTime - ESP._lastRender < 0.05 then return end
    ESP._lastRender = currentTime

    local drawn = {}

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not IsTeammate(plr) and IsAlive(plr.Character) then
            local data = GetTargetData(plr, true)
            if data then
                table.insert(drawn, data)
            end
        end
    end

    local bases = Workspace:FindFirstChild("Bases")
    if bases then
        for _, base in pairs(bases:GetChildren()) do
            for _, child in pairs(base:GetChildren()) do
                if child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") and child.Name ~= LocalPlayer.Name then
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
        if ESP.Settings.ShowBox then
            local box = CreateDrawing("Square", {
                Thickness = 1,
                Color = ESP.Settings.Color,
                Filled = false,
                Visible = true
            })
            box.Size = Vector2.new(data.width, data.height)
            box.Position = Vector2.new(data.x - (data.width / 2), data.headY)
            
            table.insert(ESP.Objects, box)
        end

        if ESP.Settings.ShowHealth and data.maxHealth > 0 then
            local bar = CreateDrawing("Square", {
                Thickness = 1,
                Color = Color3.fromRGB(0, 255, 0),
                Filled = true,
                Visible = true
            })
            local barHeight = (data.health / data.maxHealth) * data.height
            bar.Size = Vector2.new(2, barHeight)
            bar.Position = Vector2.new(data.x - (data.width / 2) - 4, data.headY + (data.height - barHeight))
            
            table.insert(ESP.Objects, bar)
        end

        if ESP.Settings.ShowNames then
            local nameText = data.name
            if ESP.Settings.ShowDistance then
                nameText = string.format("%s [%dm]", nameText, math.floor(data.distance))
            end
            
            local text = CreateDrawing("Text", {
                Size = 14,
                Center = true,
                Outline = true,
                Color = ESP.Settings.TextColor,
                Visible = true,
                Font = 2
            })
            text.Text = nameText
            text.Position = Vector2.new(data.x, data.headY - 16)
            
            table.insert(ESP.Objects, text)
        end
    end

    task.spawn(function()
        task.wait(0.06)
        for _, obj in pairs(ESP.Objects) do
            pcall(function() obj:Remove() end)
        end
        table.clear(ESP.Objects)
    end)
end

RunService.RenderStepped:Connect(RenderESP)
