local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()[cite: 7]

local Window = Library:CreateWindow({
    Title = "Rexta",
    Footer = "v1.0",
    Icon = 10511856020,
    NotifySide = "Right",
    ShowCustomCursor = false,
})[cite: 7]

local Tabs = {
    Visuals = Window:AddTab("Visuals", "eye"),
    Combat = Window:AddTab("Combat", "crosshair"),
    Settings = Window:AddTab("Settings", "settings"),
}[cite: 7]

local PlayerGroup = Tabs.Visuals:AddLeftGroupbox("Players")[cite: 7]
local NodeGroup = Tabs.Visuals:AddLeftGroupbox("Ores")[cite: 7]
local CrateGroup = Tabs.Visuals:AddLeftGroupbox("Crates & Loot")[cite: 7]
local SilentAimGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")[cite: 7]
local AimbotGroup = Tabs.Combat:AddRightGroupbox("Aimbot")[cite: 7]

local Workspace = cloneref and cloneref(workspace) or workspace[cite: 7]
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")[cite: 7]
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")[cite: 7]
local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")[cite: 7]
local Camera = Workspace.CurrentCamera[cite: 7]
local LocalPlayer = Players.LocalPlayer[cite: 7]
local Drawing = Drawing[cite: 7]
local WorldToViewportPoint = Camera.WorldToViewportPoint[cite: 7]

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
}[cite: 7]

local EntityESPState = {
    Enabled = false,
    ShowNames = true,
    ShowDistance = true,
    MaxDistance = 1500,
    Color = Color3.new(0, 1, 1),
}[cite: 7]

local SilentAimState = {
    Enabled = false,
    TargetPart = "Head",
    FOV = 150,
    VisibleCheck = false,
    TargetNPCs = false,
    DrawFOV = false,
}[cite: 7]

local AimbotState = {
    Enabled = false,
    TargetPart = "Head",
    Smoothness = 0.25,
    FOV = 150,
    DrawFOV = false,
    PickerValue = "MB2",
    MouseOverride = "None",
    DirectKeyHeld = false,
    DirectMouseHeld = nil,
}[cite: 7]

local AimbotKeyPicker = nil[cite: 7]

local SelectedNodes = {
    ["Stone_Node"] = true,
    ["Metal_Node"] = true,
    ["Phosphate_Node"] = true,
}[cite: 7]

local SelectedCrates = {
    ["Timed Crate"] = true,
    ["Wooden Crate"] = true,
    ["Food Crate"] = true,
    ["Locked Metal Crate"] = true,
    ["Locked Wooden Crate"] = true,
    ["Body Bag"] = true,
}[cite: 7]

local PlayerObjects = {}[cite: 7]
local EntityObjects = {}[cite: 7]
local FOVCircle = nil[cite: 7]
local AimbotFOVCircle = nil[cite: 7]

local function CreateObject(className, properties)
    local obj = Drawing.new(className)[cite: 7]
    for k, v in pairs(properties) do obj[k] = v end[cite: 7]
    return obj[cite: 7]
end[cite: 7]

local function DestroyObject(obj)
    if obj then pcall(function() obj:Remove() end) end[cite: 7]
end[cite: 7]

local function SetSegment(line, p1, p2, visible, color)
    if not line then return end[cite: 7]
    if visible and p1 and p2 then
        line.Visible = true[cite: 7]
        line.Color = color[cite: 7]
        line.From = p1[cite: 7]
        line.To = p2[cite: 7]
    else
        line.Visible = false[cite: 7]
    end
end[cite: 7]

local function GetBonePos(char, boneName)
    local part = char:FindFirstChild(boneName)[cite: 7]
    if part then
        local screen, onScreen = WorldToViewportPoint(Camera, part.Position)[cite: 7]
        if onScreen then return Vector2.new(screen.X, screen.Y) end[cite: 7]
    end
    return nil[cite: 7]
end[cite: 7]

