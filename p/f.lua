local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Rexta",
    Footer = "v1.0",
    Icon = 10511856020,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Visuals = Window:AddTab("Visuals", "eye"),
    Combat = Window:AddTab("Combat", "crosshair"),
    Settings = Window:AddTab("Settings", "settings"),
}

local PlayerGroup = Tabs.Visuals:AddLeftGroupbox("Players")
local NodeGroup = Tabs.Visuals:AddLeftGroupbox("Ores")
local CrateGroup = Tabs.Visuals:AddLeftGroupbox("Crates & Loot")
local SilentAimGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
local AimbotGroup = Tabs.Combat:AddRightGroupbox("Aimbot")

local Workspace = cloneref and cloneref(workspace) or workspace
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
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
}

local SilentAimState = {
    Enabled = false,
    TargetPart = "Head",
    FOV = 150,
    VisibleCheck = false,
    TargetNPCs = false,
    DrawFOV = false,
}

local AimbotState = {
    Enabled = false,
    Key = "MouseButton2",
    TargetPart = "Head",
    Smoothness = 0.25,
    FOV = 150,
    DrawFOV = false,
}

local SelectedNodes = {
    ["Stone_Node"] = true,
    ["Metal_Node"] = true,
    ["Phosphate_Node"] = true,
}

local SelectedCrates = {
    ["Timed Crate"] = true,
    ["Wooden Crate"] = true,
    ["Food Crate"] = true,
    ["Locked Metal Crate"] = true,
    ["Locked Wooden Crate"] = true,
    ["Body Bag"] = true,
}

local PlayerObjects = {}
local EntityObjects = {}
local FOVCircle = nil
local AimbotFOVCircle = nil

local function CreateObject(className, properties)
    local obj = Drawing.new(className)
    for k, v in pairs(properties) do obj[k] = v end
    return obj
end

local function DestroyObject(obj)
    if obj then pcall(function() obj:Remove() end) end
end

