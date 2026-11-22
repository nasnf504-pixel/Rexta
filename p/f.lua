local cloneref = cloneref or function(x) return x end
local clonefunction = clonefunction or function(f) return f end

local isScriptable = clonefunction(isscriptable)
local setScriptable = clonefunction(setscriptable)
local setScriptableCache = {}

local textService = cloneref(game:GetService("TextService"))

local drawing = {
    Fonts = {
        UI = 0,
        System = 2,
        Plex = 1,
        Monospace = 3
    }
}

local renv = getrenv()
local genv = getgenv()
local pi = renv.math.pi
local huge = renv.math.huge
local _assert = clonefunction(renv.assert)
local _color3new = clonefunction(renv.Color3.new)
local _instancenew = clonefunction(renv.Instance.new)
local _mathatan2 = clonefunction(renv.math.atan2)
local _mathclamp = clonefunction(renv.math.clamp)
local _mathmax = clonefunction(renv.math.max)
local _setmetatable = clonefunction(renv.setmetatable)
local _stringformat = clonefunction(renv.string.format)
local _typeof = clonefunction(renv.typeof)
local _taskspawn = clonefunction(renv.task.spawn)
local _udimnew = clonefunction(renv.UDim.new)
local _udim2fromoffset = clonefunction(renv.UDim2.fromOffset)
local _udim2new = clonefunction(renv.UDim2.new)
local _vector2new = clonefunction(renv.Vector2.new)
local _destroy = clonefunction(game.Destroy)
local _gettextboundsasync = clonefunction(textService.GetTextBoundsAsync)
local _httpget = clonefunction(game.HttpGet)
local _writecustomasset = writecustomasset and clonefunction(writecustomasset)
local _protectinstance = protectinstance and clonefunction(protectinstance)

local function create(className, properties, children)
    local inst = _instancenew(className)
    for i, v in properties do
        if i ~= "Parent" then
            inst[i] = v
        end
    end
    if children then
        for i, v in children do
            v.Parent = inst
        end
    end
    if _protectinstance then
        _protectinstance(inst)
    end
    inst.Parent = properties.Parent
    return inst
end