local function UpdatePlayerESP()
    local activeTargets = {}[cite: 7]
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(activeTargets, plr.Character)[cite: 7]
        end
    end

    for char, data in pairs(PlayerObjects) do
        local keep = false[cite: 7]
        if PlayerESPState.Enabled then
            for _, activeChar in pairs(activeTargets) do
                if activeChar == char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")[cite: 7]
                    if hrp and (Camera.CFrame.Position - hrp.Position).Magnitude <= PlayerESPState.MaxDistance then
                        keep = true[cite: 7]
                        break[cite: 7]
                    end
                end
            end
        end
        if not keep then
            for _, obj in pairs(data) do DestroyObject(obj) end[cite: 7]
            PlayerObjects[char] = nil[cite: 7]
        end
    end

    if not PlayerESPState.Enabled then return end[cite: 7]

    for _, char in pairs(activeTargets) do
        local hrp = char:FindFirstChild("HumanoidRootPart")[cite: 7]
        local hum = char:FindFirstChildOfClass("Humanoid")[cite: 7]
        local head = char:FindFirstChild("Head")[cite: 7]
        if hrp and hum and hum.Health > 0 and head then
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude[cite: 7]
            if dist <= PlayerESPState.MaxDistance then
                local screenPos, onScreen = WorldToViewportPoint(Camera, hrp.Position)[cite: 7]
                local headPos, headOnScreen = WorldToViewportPoint(Camera, head.Position + Vector3.new(0, 0.5, 0))[cite: 7]

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
                        }[cite: 7]
                    end

                    local o = PlayerObjects[char][cite: 7]
                    local boxHeight = math.abs(screenPos.Y - headPos.Y)[cite: 7]
                    local boxWidth = boxHeight / 2[cite: 7]

                    local minHeight = 25[cite: 7]
                    local minWidth = 12[cite: 7]
                    if boxHeight < minHeight then
                        boxHeight = minHeight[cite: 7]
                        boxWidth = minWidth[cite: 7]
                    end

                    o.Box.Visible = PlayerESPState.ShowBox[cite: 7]
                    o.Box.Color = PlayerESPState.Color[cite: 7]
                    o.Box.Size = Vector2.new(boxWidth, boxHeight)[cite: 7]
                    o.Box.Position = Vector2.new(screenPos.X - (boxWidth / 2), headPos.Y)[cite: 7]

                    o.HealthBar.Visible = PlayerESPState.ShowHealth[cite: 7]
                    local barH = (hum.Health / hum.MaxHealth) * boxHeight[cite: 7]
                    o.HealthBar.Color = Color3.new(1 - (hum.Health/hum.MaxHealth), (hum.Health/hum.MaxHealth), 0)[cite: 7]
                    o.HealthBar.Size = Vector2.new(2, barH)[cite: 7]
                    o.HealthBar.Position = Vector2.new(screenPos.X - (boxWidth / 2) - 4, headPos.Y + (boxHeight - barH))[cite: 7]

                    o.NameText.Visible = PlayerESPState.ShowNames[cite: 7]
                    o.NameText.Color = PlayerESPState.Color[cite: 7]
                    o.NameText.Text = char.Name[cite: 7]
                    o.NameText.Position = Vector2.new(screenPos.X, headPos.Y - 16)[cite: 7]

                    o.DistText.Visible = PlayerESPState.ShowDistance[cite: 7]
                    o.DistText.Color = Color3.new(1,1,1)[cite: 7]
                    o.DistText.Text = string.format("[%dm]", math.floor(dist))[cite: 7]
                    o.DistText.Position = Vector2.new(screenPos.X, headPos.Y - 28)[cite: 7]

                    o.Tracer.Visible = PlayerESPState.ShowTracers[cite: 7]
                    o.Tracer.Color = PlayerESPState.Color[cite: 7]
                    o.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)[cite: 7]
                    o.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)[cite: 7]

                    local skelVisible = PlayerESPState.ShowSkeleton[cite: 7]
                    local col = PlayerESPState.Color[cite: 7]

                    if skelVisible then
                        local h = GetBonePos(char, "Head")[cite: 7]
                        local upperT = GetBonePos(char, "UpperTorso") or GetBonePos(char, "Torso")[cite: 7]
                        local lowerT = GetBonePos(char, "LowerTorso") or GetBonePos(char, "HumanoidRootPart")[cite: 7]

                        local lUpperArm = GetBonePos(char, "LeftUpperArm") or GetBonePos(char, "Left Arm")[cite: 7]
                        local lLowerArm = GetBonePos(char, "LeftLowerArm") or GetBonePos(char, "LeftHand") or GetBonePos(char, "Left Arm")[cite: 7]

                        local rUpperArm = GetBonePos(char, "RightUpperArm") or GetBonePos(char, "Right Arm")[cite: 7]
                        local rLowerArm = GetBonePos(char, "RightLowerArm") or GetBonePos(char, "RightHand") or GetBonePos(char, "Right Arm")[cite: 7]

                        local lUpperLeg = GetBonePos(char, "LeftUpperLeg") or GetBonePos(char, "Left Leg")[cite: 7]
                        local lLowerLeg = GetBonePos(char, "LeftLowerLeg") or GetBonePos(char, "LeftFoot") or GetBonePos(char, "Left Leg")[cite: 7]

                        local rUpperLeg = GetBonePos(char, "RightUpperLeg") or GetBonePos(char, "Right Leg")[cite: 7]
                        local rLowerLeg = GetBonePos(char, "RightLowerLeg") or GetBonePos(char, "RightFoot") or GetBonePos(char, "Right Leg")[cite: 7]

                        SetSegment(o.SkelHead, h, upperT, true, col)[cite: 7]
                        SetSegment(o.SkelSpine, upperT, lowerT, true, col)[cite: 7]
                        SetSegment(o.SkelLUpperArm, upperT, lUpperArm, true, col)[cite: 7]
                        SetSegment(o.SkelLLowerArm, lUpperArm, lLowerArm, true, col)[cite: 7]
                        SetSegment(o.SkelRUpperArm, upperT, rUpperArm, true, col)[cite: 7]
                        SetSegment(o.SkelRLowerArm, rUpperArm, rLowerArm, true, col)[cite: 7]
                        SetSegment(o.SkelLLeg, lowerT, lUpperLeg, true, col)[cite: 7]
                        SetSegment(o.SkelLLowerLeg, lUpperLeg, lLowerLeg, true, col)[cite: 7]
                        SetSegment(o.SkelRLeg, lowerT, rUpperLeg, true, col)[cite: 7]
                        SetSegment(o.SkelRLowerLeg, rUpperLeg, rLowerLeg, true, col)[cite: 7]
                    else
                        SetSegment(o.SkelHead, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelSpine, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelLUpperArm, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelLLowerArm, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelRUpperArm, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelRLowerArm, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelLLeg, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelLLowerLeg, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelRLeg, nil, nil, false, col)[cite: 7]
                        SetSegment(o.SkelRLowerLeg, nil, nil, false, col)[cite: 7]
                    end
                else
                    if PlayerObjects[char] then
                        for _, obj in pairs(PlayerObjects[char]) do obj.Visible = false end[cite: 7]
                    end
                end
            end
        end
    end
