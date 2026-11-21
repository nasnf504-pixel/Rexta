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

local PlayerGroup = Tabs.Visuals:AddLeftGroupbox("Players")
local EntityGroup = Tabs.Visuals:AddLeftGroupbox("Entities")

local Workspace = cloneref and cloneref(workspace) or workspace
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Drawing = Drawing
local WorldToViewportPoint = Camera.WorldToViewportPoint

local PlayerESPState = {
    Enabled = false,
    ShowNames = true,
    ShowDistance = true,
    ShowBox = true,
    ShowHealth = true,
    ShowTracers = false,
    ShowSkeleton = false,
    MaxDistance = 1000,
    Color = Color3.new(1, 0, 0),
}

local EntityESPState = {
    Enabled = false,
    ShowNames = true,
    ShowDistance = true,
    MaxDistance = 1500,
    Color = Color3.new(0, 1, 1),
    Items = {
        ["Weapon Crate"] = true,
        ["Airdrop"] = true,
        ["Timed Crate"] = true,
        ["Body Bag"] = true,
        ["Minicopter"] = true,
        ["Hemp"] = true,
        ["Metal"] = true,
        ["Stone"] = true,
        ["Phosphate"] = true
    }
}

local PlayerObjects = {}
local EntityObjects = {}

local function CreateObject(className, properties)
    local obj = Drawing.new(className)
    for k, v in pairs(properties) do obj[k] = v end
    return obj
end

local function DestroyObject(obj)
    if obj then pcall(function() obj:Remove() end) end
end

local function GetBonePos(char, boneName)
    local part = char:FindFirstChild(boneName)
    if part then
        local screen, onScreen = WorldToViewportPoint(Camera, part.Position)
        if onScreen then return Vector2.new(screen.X, screen.Y) end
    end
    return nil
end