local function SetSegment(line, p1, p2, visible, color)
    if not line then return end
    if visible and p1 and p2 then
        line.Visible = true
        line.Color = color
        line.From = p1
        line.To = p2
    else
        line.Visible = false
    end
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
                            SkelSpine = CreateObject("Line", { Thickness = 1 }),
                            SkelLUpperArm = CreateObject("Line", { Thickness = 1 }),
                            SkelLLowerArm = CreateObject("Line", { Thickness = 1 }),
                            SkelRUpperArm = CreateObject("Line", { Thickness = 1 }),
                            SkelRLowerArm = CreateObject("Line", { Thickness = 1 }),
                            SkelLLeg = CreateObject("Line", { Thickness = 1 }),
                            SkelLLowerLeg = CreateObject("Line", { Thickness = 1 }),
                            SkelRLeg = CreateObject("Line", { Thickness = 1 }),
                            SkelRLowerLeg = CreateObject("Line", { Thickness = 1 }),
                        }
                    end

                    local o = PlayerObjects[char]
                    local boxHeight = math.abs(screenPos.Y - headPos.Y)
                    local boxWidth = boxHeight / 2

                    local minHeight = 25
                    local minWidth = 12
                    if boxHeight < minHeight then
                        boxHeight = minHeight
                        boxWidth = minWidth
                    end

                    o.Box.Visible = PlayerESPState.ShowBox
                    o.Box.Color = PlayerESPState.Color
                    o.Box.Size = Vector2.new(boxWidth, boxHeight)
                    o.Box.Position = Vector2.new(screenPos.X - (boxWidth / 2), headPos.Y)

                    o.HealthBar.Visible = PlayerESPState.ShowHealth
                    local barH = (hum.Health / hum.MaxHealth) * boxHeight
                    o.HealthBar.Color = Color3.new(1 - (hum.Health/hum.MaxHealth), (hum.Health/hum.MaxHealth), 0)
                    o.HealthBar.Size = Vector2.new(2, barH)
                    o.HealthBar.Position = Vector2.new(screenPos.X - (boxWidth / 2) - 4, headPos.Y + (boxHeight - barH))

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
                    local col = PlayerESPState.Color

                    if skelVisible then
                        local h = GetBonePos(char, "Head")
                        local upperT = GetBonePos(char, "UpperTorso") or GetBonePos(char, "Torso")
                        local lowerT = GetBonePos(char, "LowerTorso") or GetBonePos(char, "HumanoidRootPart")

                        local lUpperArm = GetBonePos(char, "LeftUpperArm") or GetBonePos(char, "Left Arm")
                        local lLowerArm = GetBonePos(char, "LeftLowerArm") or GetBonePos(char, "LeftHand") or GetBonePos(char, "Left Arm")

                        local rUpperArm = GetBonePos(char, "RightUpperArm") or GetBonePos(char, "Right Arm")
                        local rLowerArm = GetBonePos(char, "RightLowerArm") or GetBonePos(char, "RightHand") or GetBonePos(char, "Right Arm")

                        local lUpperLeg = GetBonePos(char, "LeftUpperLeg") or GetBonePos(char, "Left Leg")
                        local lLowerLeg = GetBonePos(char, "LeftLowerLeg") or GetBonePos(char, "LeftFoot") or GetBonePos(char, "Left Leg")

                        local rUpperLeg = GetBonePos(char, "RightUpperLeg") or GetBonePos(char, "Right Leg")
                        local rLowerLeg = GetBonePos(char, "RightLowerLeg") or GetBonePos(char, "RightFoot") or GetBonePos(char, "Right Leg")

                        SetSegment(o.SkelHead, h, upperT, true, col)
                        SetSegment(o.SkelSpine, upperT, lowerT, true, col)
                        SetSegment(o.SkelLUpperArm, upperT, lUpperArm, true, col)
                        SetSegment(o.SkelLLowerArm, lUpperArm, lLowerArm, true, col)
                        SetSegment(o.SkelRUpperArm, upperT, rUpperArm, true, col)
                        SetSegment(o.SkelRLowerArm, rUpperArm, rLowerArm, true, col)
                        SetSegment(o.SkelLLeg, lowerT, lUpperLeg, true, col)
                        SetSegment(o.SkelLLowerLeg, lUpperLeg, lLowerLeg, true, col)
                        SetSegment(o.SkelRLeg, lowerT, rUpperLeg, true, col)
                        SetSegment(o.SkelRLowerLeg, rUpperLeg, rLowerLeg, true, col)
                    else
                        SetSegment(o.SkelHead, nil, nil, false, col)
                        SetSegment(o.SkelSpine, nil, nil, false, col)
                        SetSegment(o.SkelLUpperArm, nil, nil, false, col)
                        SetSegment(o.SkelLLowerArm, nil, nil, false, col)
                        SetSegment(o.SkelRUpperArm, nil, nil, false, col)
                        SetSegment(o.SkelRLowerArm, nil, nil, false, col)
                        SetSegment(o.SkelLLeg, nil, nil, false, col)
                        SetSegment(o.SkelLLowerLeg, nil, nil, false, col)
                        SetSegment(o.SkelRLeg, nil, nil, false, col)
                        SetSegment(o.SkelRLowerLeg, nil, nil, false, col)
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

    local nodesFolder = Workspace:FindFirstChild("Nodes")
    if nodesFolder then
        for _, child in pairs(nodesFolder:GetChildren()) do
            if child:IsA("Model") and SelectedNodes[child.Name] then
                local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
                if root then table.insert(activeEnts, {obj = child, root = root}) end
            end
        end
    end

    local basesFolder = Workspace:FindFirstChild("Bases")
    if basesFolder then
        for _, container in pairs(basesFolder:GetDescendants()) do
            if (container:IsA("Model") or container:IsA("Part")) and SelectedCrates[container.Name] then
                local root = container:FindFirstChild("HumanoidRootPart") or container:FindFirstChildWhichIsA("BasePart") or (container:IsA("Part") and container)
                if root then table.insert(activeEnts, {obj = container, root = root}) end
            end
        end
    end

    local dropsFolder = Workspace:FindFirstChild("Drops")
    if dropsFolder then
        for _, child in pairs(dropsFolder:GetChildren()) do
            if (child:IsA("Model") or child:IsA("Part")) and SelectedCrates[child.Name] then
                local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart") or (child:IsA("Part") and child)
                if root then table.insert(activeEnts, {obj = child, root = root}) end
            end
        end
    end

    for obj, data in pairs(EntityObjects) do
        local keep = false
        if EntityESPState.Enabled then
            for _, ent in pairs(activeEnts) do
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

    for _, ent in pairs(activeEnts) do
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