end[cite: 7]

local function UpdateEntityESP()
    local activeEnts = {}[cite: 7]

    local nodesFolder = Workspace:FindFirstChild("Nodes")[cite: 7]
    if nodesFolder then
        for _, child in pairs(nodesFolder:GetChildren()) do
            if child:IsA("Model") and SelectedNodes[child.Name] then
                local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")[cite: 7]
                if root then table.insert(activeEnts, {obj = child, root = root}) end[cite: 7]
            end
        end
    end

    local basesFolder = Workspace:FindFirstChild("Bases")[cite: 7]
    if basesFolder then
        for _, container in pairs(basesFolder:GetDescendants()) do
            if (container:IsA("Model") or container:IsA("Part")) and SelectedCrates[container.Name] then
                local root = container:FindFirstChild("HumanoidRootPart") or container:FindFirstChildWhichIsA("BasePart") or (container:IsA("Part") and container)[cite: 7]
                if root then table.insert(activeEnts, {obj = container, root = root}) end[cite: 7]
            end
        end
    end

    local dropsFolder = Workspace:FindFirstChild("Drops")[cite: 7]
    if dropsFolder then
        for _, child in pairs(dropsFolder:GetChildren()) do
            if (child:IsA("Model") or child:IsA("Part")) and SelectedCrates[child.Name] then
                local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart") or (child:IsA("Part") and child)[cite: 7]
                if root then table.insert(activeEnts, {obj = child, root = root}) end[cite: 7]
            end
        end
    end

    for obj, data in pairs(EntityObjects) do
        local keep = false[cite: 7]
        if EntityESPState.Enabled then
            for _, ent in pairs(activeEnts) do
                if ent.obj == obj and (Camera.CFrame.Position - ent.root.Position).Magnitude <= EntityESPState.MaxDistance then
                    keep = true[cite: 7]
                    break[cite: 7]
                end
            end
        end
        if not keep then
            DestroyObject(data.Text)[cite: 7]
            EntityObjects[obj] = nil[cite: 7]
        end
    end

    if not EntityESPState.Enabled then return end[cite: 7]

    for _, ent in pairs(activeEnts) do
        local dist = (Camera.CFrame.Position - ent.root.Position).Magnitude[cite: 7]
        if dist <= EntityESPState.MaxDistance then
            local screen, onScreen = WorldToViewportPoint(Camera, ent.root.Position)[cite: 7]
            if onScreen then
                if not EntityObjects[ent.obj] then
                    EntityObjects[ent.obj] = {
                        Text = CreateObject("Text", { Size = 13, Center = true, Outline = true, Font = 2 })
                    }[cite: 7]
                end
                local o = EntityObjects[ent.obj][cite: 7]
                o.Text.Visible = true[cite: 7]
                o.Text.Color = EntityESPState.Color[cite: 7]
                local txt = ent.obj.Name[cite: 7]
                if EntityESPState.ShowDistance then txt = txt .. string.format(" [%dm]", math.floor(dist)) end[cite: 7]
                o.Text.Text = txt[cite: 7]
                o.Text.Position = Vector2.new(screen.X, screen.Y)[cite: 7]
            else
                if EntityObjects[ent.obj] then EntityObjects[ent.obj].Text.Visible = false end[cite: 7]
            end
        else
            if EntityObjects[ent.obj] then EntityObjects[ent.obj].Text.Visible = false end[cite: 7]
        end
    end