local function UpdatePlayerESP()
    local activeTargets = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(activeTargets, plr.Character)
        end
    end

    for char, data in pairs(PlayerObjects) do
        local keep = false
        if PlayerESPState.Enabled then
            for _, activeChar in pairs(activeTargets) do
                if activeChar == char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and (Camera.CFrame.Position - hrp.Position).Magnitude <= PlayerESPState.MaxDistance then
                        keep = true
                        break
                    end
                end
            end
        end
        if not keep then
            for _, obj in pairs(data) do DestroyObject(obj) end
            PlayerObjects[char] = nil
        end
    end

    if not PlayerESPState.Enabled then return end

    for _, char in pairs(activeTargets) do
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if hrp and hum and hum.Health > 0 and head then
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist <= PlayerESPState.MaxDistance then
                local screenPos, onScreen = WorldToViewportPoint(Camera, hrp.Position)
                local headPos, headOnScreen = WorldToViewportPoint(Camera, head.Position + Vector3.new(0, 0.5, 0))
                
                if onScreen and headOnScreen then
                    if not PlayerObjects[char] then
                        PlayerObjects[char] = {
                            Box = CreateObject("Square", { Thickness = 1, Filled = false }),
                            HealthBar = CreateObject("Square", { Thickness = 1, Filled = true }),
                            NameText = CreateObject("Text", { Size = 14, Center = true, Outline = true, Font = 2 }),
                            DistText = CreateObject("Text", { Size = 12, Center = true, Outline = true, Font = 2 }),
                            Tracer = CreateObject("Line", { Thickness = 1 }),
                            SkelHead = CreateObject("Line", { Thickness = 1 }),
                            SkelTorso = CreateObject("Line", { Thickness = 1 }),
                            SkelL1 = CreateObject("Line", { Thickness = 1 }),
                            SkelL2 = CreateObject("Line", { Thickness = 1 }),
                            SkelR1 = CreateObject("Line", { Thickness = 1 }),
                            SkelR2 = CreateObject("Line", { Thickness = 1 }),
                        }
                    end

                    local o = PlayerObjects[char]
                    local boxHeight = math.abs(screenPos.Y - headPos.Y)
                    local boxWidth = boxHeight / 2

                    o.Box.Visible = PlayerESPState.ShowBox
                    o.Box.Color = PlayerESPState.Color
                    o.Box.Size = Vector2.new(boxWidth, boxHeight)
                    o.Box.Position = Vector2.new(screenPos.X - boxWidth/2, headPos.Y)

                    o.HealthBar.Visible = PlayerESPState.ShowHealth
                    local barH = (hum.Health / hum.MaxHealth) * boxHeight
                    o.HealthBar.Color = Color3.new(1 - (hum.Health/hum.MaxHealth), (hum.Health/hum.MaxHealth), 0)
                    o.HealthBar.Size = Vector2.new(2, barH)
                    o.HealthBar.Position = Vector2.new(screenPos.X - boxWidth/2 - 4, headPos.Y + (boxHeight - barH))

                    o.NameText.Visible = PlayerESPState.ShowNames
                    o.NameText.Color = PlayerESPState.Color
                    o.NameText.Text = char.Name
                    o.NameText.Position = Vector2.new(screenPos.X, headPos.Y - 16)

                    o.DistText.Visible = PlayerESPState.ShowDistance
                    o.DistText.Color = Color3.new(1,1,1)
                    o.DistText.Text = string.format("[%dm]", math.floor(dist))
                    o.DistText.Position = Vector2.new(screenPos.X, headPos.Y - 28)

                    o.Tracer.Visible = PlayerESPState.ShowTracers
                    o.Tracer.Color = PlayerESPState.Color
                    o.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    o.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)

                    local skelVisible = PlayerESPState.ShowSkeleton
                    for _, skel in pairs({o.SkelHead, o.SkelTorso, o.SkelL1, o.SkelL2, o.SkelR1, o.SkelR2}) do
                        skel.Visible = skelVisible
                        skel.Color = PlayerESPState.Color
                    end

                    if skelVisible then
                        local h = GetBonePos(char, "Head")
                        local t = GetBonePos(char, "UpperTorso") or GetBonePos(char, "Torso")
                        local la = GetBonePos(char, "LeftUpperArm") or GetBonePos(char, "Left Arm")
                        local ra = GetBonePos(char, "RightUpperArm") or GetBonePos(char, "Right Arm")
                        local ll = GetBonePos(char, "LeftLowerArm") or GetBonePos(char, "Left Arm")
                        local rl = GetBonePos(char, "RightLowerArm") or GetBonePos(char, "Right Arm")

                        if h and t then o.SkelHead.From = h; o.SkelHead.To = t end
                        if la and t then o.SkelTorso.From = t; o.SkelTorso.To = la end
                        if la and ll then o.SkelL1.From = la; o.SkelL1.To = ll end
                        if ra and t then o.SkelR1.From = t; o.SkelR1.To = ra end
                        if ra and rl then o.SkelR2.From = ra; o.SkelR2.To = rl end
                    end
                else
                    if PlayerObjects[char] then
                        for _, obj in pairs(PlayerObjects[char]) do obj.Visible = false end
                    end
                end
            end
        end
    end
end

local function UpdateEntityESP()
    local activeEnts = {}
    local containers = {Workspace:FindFirstChild("Drops"), Workspace:FindFirstChild("Nodes")}
    
    for _, container in pairs(containers) do
        if container then
            for _, child in pairs(container:GetChildren()) do
                if child:IsA("Model") or child:IsA("Part") then
                    local root = child:FindFirstChild("HumanoidRootPart") or (child:IsA("Part") and child) or child:FindFirstChildWhichIsA("BasePart")
                    if root then
                        table.insert(activeEnts, {obj = child, root = root})
                    end
                end
            end
        end
    end

    local visibleEnts = {}
    for _, ent in pairs(activeEnts) do
        local isTarget = false
        for name, enabled in pairs(EntityESPState.Items) do
            if enabled and string.find(string.lower(ent.obj.Name), string.lower(name)) then
                isTarget = true
                break
            end
        end
        if isTarget then table.insert(visibleEnts, ent) end
    end

    for obj, data in pairs(EntityObjects) do
        local keep = false
        if EntityESPState.Enabled then
            for _, ent in pairs(visibleEnts) do
                if ent.obj == obj and (Camera.CFrame.Position - ent.root.Position).Magnitude <= EntityESPState.MaxDistance then
                    keep = true
                    break
                end
            end
        end
        if not keep then
            DestroyObject(data.Text)
            EntityObjects[obj] = nil
        end
    end

    if not EntityESPState.Enabled then return end

    for _, ent in pairs(visibleEnts) do
        local dist = (Camera.CFrame.Position - ent.root.Position).Magnitude
        if dist <= EntityESPState.MaxDistance then
            local screen, onScreen = WorldToViewportPoint(Camera, ent.root.Position)
            if onScreen then
                if not EntityObjects[ent.obj] then
                    EntityObjects[ent.obj] = {
                        Text = CreateObject("Text", { Size = 13, Center = true, Outline = true, Font = 2 })
                    }
                end
                local o = EntityObjects[ent.obj]
                o.Text.Visible = true
                o.Text.Color = EntityESPState.Color
                local txt = ent.obj.Name
                if EntityESPState.ShowDistance then txt = txt .. string.format(" [%dm]", math.floor(dist)) end
                o.Text.Text = txt
                o.Text.Position = Vector2.new(screen.X, screen.Y)
            else
                if EntityObjects[ent.obj] then EntityObjects[ent.obj].Text.Visible = false end
            end
        else
            if EntityObjects[ent.obj] then EntityObjects[ent.obj].Text.Visible = false end
        end
    end