do
    local fonts = {
        Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new("rbxasset://fonts/families/HighwayGothic.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    }

    for i, v in fonts do
        game:GetService("TextService"):GetTextBoundsAsync(create("GetTextBoundsParams", {
            Text = "Hi",
            Size = 12,
            Font = v,
            Width = huge
        }))
    end
end

do
    local drawingDirectory = create("ScreenGui", {
        DisplayOrder = 15,
        IgnoreGuiInset = true,
        Name = "drawingDirectory",
        Parent = gethui(),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local function updatePosition(frame, from, to, thickness)
        local central = (from + to) / 2
        local offset = to - from
        frame.Position = _udim2fromoffset(central.X, central.Y)
        frame.Rotation = _mathatan2(offset.Y, offset.X) * 180 / pi
        frame.Size = _udim2fromoffset(offset.Magnitude, thickness)
    end

    local itemCounter = 0
    local cache = {}

    local classes = {}
    do
        local line = {}

        function line.new()
            itemCounter = itemCounter + 1
            local id = itemCounter

            local newLine = _setmetatable({
                _id = id,
                __OBJECT_EXISTS = true,
                _properties = {
                    Color = _color3new(),
                    From = _vector2new(),
                    Thickness = 1,
                    To = _vector2new(),
                    Transparency = 1,
                    Visible = false,
                    ZIndex = 0
                },
                _frame = create("Frame", {
                    Name = id,
                    AnchorPoint = _vector2new(0.5, 0.5),
                    BackgroundColor3 = _color3new(),
                    BorderSizePixel = 0,
                    Parent = drawingDirectory,
                    Position = _udim2new(),
                    Size = _udim2new(),
                    Visible = false,
                    ZIndex = 0
                })
            }, line)

            cache[id] = newLine
            return newLine
        end

        function line:__index(k)
            local prop = self._properties[k]
            if prop ~= nil then
                return prop
            end
            return line[k]
        end

        function line:__newindex(k, v)
            if self.__OBJECT_EXISTS == true then
                local props = self._properties

                if props[k] == nil or props[k] == v or typeof(props[k]) ~= typeof(v) then
                    return
                end

                props[k] = v

                if k == "Color" then
                    self._frame.BackgroundColor3 = v
                elseif k == "From" then
                    self:_updatePosition()
                elseif k == "Thickness" then
                    self._frame.Size = _udim2fromoffset(self._frame.AbsoluteSize.X, _mathmax(v, 1))
                elseif k == "To" then
                    self:_updatePosition()
                elseif k == "Transparency" then
                    self._frame.BackgroundTransparency = _mathclamp(1 - v, 0, 1)
                elseif k == "Visible" then
                    self._frame.Visible = v
                elseif k == "ZIndex" then
                    self._frame.ZIndex = v
                end
            end
        end

        function line:__iter()
            return next, self._properties
        end

        function line:__tostring()
            return "Drawing"
        end

        function line:Destroy()
            cache[self._id] = nil
            self.__OBJECT_EXISTS = false
            _destroy(self._frame)
        end

        function line:_updatePosition()
            local props = self._properties
            updatePosition(self._frame, props.From, props.To, props.Thickness)
        end

        line.Remove = line.Destroy
        classes.Line = line
    end

    do
        local circle = {}

        function circle.new()
            itemCounter = itemCounter + 1
            local id = itemCounter

            local newCircle = _setmetatable({
                _id = id,
                __OBJECT_EXISTS = true,
                _properties = {
                    Color = _color3new(),
                    Filled = false,
                    NumSides = 0,
                    Position = _vector2new(),
                    Radius = 0,
                    Thickness = 1,
                    Transparency = 1,
                    Visible = false,
                    ZIndex = 0
                },
                _frame = create("Frame", {
                    Name = id,
                    AnchorPoint = _vector2new(0.5, 0.5),
                    BackgroundColor3 = _color3new(),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = drawingDirectory,
                    Position = _udim2new(),
                    Size = _udim2new(),
                    Visible = false,
                    ZIndex = 0
                }, {
                    create("UICorner", {
                        Name = "_corner",
                        CornerRadius = _udimnew(1, 0)
                    }),
                    create("UIStroke", {
                        Name = "_stroke",
                        Color = _color3new(),
                        Thickness = 1,
                    })
                })
            }, circle)

            cache[id] = newCircle
            return newCircle
        end

        function circle:__index(k)
            local prop = self._properties[k]
            if prop ~= nil then
                return prop
            end
            return circle[k]
        end

        function circle:__newindex(k, v)
            if self.__OBJECT_EXISTS == true then
                local props = self._properties
                if props[k] == nil or props[k] == v or typeof(props[k]) ~= typeof(v) then
                    return
                end
                props[k] = v
                if k == "Color" then
                    self._frame.BackgroundColor3 = v
                    self._frame._stroke.Color = v
                elseif k == "Filled" then
                    self._frame.BackgroundTransparency = v and 1 - props.Transparency or 1
                elseif k == "Position" then
                    self._frame.Position = _udim2fromoffset(v.X, v.Y)
                elseif k == "Radius" then
                    self:_updateRadius()
                elseif k == "Thickness" then
                    self._frame._stroke.Thickness = _mathmax(v, 1)
                    self:_updateRadius()
                elseif k == "Transparency" then
                    self._frame._stroke.Transparency = 1 - v
                    if props.Filled then
                        self._frame.BackgroundTransparency = 1 - v
                    end
                elseif k == "Visible" then
                    self._frame.Visible = v
                elseif k == "ZIndex" then
                    self._frame.ZIndex = v
                end
            end
        end

        function circle:__iter()
            return next, self._properties
        end

        function circle:__tostring()
            return "Drawing"
        end

        function circle:Destroy()
            cache[self._id] = nil
            self.__OBJECT_EXISTS = false
            _destroy(self._frame)
        end

        function circle:_updateRadius()
            local props = self._properties
            local diameter = (props.Radius * 2) - (props.Thickness * 2)
            self._frame.Size = _udim2fromoffset(diameter, diameter)
        end

        circle.Remove = circle.Destroy
        classes.Circle = circle
    end

    do
        local enumToFont = {
            [drawing.Fonts.UI] = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            [drawing.Fonts.System] = Font.new("rbxasset://fonts/families/HighwayGothic.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            [drawing.Fonts.Plex] = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            [drawing.Fonts.Monospace] = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        }

        local text = {}

        function text.new()
            itemCounter = itemCounter + 1
            local id = itemCounter

            local newText = _setmetatable({
                _id = id,
                __OBJECT_EXISTS = true,
                _properties = {
                    Center = false,
                    Color = _color3new(),
                    Font = 0,
                    Outline = false,
                    OutlineColor = _color3new(),
                    Position = _vector2new(),
                    Size = 12,
                    Text = "",
                    TextBounds = _vector2new(),
                    Transparency = 1,
                    Visible = false,
                    ZIndex = 0
                },
                _frame = create("TextLabel", {
                    Name = id,
                    BackgroundTransparency = 1,
                    FontFace = enumToFont[0],
                    Parent = drawingDirectory,
                    Position = _udim2new(),
                    Size = _udim2new(),
                    Text = "",
                    TextColor3 = _color3new(),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Visible = false,
                    ZIndex = 0
                }, {
                    create("UIStroke", {
                        Name = "_stroke",
                        Color = _color3new(),
                        Enabled = false,
                        Thickness = 1
                    })
                })
            }, text)

            cache[id] = newText
            return newText
        end

        function text:__index(k)
            local prop = self._properties[k]
            if prop ~= nil then
                return prop
            end
            return text[k]
        end

        function text:__newindex(k, v)
            if self.__OBJECT_EXISTS == true then
                local props = self._properties
                if k == "TextBounds" or props[k] == nil or props[k] == v or typeof(props[k]) ~= typeof(v) then
                    return
                end
                props[k] = v
                if k == "Center" then
                    self._frame.TextXAlignment = v and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                elseif k == "Color" then
                    self._frame.TextColor3 = v
                elseif k == "Font" then
                    self._frame.FontFace = enumToFont[v]
                    self:_updateTextBounds()
                elseif k == "Outline" then
                    self._frame._stroke.Enabled = v
                elseif k == "OutlineColor" then
                    self._frame._stroke.Color = v
                elseif k == "Position" then
                    self._frame.Position = _udim2fromoffset(v.X, v.Y)
                elseif k == "Size" then
                    self._frame.TextSize = v
                    self:_updateTextBounds()
                elseif k == "Text" then
                    self._frame.Text = v
                    self:_updateTextBounds()
                elseif k == "Transparency" then
                    self._frame.TextTransparency = 1 - v
                    self._frame._stroke.Transparency = 1 - v
                elseif k == "Visible" then
                    self._frame.Visible = v
                elseif k == "ZIndex" then
                    self._frame.ZIndex = v
                end
            end
        end

        function text:__iter()
            return next, self._properties
        end

        function text:__tostring()
            return "Drawing"
        end

        function text:Destroy()
            cache[self._id] = nil
            self.__OBJECT_EXISTS = false
            _destroy(self._frame)
        end

        function text:_updateTextBounds()
            local props = self._properties
            props.TextBounds = _gettextboundsasync(textService, create("GetTextBoundsParams", {
                Text = props.Text,
                Size = props.Size,
                Font = enumToFont[props.Font],
                Width = huge
            }))
        end

        text.Remove = text.Destroy
        classes.Text = text
    end

    do
        local square = {}

        function square.new()
            itemCounter = itemCounter + 1
            local id = itemCounter

            local newSquare = _setmetatable({
                _id = id,
                __OBJECT_EXISTS = true,
                _properties = {
                    Color = _color3new(),
                    Filled = false,
                    Position = _vector2new(),
                    Size = _vector2new(),
                    Thickness = 1,
                    Transparency = 1,
                    Visible = false,
                    ZIndex = 0
                },
                _frame = create("Frame", {
                    BackgroundColor3 = _color3new(),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = drawingDirectory,
                    Position = _udim2new(),
                    Size = _udim2new(),
                    Visible = false,
                    ZIndex = 0
                }, {
                    create("UIStroke", {
                        Name = "_stroke",
                        Color = _color3new(),
                        Thickness = 1,
                        LineJoinMode = Enum.LineJoinMode.Miter
                    })
                })
            }, square)

            cache[id] = newSquare
            return newSquare
        end

        function square:__index(k)
            local prop = self._properties[k]
            if prop ~= nil then
                return prop
            end
            return square[k]
        end

        function square:__newindex(k, v)
            if self.__OBJECT_EXISTS == true then
                local props = self._properties
                if props[k] == nil or props[k] == v or typeof(props[k]) ~= typeof(v) then
                    return
                end
                props[k] = v
                if k == "Color" then
                    self._frame.BackgroundColor3 = v
                    self._frame._stroke.Color = v
                elseif k == "Filled" then
                    self._frame.BackgroundTransparency = v and 1 - props.Transparency or 1
                elseif k == "Position" then
                    self:_updateScale()
                elseif k == "Size" then
                    self:_updateScale()
                elseif k == "Thickness" then
                    self._frame._stroke.Thickness = v
                    self:_updateScale()
                elseif k == "Transparency" then
                    self._frame._stroke.Transparency = 1 - v
                    if props.Filled then
                        self._frame.BackgroundTransparency = 1 - v
                    end
                elseif k == "Visible" then
                    self._frame.Visible = v
                elseif k == "ZIndex" then
                    self._frame.ZIndex = v
                end
            end
        end

        function square:__iter()
            return next, self._properties
        end

        function square:__tostring()
            return "Drawing"
        end

        function square:Destroy()
            cache[self._id] = nil
            self.__OBJECT_EXISTS = false
            _destroy(self._frame)
        end

        function square:_updateScale()
            local props = self._properties
            self._frame.Position = _udim2fromoffset(props.Position.X + props.Thickness, props.Position.Y + props.Thickness)
            local thickness = props.Thickness
            self._frame.Size = _udim2fromoffset(props.Size.X - thickness * 2, props.Size.Y - thickness * 2)
        end

        square.Remove = square.Destroy
        classes.Square = square
    end

    drawing.new = newcclosure(function(x)
        return _assert(classes[x], _stringformat("Invalid drawing type '%s'", x)).new()
    end)

    drawing.clear = newcclosure(function()
        for i, v in cache do
            if v.__OBJECT_EXISTS then
                v:Destroy()
            end
        end
    end)

    drawing.cache = cache
end

setreadonly(drawing, true)
setreadonly(drawing.Fonts, true)

genv.Drawing = drawing
genv.cleardrawcache = drawing.clear

genv.isrenderobj = newcclosure(function(x)
    return tostring(x) == "Drawing"
end)

local _isrenderobj = clonefunction(isrenderobj)

genv.getrenderproperty = newcclosure(function(x, y)
    _assert(_isrenderobj(x), _stringformat("invalid argument #1 to 'getrenderproperty' (Drawing expected, got %s)", _typeof(x)))
    return x[y]
end)

genv.setrenderproperty = newcclosure(function(x, y, z)
    _assert(_isrenderobj(x), _stringformat("invalid argument #1 to 'setrenderproperty' (Drawing expected, got %s)", _typeof(x)))
    x[y] = z
end)

genv.drawingLoaded = true

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

local function CreateObject(className, properties)
    local obj = Drawing.new(className)
    for k, v in pairs(properties) do obj[k] = v end
    return obj
end

local function DestroyObject(obj)
    if obj then pcall(function() obj:Remove() end) end
end

local function GetBoundingBox(model, isPlayer)
    if isPlayer then
        local success, cf, size = pcall(function()
            return model:ComputeR15BodyBoundingBox()
        end)
        if success and cf and size then
            return cf, size
        end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum then
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp then
                return CFrame.new(hrp.Position), Vector3.new(2, 5, 1)
            end
        end
        return nil, nil
    else
        local success, cf, size = pcall(function()
            return model:GetBoundingBox()
        end)
        if success and cf and size then
            return cf, size
        end
        return nil, nil
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

local function GetBoxOffset(cf, size)
    local x, y = -size.X / 2, size.Y / 2
    local topRightPos = (cf * CFrame.new(x, y, 0)).Position
    local bottomRightPos = (cf * CFrame.new(x, -y, 0)).Position
    
    local topRight, onTop = WorldToViewportPoint(Camera, topRightPos)
    local bottomRight, onBottom = WorldToViewportPoint(Camera, bottomRightPos)
    local center, onCenter = WorldToViewportPoint(Camera, cf.Position)
    
    if not (onTop and onBottom and onCenter) then return nil end
    
    local centerVec = Vector2.new(center.X, center.Y)
    local topRightVec = Vector2.new(topRight.X, topRight.Y)
    local bottomRightVec = Vector2.new(bottomRight.X, bottomRight.Y)
    
    local offsetX = math.max(topRightVec.X - centerVec.X, bottomRightVec.X - centerVec.X)
    local offsetY = math.max(centerVec.Y - topRightVec.Y, bottomRightVec.Y - centerVec.Y)
    
    return centerVec, Vector2.new(offsetX, offsetY)
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
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if hrp and hum and hum.Health > 0 and head then
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist <= PlayerESPState.MaxDistance then
                local cf, size = GetBoundingBox(char, true)
                if not cf or not size then 
                    if PlayerObjects[char] then
                        for _, obj in pairs(PlayerObjects[char]) do obj.Visible = false end
                    end
                    continue
                end
                
                local center, offset = GetBoxOffset(cf, size)
                if not center or not offset then 
                    if PlayerObjects[char] then
                        for _, obj in pairs(PlayerObjects[char]) do obj.Visible = false end
                    end
                    continue
                end
                
                if not PlayerObjects[char] then
                    PlayerObjects[char] = {
                        Box = CreateObject("Square", { Thickness = 1, Filled = false }),
                        BoxOutline = CreateObject("Square", { Thickness = 1, Filled = false, Color = Color3.new(0, 0, 0) }),
                        HealthBar = CreateObject("Square", { Thickness = 1, Filled = true }),
                        HealthBg = CreateObject("Square", { Thickness = 1, Filled = true, Color = Color3.new(0.2, 0.2, 0.2), Transparency = 0.5 }),
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
                local boxSize = offset * 2
                local boxPos = center - offset
                
                local minHeight = 30
                if boxSize.Y < minHeight then
                    local scale = minHeight / boxSize.Y
                    boxSize = boxSize * scale
                    boxPos = center - Vector2.new(boxSize.X / 2, boxSize.Y / 2)
                end

                o.Box.Visible = PlayerESPState.ShowBox
                o.Box.Color = PlayerESPState.Color
                o.Box.Size = boxSize
                o.Box.Position = boxPos

                o.BoxOutline.Visible = PlayerESPState.ShowBox
                o.BoxOutline.Size = boxSize + Vector2.new(2, 2)
                o.BoxOutline.Position = boxPos - Vector2.new(1, 1)

                o.HealthBar.Visible = PlayerESPState.ShowHealth
                local barH = (hum.Health / hum.MaxHealth) * boxSize.Y
                o.HealthBar.Color = Color3.new(1 - (hum.Health/hum.MaxHealth), (hum.Health/hum.MaxHealth), 0)
                o.HealthBar.Size = Vector2.new(2, barH)
                o.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (boxSize.Y - barH))

                o.HealthBg.Visible = PlayerESPState.ShowHealth
                o.HealthBg.Size = Vector2.new(2, boxSize.Y)
                o.HealthBg.Position = Vector2.new(boxPos.X - 5, boxPos.Y)

                o.NameText.Visible = PlayerESPState.ShowNames
                o.NameText.Color = PlayerESPState.Color
                o.NameText.Text = char.Name
                o.NameText.Position = Vector2.new(center.X, boxPos.Y - 16)

                o.DistText.Visible = PlayerESPState.ShowDistance
                o.DistText.Color = Color3.new(1,1,1)
                o.DistText.Text = string.format("[%dm]", math.floor(dist))
                o.DistText.Position = Vector2.new(center.X, boxPos.Y + boxSize.Y + 2)

                o.Tracer.Visible = PlayerESPState.ShowTracers
                o.Tracer.Color = PlayerESPState.Color
                o.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                o.Tracer.To = center

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
                table.insert(activeEnts, child)
            end
        end
    end

    local basesFolder = Workspace:FindFirstChild("Bases")
    if basesFolder then
        for _, container in pairs(basesFolder:GetDescendants()) do
            if (container:IsA("Model") or container:IsA("Part")) and SelectedCrates[container.Name] then
                table.insert(activeEnts, container)
            end
        end
    end

    local dropsFolder = Workspace:FindFirstChild("Drops")
    if dropsFolder then
        for _, child in pairs(dropsFolder:GetChildren()) do
            if (child:IsA("Model") or child:IsA("Part")) and SelectedCrates[child.Name] then
                table.insert(activeEnts, child)
            end
        end
    end

    for obj, data in pairs(EntityObjects) do
        local keep = false
        if EntityESPState.Enabled then
            for _, ent in pairs(activeEnts) do
                if ent == obj then
                    local pivot = ent:GetPivot()
                    if pivot and (Camera.CFrame.Position - pivot.Position).Magnitude <= EntityESPState.MaxDistance then
                        keep = true
                        break
                    end
                end
            end
        end
        if not keep then
            DestroyObject(data.Box)
            DestroyObject(data.BoxOutline)
            DestroyObject(data.Text)
            EntityObjects[obj] = nil
        end
    end

    if not EntityESPState.Enabled then return end

    for _, ent in pairs(activeEnts) do
        local pivot = ent:GetPivot()
        if pivot then
            local dist = (Camera.CFrame.Position - pivot.Position).Magnitude
            if dist <= EntityESPState.MaxDistance then
                local cf, size = GetBoundingBox(ent, false)
                if not cf or not size then
                    if EntityObjects[ent] then
                        EntityObjects[ent].Box.Visible = false
                        EntityObjects[ent].BoxOutline.Visible = false
                        EntityObjects[ent].Text.Visible = false
                    end
                    continue
                end
                
                local center, offset = GetBoxOffset(cf, size)
                if not center or not offset then
                    if EntityObjects[ent] then
                        EntityObjects[ent].Box.Visible = false
                        EntityObjects[ent].BoxOutline.Visible = false
                        EntityObjects[ent].Text.Visible = false
                    end
                    continue
                end

                if not EntityObjects[ent] then
                    EntityObjects[ent] = {
                        Box = CreateObject("Square", { Thickness = 1, Filled = false }),
                        BoxOutline = CreateObject("Square", { Thickness = 1, Filled = false, Color = Color3.new(0, 0, 0) }),
                        Text = CreateObject("Text", { Size = 13, Center = true, Outline = true, Font = 2 })
                    }
                end
                
                local o = EntityObjects[ent]
                local boxSize = offset * 2
                local boxPos = center - offset
                
                local minHeight = 15
                if boxSize.Y < minHeight then
                    local scale = minHeight / boxSize.Y
                    boxSize = boxSize * scale
                    boxPos = center - Vector2.new(boxSize.X / 2, boxSize.Y / 2)
                end

                o.Box.Visible = true
                o.Box.Color = EntityESPState.Color
                o.Box.Size = boxSize
                o.Box.Position = boxPos

                o.BoxOutline.Visible = true
                o.BoxOutline.Size = boxSize + Vector2.new(2, 2)
                o.BoxOutline.Position = boxPos - Vector2.new(1, 1)

                o.Text.Visible = EntityESPState.ShowNames
                o.Text.Color = EntityESPState.Color
                local txt = ent.Name
                if EntityESPState.ShowDistance then txt = txt .. string.format(" [%dm]", math.floor(dist)) end
                o.Text.Text = txt
                o.Text.Position = Vector2.new(center.X, boxPos.Y - 16)
            end
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

local function UpdateFOV()
    if not SilentAimState.DrawFOV then
        if FOVCircle then FOVCircle.Visible = false end
        return
    end

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