end[cite: 7]

local function GetClosestTarget()
    local closest = nil[cite: 7]
    local shortestDist = SilentAimState.FOV[cite: 7]

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(SilentAimState.TargetPart)[cite: 7]
            if part then
                local screenPos, onScreen = WorldToViewportPoint(Camera, part.Position)[cite: 7]
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)[cite: 7]
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude[cite: 7]
                    if dist < shortestDist then
                        shortestDist = dist[cite: 7]
                        closest = part[cite: 7]
                    end
                end
            end
        end
    end
    return closest[cite: 7]
end[cite: 7]

local function GetAimbotTarget()
    local closest = nil[cite: 7]
    local shortestDist = AimbotState.FOV[cite: 7]
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)[cite: 7]

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")[cite: 7]
            local part = plr.Character:FindFirstChild(AimbotState.TargetPart) or plr.Character:FindFirstChild("Head")[cite: 7]
            if part and (not hum or hum.Health > 0) then
                local screenPos, onScreen = WorldToViewportPoint(Camera, part.Position)[cite: 7]
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude[cite: 7]
                    if dist < shortestDist then
                        shortestDist = dist[cite: 7]
                        closest = part[cite: 7]
                    end
                end
            end
        end
    end
    return closest[cite: 7]
end[cite: 7]

local function MatchInputToBindValue(input, bindVal)
    if not input or not bindVal then return false end[cite: 7]

    if typeof(bindVal) == "EnumItem" then
        return input.KeyCode == bindVal or input.UserInputType == bindVal[cite: 7]
    end

    if type(bindVal) == "table" then
        local raw = bindVal.Key or bindVal.Value or bindVal.Bind[cite: 7]
        if raw then
            return MatchInputToBindValue(input, raw)[cite: 7]
        end
        return false[cite: 7]
    end

    if type(bindVal) == "string" then
        if bindVal == "MB1" or bindVal == "MouseButton1" then
            return input.UserInputType == Enum.UserInputType.MouseButton1[cite: 7]
        elseif bindVal == "MB2" or bindVal == "MouseButton2" then
            return input.UserInputType == Enum.UserInputType.MouseButton2[cite: 7]
        elseif bindVal == "MB3" or bindVal == "MouseButton3" then
            return input.UserInputType == Enum.UserInputType.MouseButton3[cite: 7]
        end
        local kc = Enum.KeyCode[bindVal][cite: 7]
        if kc then
            return input.KeyCode == kc[cite: 7]
        end
        local uit = Enum.UserInputType[bindVal][cite: 7]
        if uit then
            return input.UserInputType == uit[cite: 7]
        end
    end

    return false[cite: 7]