local function GetClosestTarget()
    local closest = nil
    local shortestDist = SilentAimState.FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(SilentAimState.TargetPart)
            if part then
                local screenPos, onScreen = WorldToViewportPoint(Camera, part.Position)
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function GetAimbotTarget()
    local closest = nil
    local shortestDist = AimbotState.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local part = plr.Character:FindFirstChild(AimbotState.TargetPart) or plr.Character:FindFirstChild("Head")
            if part and (not hum or hum.Health > 0) then
                local screenPos, onScreen = WorldToViewportPoint(Camera, part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function IsAimbotKeyHeld()
    local k = AimbotState.Key
    if k == "MouseButton2" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif k == "MouseButton1" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif k == "E" then
        return UserInputService:IsKeyDown(Enum.KeyCode.E)
    elseif k == "Q" then
        return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    end
    return false
end

local function UpdateAimbot()
    if not AimbotState.Enabled or not Camera then return end
    if not IsAimbotKeyHeld() then return end

    local targetPart = GetAimbotTarget()
    if not targetPart then return end

    local camPos = Camera.CFrame.Position
    local desiredCF = CFrame.new(camPos, targetPart.Position)
    local alpha = math.clamp(AimbotState.Smoothness, 0.01, 1)
    Camera.CFrame = Camera.CFrame:Lerp(desiredCF, alpha)
end

local function UpdateFOV()
    if not SilentAimState.DrawFOV then
        if FOVCircle then
            FOVCircle.Visible = false
        end
    else
        if not FOVCircle then
            FOVCircle = CreateObject("Circle", {
                Thickness = 1,
                NumSides = 60,
                Filled = false,
                Transparency = 0.5,
            })
        end

        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = SilentAimState.FOV

        local target = GetClosestTarget()
        if target then
            FOVCircle.Color = Color3.new(0, 0, 1)
        else
            FOVCircle.Color = Color3.new(1, 1, 1)
        end
    end

    if not AimbotState.DrawFOV then
        if AimbotFOVCircle then
            AimbotFOVCircle.Visible = false
        end
    else
        if not AimbotFOVCircle then
            AimbotFOVCircle = CreateObject("Circle", {
                Thickness = 1,
                NumSides = 60,
                Filled = false,
                Transparency = 0.5,
                Color = Color3.new(1, 0.5, 0),
            })
        end

        AimbotFOVCircle.Visible = true
        AimbotFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        AimbotFOVCircle.Radius = AimbotState.FOV
    end
end

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(t, k)
    if not checkcaller() and t == LocalPlayer and k == "GetMouse" then
        if SilentAimState.Enabled then
            local targetPart = GetClosestTarget()
            if targetPart then
                return function()
                    return {Hit = CFrame.new(targetPart.Position), Target = targetPart, UnitRay = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit)}
                end
            end
        end
    end
    return oldIndex(t, k)
end)