end

RunService.RenderStepped:Connect(function()
    UpdatePlayerESP()
    UpdateEntityESP()
end)

PlayerGroup:AddToggle("PlayerEsp", { Text = "Enable Player ESP", Default = false, Callback = function(v) PlayerESPState.Enabled = v end })
PlayerGroup:AddToggle("PlayerNames", { Text = "Show Names", Default = true, Callback = function(v) PlayerESPState.ShowNames = v end })
PlayerGroup:AddToggle("PlayerDist", { Text = "Show Distance", Default = true, Callback = function(v) PlayerESPState.ShowDistance = v end })
PlayerGroup:AddToggle("PlayerBox", { Text = "Show Boxes", Default = true, Callback = function(v) PlayerESPState.ShowBox = v end })
PlayerGroup:AddToggle("PlayerHealth", { Text = "Show Health", Default = true, Callback = function(v) PlayerESPState.ShowHealth = v end })
PlayerGroup:AddToggle("PlayerTracers", { Text = "Show Tracers", Default = false, Callback = function(v) PlayerESPState.ShowTracers = v end })
PlayerGroup:AddToggle("PlayerSkel", { Text = "Show Skeleton", Default = false, Callback = function(v) PlayerESPState.ShowSkeleton = v end })
PlayerGroup:AddSlider("PlayerMaxDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) PlayerESPState.MaxDistance = v end })
PlayerGroup:AddLabel("ESP Color"):AddColorPicker("PlayerColor", {
    Default = Color3.new(1, 0, 0),
    Title = "Player ESP Color",
    Callback = function(v) PlayerESPState.Color = v end
})

EntityGroup:AddToggle("EntEsp", { Text = "Enable Entity ESP", Default = false, Callback = function(v) EntityESPState.Enabled = v end })
EntityGroup:AddToggle("EntNames", { Text = "Show Names", Default = true, Callback = function(v) EntityESPState.ShowNames = v end })
EntityGroup:AddToggle("EntDist", { Text = "Show Distance", Default = true, Callback = function(v) EntityESPState.ShowDistance = v end })
EntityGroup:AddSlider("EntMaxDist", { Text = "Max Distance", Default = 1500, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) EntityESPState.MaxDistance = v end })
EntityGroup:AddLabel("Entity Color"):AddColorPicker("EntColor", {
    Default = Color3.new(0, 1, 1),
    Title = "Entity ESP Color",
    Callback = function(v) EntityESPState.Color = v end
})

EntityGroup:AddDropdown("EntItemsDropdown", {
    Text = "Select Items",
    Values = {"Weapon Crate", "Airdrop", "Timed Crate", "Body Bag", "Minicopter", "Hemp", "Metal", "Stone", "Phosphate"},
    Default = {"Weapon Crate", "Airdrop", "Timed Crate", "Body Bag", "Minicopter", "Hemp", "Metal", "Stone", "Phosphate"},
    Multi = true,
    Callback = function(Values)
        for k, v in pairs(EntityESPState.Items) do
            EntityESPState.Items[k] = false
        end
        for _, v in pairs(Values) do
            if EntityESPState.Items[v] ~= nil then
                EntityESPState.Items[v] = true
            end
        end
    end
})