end[cite: 7]

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end[cite: 7]
    local picker = AimbotKeyPicker or (Options and Options.AimbotKeyPicker)[cite: 7]
    local bindVal = (picker and picker.Value) or AimbotState.PickerValue[cite: 7]
    if MatchInputToBindValue(input, bindVal) then
        AimbotState.DirectKeyHeld = true[cite: 7]
    end
end)[cite: 7]

UserInputService.InputEnded:Connect(function(input)
    local picker = AimbotKeyPicker or (Options and Options.AimbotKeyPicker)[cite: 7]
    local bindVal = (picker and picker.Value) or AimbotState.PickerValue[cite: 7]
    if MatchInputToBindValue(input, bindVal) then
        AimbotState.DirectKeyHeld = false[cite: 7]
    end
end)[cite: 7]

local function IsAimbotBindHeld()
    local override = AimbotState.MouseOverride[cite: 7]
    if override == "Mouse 0 (MB1)" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)[cite: 7]
    elseif override == "Mouse 2 (MB2)" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)[cite: 7]
    elseif override == "Mouse 3 (MB3)" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)[cite: 7]
    end

    if AimbotState.DirectKeyHeld then
        return true[cite: 7]
    end

    local picker = AimbotKeyPicker or (Options and Options.AimbotKeyPicker)[cite: 7]
    if picker then
        local okState, isDown = pcall(function()
            return picker:GetState()[cite: 7]
        end)
        if okState and type(isDown) == "boolean" and isDown then
            return true[cite: 7]
        end

        local val = picker.Value[cite: 7]
        if type(val) == "table" and type(val.State) == "boolean" and val.State then
            return true[cite: 7]
        end
        if type(val) == "string" then
            if val == "MB1" or val == "MouseButton1" then
                return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)[cite: 7]
            elseif val == "MB2" or val == "MouseButton2" then
                return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)[cite: 7]
            elseif val == "MB3" or val == "MouseButton3" then
                return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)[cite: 7]
            end
            local enumKey = Enum.KeyCode[val][cite: 7]
            if enumKey then
                return UserInputService:IsKeyDown(enumKey)[cite: 7]
            end
        elseif typeof(val) == "EnumItem" then
            if val.EnumType == Enum.KeyCode then
                return UserInputService:IsKeyDown(val)[cite: 7]
            elseif val.EnumType == Enum.UserInputType then
                return UserInputService:IsMouseButtonPressed(val)[cite: 7]
            end
        end
    end

    return false[cite: 7]
end[cite: 7]

local function UpdateAimbot()
    if not AimbotState.Enabled or not Camera then return end[cite: 7]
    if not IsAimbotBindHeld() then return end[cite: 7]

    local targetPart = GetAimbotTarget()[cite: 7]
    if not targetPart then return end[cite: 7]

    local camPos = Camera.CFrame.Position[cite: 7]
    local desiredCF = CFrame.new(camPos, targetPart.Position)[cite: 7]
    local alpha = math.clamp(AimbotState.Smoothness, 0.01, 1)[cite: 7]
    Camera.CFrame = Camera.CFrame:Lerp(desiredCF, alpha)[cite: 7]
end[cite: 7]