RunService.RenderStepped:Connect(function()
    UpdatePlayerESP()
    UpdateEntityESP()
    UpdateAimbot()
    UpdateFOV()
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

NodeGroup:AddToggle("EntEsp", { Text = "Enable Entity ESP", Default = false, Callback = function(v) EntityESPState.Enabled = v end })
NodeGroup:AddToggle("EntNames", { Text = "Show Names", Default = true, Callback = function(v) EntityESPState.ShowNames = v end })
NodeGroup:AddToggle("EntDist", { Text = "Show Distance", Default = true, Callback = function(v) EntityESPState.ShowDistance = v end })
NodeGroup:AddSlider("EntMaxDist", { Text = "Max Distance", Default = 1500, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) EntityESPState.MaxDistance = v end })
NodeGroup:AddLabel("Entity Color"):AddColorPicker("EntColor", {
    Default = Color3.new(0, 1, 1),
    Title = "Entity ESP Color",
    Callback = function(v) EntityESPState.Color = v end
})

NodeGroup:AddToggle("NodeStone", { Text = "Stone Node", Default = true, Callback = function(v) SelectedNodes["Stone_Node"] = v end })
NodeGroup:AddToggle("NodeMetal", { Text = "Metal Node", Default = true, Callback = function(v) SelectedNodes["Metal_Node"] = v end })
NodeGroup:AddToggle("NodePhosphate", { Text = "Phosphate Node", Default = true, Callback = function(v) SelectedNodes["Phosphate_Node"] = v end })

CrateGroup:AddToggle("CrateTimed", { Text = "Timed Crate", Default = true, Callback = function(v) SelectedCrates["Timed Crate"] = v end })
CrateGroup:AddToggle("CrateWooden", { Text = "Wooden Crate", Default = true, Callback = function(v) SelectedCrates["Wooden Crate"] = v end })
CrateGroup:AddToggle("CrateFood", { Text = "Food Crate", Default = true, Callback = function(v) SelectedCrates["Food Crate"] = v end })
CrateGroup:AddToggle("CrateLockedMetal", { Text = "Locked Metal Crate", Default = true, Callback = function(v) SelectedCrates["Locked Metal Crate"] = v end })
CrateGroup:AddToggle("CrateLockedWood", { Text = "Locked Wooden Crate", Default = true, Callback = function(v) SelectedCrates["Locked Wooden Crate"] = v end })
CrateGroup:AddToggle("CrateBodyBag", { Text = "Body Bag", Default = true, Callback = function(v) SelectedCrates["Body Bag"] = v end })

SilentAimGroup:AddToggle("SilentAim", { Text = "Enable Silent Aim", Default = false, Callback = function(v) SilentAimState.Enabled = v end })
SilentAimGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = false, Callback = function(v) SilentAimState.DrawFOV = v end })
SilentAimGroup:AddDropdown("AimPart", {
    Text = "Target Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"},
    Default = "Head",
    Multi = false,
    Callback = function(v) SilentAimState.TargetPart = v end
})
SilentAimGroup:AddSlider("AimFOV", {
    Text = "FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v) SilentAimState.FOV = v end
})

AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enable Aimbot", Default = false, Callback = function(v) AimbotState.Enabled = v end })
AimbotGroup:AddToggle("AimbotDrawFOV", { Text = "Draw Aimbot FOV", Default = false, Callback = function(v) AimbotState.DrawFOV = v end })
AimbotGroup:AddDropdown("AimbotKey", {
    Text = "Aimbot Key",
    Values = {"MouseButton2", "MouseButton1", "E", "Q"},
    Default = "MouseButton2",
    Multi = false,
    Callback = function(v) AimbotState.Key = v end
})
AimbotGroup:AddDropdown("AimbotPart", {
    Text = "Target Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"},
    Default = "Head",
    Multi = false,
    Callback = function(v) AimbotState.TargetPart = v end
})
AimbotGroup:AddSlider("AimbotFOV", {
    Text = "Aimbot FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v) AimbotState.FOV = v end
})
AimbotGroup:AddSlider("AimbotSmooth", {
    Text = "Smoothness",
    Default = 25,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(v) AimbotState.Smoothness = v / 100 end
})