local function UpdateFOV()
    if not SilentAimState.DrawFOV then
        if FOVCircle then
            FOVCircle.Visible = false[cite: 7]
        end
    else
        if not FOVCircle then
            FOVCircle = CreateObject("Circle", {
                Thickness = 1,
                NumSides = 60,
                Filled = false,
                Transparency = 0.5,
            })[cite: 7]
        end

        FOVCircle.Visible = true[cite: 7]
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)[cite: 7]
        FOVCircle.Radius = SilentAimState.FOV[cite: 7]

        local target = GetClosestTarget()[cite: 7]
        if target then
            FOVCircle.Color = Color3.new(0, 0, 1)[cite: 7]
        else
            FOVCircle.Color = Color3.new(1, 1, 1)[cite: 7]
        end
    end

    if not AimbotState.DrawFOV then
        if AimbotFOVCircle then
            AimbotFOVCircle.Visible = false[cite: 7]
        end
    else
        if not AimbotFOVCircle then
            AimbotFOVCircle = CreateObject("Circle", {
                Thickness = 1,
                NumSides = 60,
                Filled = false,
                Transparency = 0.5,
                Color = Color3.new(1, 0.5, 0),
            })[cite: 7]
        end

        AimbotFOVCircle.Visible = true[cite: 7]
        AimbotFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)[cite: 7]
        AimbotFOVCircle.Radius = AimbotState.FOV[cite: 7]
    end
end[cite: 7]

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(t, k)
    if not checkcaller() and t == LocalPlayer and k == "GetMouse" then
        if SilentAimState.Enabled then
            local targetPart = GetClosestTarget()[cite: 7]
            if targetPart then
                return function()
                    return {Hit = CFrame.new(targetPart.Position), Target = targetPart, UnitRay = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit)}[cite: 7]
                end
            end
        end
    end
    return oldIndex(t, k)[cite: 7]
end)[cite: 7]

RunService.RenderStepped:Connect(function()
    UpdatePlayerESP()[cite: 7]
    UpdateEntityESP()[cite: 7]
    UpdateAimbot()[cite: 7]
    UpdateFOV()[cite: 7]
end)[cite: 7]

PlayerGroup:AddToggle("PlayerEsp", { Text = "Enable Player ESP", Default = false, Callback = function(v) PlayerESPState.Enabled = v end })[cite: 7]
PlayerGroup:AddToggle("PlayerNames", { Text = "Show Names", Default = true, Callback = function(v) PlayerESPState.ShowNames = v end })[cite: 7]
PlayerGroup:AddToggle("PlayerDist", { Text = "Show Distance", Default = true, Callback = function(v) PlayerESPState.ShowDistance = v end })[cite: 7]
PlayerGroup:AddToggle("PlayerBox", { Text = "Show Boxes", Default = true, Callback = function(v) PlayerESPState.ShowBox = v end })[cite: 7]
PlayerGroup:AddToggle("PlayerHealth", { Text = "Show Health", Default = true, Callback = function(v) PlayerESPState.ShowHealth = v end })[cite: 7]
PlayerGroup:AddToggle("PlayerTracers", { Text = "Show Tracers", Default = false, Callback = function(v) PlayerESPState.ShowTracers = v end })[cite: 7]
PlayerGroup:AddToggle("PlayerSkel", { Text = "Show Skeleton", Default = false, Callback = function(v) PlayerESPState.ShowSkeleton = v end })[cite: 7]
PlayerGroup:AddSlider("PlayerMaxDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) PlayerESPState.MaxDistance = v end })[cite: 7]
PlayerGroup:AddLabel("ESP Color"):AddColorPicker("PlayerColor", {
    Default = Color3.new(1, 0, 0),
    Title = "Player ESP Color",
    Callback = function(v) PlayerESPState.Color = v end
})[cite: 7]

NodeGroup:AddToggle("EntEsp", { Text = "Enable Entity ESP", Default = false, Callback = function(v) EntityESPState.Enabled = v end })[cite: 7]
NodeGroup:AddToggle("EntNames", { Text = "Show Names", Default = true, Callback = function(v) EntityESPState.ShowNames = v end })[cite: 7]
NodeGroup:AddToggle("EntDist", { Text = "Show Distance", Default = true, Callback = function(v) EntityESPState.ShowDistance = v end })[cite: 7]
NodeGroup:AddSlider("EntMaxDist", { Text = "Max Distance", Default = 1500, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) EntityESPState.MaxDistance = v end })[cite: 7]
NodeGroup:AddLabel("Entity Color"):AddColorPicker("EntColor", {
    Default = Color3.new(0, 1, 1),
    Title = "Entity ESP Color",
    Callback = function(v) EntityESPState.Color = v end
})[cite: 7]

NodeGroup:AddToggle("NodeStone", { Text = "Stone Node", Default = true, Callback = function(v) SelectedNodes["Stone_Node"] = v end })[cite: 7]
NodeGroup:AddToggle("NodeMetal", { Text = "Metal Node", Default = true, Callback = function(v) SelectedNodes["Metal_Node"] = v end })[cite: 7]
NodeGroup:AddToggle("NodePhosphate", { Text = "Phosphate Node", Default = true, Callback = function(v) SelectedNodes["Phosphate_Node"] = v end })[cite: 7]

CrateGroup:AddToggle("CrateTimed", { Text = "Timed Crate", Default = true, Callback = function(v) SelectedCrates["Timed Crate"] = v end })[cite: 7]
CrateGroup:AddToggle("CrateWooden", { Text = "Wooden Crate", Default = true, Callback = function(v) SelectedCrates["Wooden Crate"] = v end })[cite: 7]
CrateGroup:AddToggle("CrateFood", { Text = "Food Crate", Default = true, Callback = function(v) SelectedCrates["Food Crate"] = v end })[cite: 7]
CrateGroup:AddToggle("CrateLockedMetal", { Text = "Locked Metal Crate", Default = true, Callback = function(v) SelectedCrates["Locked Metal Crate"] = v end })[cite: 7]
CrateGroup:AddToggle("CrateLockedWood", { Text = "Locked Wooden Crate", Default = true, Callback = function(v) SelectedCrates["Locked Wooden Crate"] = v end })[cite: 7]
CrateGroup:AddToggle("CrateBodyBag", { Text = "Body Bag", Default = true, Callback = function(v) SelectedCrates["Body Bag"] = v end })[cite: 7]

SilentAimGroup:AddToggle("SilentAim", { Text = "Enable Silent Aim", Default = false, Callback = function(v) SilentAimState.Enabled = v end })[cite: 7]
SilentAimGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = false, Callback = function(v) SilentAimState.DrawFOV = v end })[cite: 7]
SilentAimGroup:AddDropdown("AimPart", {
    Text = "Target Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"},
    Default = "Head",
    Multi = false,
    Callback = function(v) SilentAimState.TargetPart = v end
})[cite: 7]
SilentAimGroup:AddSlider("AimFOV", {
    Text = "FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v) SilentAimState.FOV = v end
})[cite: 7]

AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enable Aimbot", Default = false, Callback = function(v) AimbotState.Enabled = v end })[cite: 7]
AimbotGroup:AddToggle("AimbotDrawFOV", { Text = "Draw Aimbot FOV", Default = false, Callback = function(v) AimbotState.DrawFOV = v end })[cite: 7]
AimbotKeyPicker = AimbotGroup:AddLabel("Aimbot Bind"):AddKeyPicker("AimbotKeyPicker", {
    Default = "MB2",
    Mode = "Hold",
    Text = "Aimbot Bind",
    Callback = function(v)
        AimbotState.PickerValue = v
        AimbotState.DirectKeyHeld = false
    end,
})[cite: 7]
AimbotGroup:AddDropdown("AimbotMouseOverride", {
    Text = "Mouse Button Override",
    Values = { "None", "Mouse 0 (MB1)", "Mouse 2 (MB2)", "Mouse 3 (MB3)" },
    Default = "None",
    Multi = false,
    Callback = function(v)
        AimbotState.MouseOverride = v
    end,
})[cite: 7]
AimbotGroup:AddDropdown("AimbotPart", {
    Text = "Target Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"},
    Default = "Head",
    Multi = false,
    Callback = function(v) AimbotState.TargetPart = v end
})[cite: 7]
AimbotGroup:AddSlider("AimbotFOV", {
    Text = "Aimbot FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v) AimbotState.FOV = v end
})[cite: 7]
AimbotGroup:AddSlider("AimbotSmooth", {
    Text = "Smoothness",
    Default = 25,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(v) AimbotState.Smoothness = v / 100 end
})[cite: 7]
