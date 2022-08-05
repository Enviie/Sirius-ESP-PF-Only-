--[[
    made by siper#9938, credits to spoorloos/mickey.#5612 for bounding box/out of view arrows
]]

-- Module
local EspLibrary = {
    drawings = {},
    instances = {},
    espCache = {},
    conns = {},
    whitelist = {}, -- insert string that is the player's name you want to whitelist (turns esp color to whitelistColor in options)
    blacklist = {}, -- insert string that is the player's name you want to blacklist (removes player from esp)
    options = {
        enabled = true,
        scaleFactorX = 4,
        scaleFactorY = 5,
        font = 2,
        fontSize = 13,
        limitDistance = false,
        maxDistance = 1000,
        visibleOnly = false,
        teamCheck = false,
        teamColor = false,
        fillColor = nil,
        whitelistColor = Color3.fromRGB(140, 0, 255),
        espColor = Color3.fromRGB(18, 184, 255),
        outOfViewArrows = false,
        outOfViewArrowsFilled = true,
        outOfViewArrowsSize = 25,
        outOfViewArrowsRadius = 100,
        outOfViewArrowsTransparency = 0.5,
        outOfViewArrowsOutline = false,
        outOfViewArrowsOutlineFilled = false,
        outOfViewArrowsOutlineColor = Color3.new(1, 1, 1),
        outOfViewArrowsOutlineTransparency = 1,
        names = true,
        nameTransparency = 1,
        boxes = true,
        boxesTransparency = 1,
        boxFill = false,
        boxFillTransparency = 0.5,
        healthBars = true,
        healthBarsSize = 1,
        healthBarsTransparency = 1,
        healthBarsColor = Color3.fromRGB(21, 255, 0),
        healthText = true,
        healthTextTransparency = 1,
        healthTextSuffix = "%",
        distance = true,
        distanceTransparency = 1,
        distanceSuffix = " Studs",
        tracers = false,
        tracerTransparency = 1,
        tracerOrigin = "Bottom" -- Available [Mouse, Top, Bottom]
    },
}

-- Variables
local instanceNew = Instance.new
local drawingNew = Drawing.new
local vector2New = Vector2.new
local vector3New = Vector3.new
local cframeNew = CFrame.new
local raycastParamsNew = RaycastParams.new
local tan = math.tan
local rad = math.rad
local floor = math.floor
local insert = table.insert
local findFirstChild = game.FindFirstChild
local raycast = workspace.Raycast
local pointToObjectSpace = cframeNew().PointToObjectSpace
local cross = vector3New().Cross

-- Services
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local coreGui = game:GetService("CoreGui")
local userInputService = game:GetService("UserInputService")

-- Cache
local currentCamera = workspace.CurrentCamera
local localPlayer = players.LocalPlayer

-- Support Functions
local CharTable, Health = nil, nil
for _, v in pairs(getgc(true)) do
	if type(v) == "function" then
		if debug.getinfo(v).name == "getbodyparts" then
			CharTable = debug.getupvalue(v, 1)
        end
	end
    if type(v) == "table" then
        if rawget(v, "getplayerhealth") then
            Health = v
        end
    end
	if CharTable and Health then
		break
	end
end

local function isDrawing(type)
    return type == "Square" or type == "Text" or type == "Triangle" or type == "Image" or type == "Line" or type == "Circle"
end

local function create(type, properties)
    local drawing = isDrawing(type)
    local object = drawing and drawingNew(type) or instanceNew(type)

    if (properties) then
        for i,v in pairs(properties) do
            object[i] = v
        end
    end

    insert(drawing and EspLibrary.drawings or EspLibrary.instances, object)
    return object
end

local function worldToViewportPoint(position)
    local screenPosition, onScreen = currentCamera:WorldToViewportPoint(position)
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z
end

local function round(number)
    if (typeof(number) == "Vector2") then
        return vector2New(round(number.X), round(number.Y))
    else
        return floor(number)
    end
end

-- Main Functions
function EspLibrary.GetTeam(player)
    local team = player.Team
    return team, player.TeamColor.Color
end

function EspLibrary.GetCharacter(player)
    local character = CharTable[player]
    return character, character and character.root
end

function EspLibrary.GetBoundingBox(torso)
    local torsoPosition, onScreen, depth = worldToViewportPoint(torso.Position)
    local scaleFactor = 1 / (tan(rad(currentCamera.FieldOfView * 0.5)) * 2 * depth) * 1000
    local size = round(vector2New(EspLibrary.options.scaleFactorX * scaleFactor, EspLibrary.options.scaleFactorY * scaleFactor))
    return onScreen, size, round(vector2New(torsoPosition.X - (size.X * 0.5), torsoPosition.Y - (size.Y * 0.5))), torsoPosition
end

function EspLibrary.GetHealth(player, character)
    local health, maxHealth = Health:getplayerhealth(player)
    if type(health) == "number" and type(maxHealth) == "number" then
        return health, maxHealth
    end
    return 100, 100
end

function EspLibrary.VisibleCheck(character, position)
    local origin = currentCamera.CFrame.Position
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { EspLibrary.GetCharacter(localPlayer), currentCamera, character }
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true

    local result = raycast(workspace, origin, position - origin, params)
    return not result
end

function EspLibrary.AddEsp(player)
    if (player == localPlayer) then
        return
    end

    local objects = {
        arrow = create("Triangle", {
            Thickness = 1,
        }),
        arrowOutline = create("Triangle", {
            Thickness = 1,
        }),
        top = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = Color3.fromRGB(),
            Font = 2,
        }),
        side = create("Text", {
            Size = 13,
            Outline = true,
            OutlineColor = Color3.fromRGB(),
            Font = 2,
        }),
        bottom = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = Color3.fromRGB(),
            Font = 2,
        }),
        boxFill = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        boxOutline = create("Square", {
            Thickness = 3,
            Color = Color3.fromRGB()
        }),
        box = create("Square", {
            Thickness = 1
        }),
        healthBarOutline = create("Square", {
            Thickness = 1,
            Color = Color3.fromRGB(),
            Filled = true
        }),
        healthBar = create("Square", {
            Thickness = 1,
            Filled = true
        }),
        line = create("Line")
    }

    EspLibrary.espCache[player] = objects
end

function EspLibrary.RemoveEsp(player)
    local espCache = EspLibrary.espCache[player]

    if (espCache) then
        EspLibrary.espCache[player] = nil

        for index, object in pairs(espCache) do
            espCache[index] = nil
            object:Remove()
        end
    end
end

function EspLibrary.Unload()
    for _, connection in pairs(EspLibrary.conns) do
        connection:Disconnect()
    end

    for _, player in pairs(players:GetPlayers()) do
        EspLibrary.RemoveEsp(player)
    end

    for _, object in pairs(EspLibrary.drawings) do
        object:Remove()
    end

    for _, object in pairs(EspLibrary.instances) do
        object:Destroy()
    end

    runService:UnbindFromRenderStep("esp_rendering")
end

function EspLibrary.Init()
    insert(EspLibrary.conns, players.PlayerAdded:Connect(function(player)
        EspLibrary.AddEsp(player)
    end))

    insert(EspLibrary.conns, players.PlayerRemoving:Connect(function(player)
        EspLibrary.RemoveEsp(player)
    end))

    for _, player in pairs(players:GetPlayers()) do
        EspLibrary.AddEsp(player)
    end

    runService:BindToRenderStep("esp_rendering", Enum.RenderPriority.Camera.Value + 1, function()
        for player, objects in pairs(EspLibrary.espCache) do
            local character, torso = EspLibrary.GetCharacter(player)

            if (character and torso) then
                local onScreen, size, position, torsoPosition = EspLibrary.GetBoundingBox(torso)
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude
                local canShow, enabled = onScreen and (size and position), EspLibrary.options.enabled
                local team, teamColor = EspLibrary.GetTeam(player)
                local color = EspLibrary.options.teamColor and teamColor or nil

                if (EspLibrary.options.fillColor ~= nil) then
                    color = EspLibrary.options.fillColor
                end

                if (table.find(EspLibrary.whitelist, player.Name)) then
                    color = EspLibrary.options.whitelistColor
                end

                if (table.find(EspLibrary.blacklist, player.Name)) then
                    enabled = false
                end

                if (EspLibrary.options.limitDistance and distance > EspLibrary.options.maxDistance) then
                    enabled = false
                end

                if (EspLibrary.options.visibleOnly and not EspLibrary.VisibleCheck(character, torso.Position)) then
                    enabled = false
                end

                if (EspLibrary.options.teamCheck and (team == EspLibrary.GetTeam(localPlayer))) then
                    enabled = false
                end

                local viewportSize = currentCamera.ViewportSize

                local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2)
                local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, torso.Position) * vector3New(1, 0, 1)).Unit
                local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1))
                local rightVector = vector2New(crossVector.X, crossVector.Z)

                local arrowRadius, arrowSize = EspLibrary.options.outOfViewArrowsRadius, EspLibrary.options.outOfViewArrowsSize
                local arrowPosition = screenCenter + vector2New(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius
                local arrowDirection = (arrowPosition - screenCenter).Unit

                local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize

                local health, maxHealth = EspLibrary.GetHealth(player, character)
                local healthBarSize = round(vector2New(EspLibrary.options.healthBarsSize, -(size.Y * (health / maxHealth))))
                local healthBarPosition = round(vector2New(position.X - (3 + healthBarSize.X), position.Y + size.Y))

                local origin = EspLibrary.options.tracerOrigin
                local show = canShow and enabled

                objects.arrow.Visible = (not canShow and enabled) and EspLibrary.options.outOfViewArrows
                objects.arrow.Filled = EspLibrary.options.outOfViewArrowsFilled
                objects.arrow.Transparency = EspLibrary.options.outOfViewArrowsTransparency
                objects.arrow.Color = color or EspLibrary.options.espColor
                objects.arrow.PointA = pointA
                objects.arrow.PointB = pointB
                objects.arrow.PointC = pointC

                objects.arrowOutline.Visible = (not canShow and enabled) and EspLibrary.options.outOfViewArrowsOutline
                objects.arrowOutline.Filled = EspLibrary.options.outOfViewArrowsOutlineFilled
                objects.arrowOutline.Transparency = EspLibrary.options.outOfViewArrowsOutlineTransparency
                objects.arrowOutline.Color = color or EspLibrary.options.outOfViewArrowsOutlineColor
                objects.arrowOutline.PointA = pointA
                objects.arrowOutline.PointB = pointB
                objects.arrowOutline.PointC = pointC

                objects.top.Visible = show and EspLibrary.options.names
                objects.top.Font = EspLibrary.options.font
                objects.top.Size = EspLibrary.options.fontSize
                objects.top.Transparency = EspLibrary.options.nameTransparency
                objects.top.Color = color or EspLibrary.options.espColor
                objects.top.Text = player.Name
                objects.top.Position = round(position + vector2New(size.X * 0.5, -(objects.top.TextBounds.Y + 2)))

                objects.side.Visible = show and EspLibrary.options.healthText
                objects.side.Font = EspLibrary.options.font
                objects.side.Size = EspLibrary.options.fontSize
                objects.side.Transparency = EspLibrary.options.healthTextTransparency
                objects.side.Color = color or EspLibrary.options.espColor
                objects.side.Text = health .. EspLibrary.options.healthTextSuffix
                objects.side.Position = round(position + vector2New(size.X + 3, -3))

                objects.bottom.Visible = show and EspLibrary.options.distance
                objects.bottom.Font = EspLibrary.options.font
                objects.bottom.Size = EspLibrary.options.fontSize
                objects.bottom.Transparency = EspLibrary.options.distanceTransparency
                objects.bottom.Color = color or EspLibrary.options.espColor
                objects.bottom.Text = tostring(round(distance)) .. EspLibrary.options.distanceSuffix
                objects.bottom.Position = round(position + vector2New(size.X * 0.5, size.Y + 1))

                objects.box.Visible = show and EspLibrary.options.boxes
                objects.box.Color = color or EspLibrary.options.espColor
                objects.box.Transparency = EspLibrary.options.boxesTransparency
                objects.box.Size = size
                objects.box.Position = position

                objects.boxOutline.Visible = show and EspLibrary.options.boxes
                objects.boxOutline.Transparency = EspLibrary.options.boxesTransparency
                objects.boxOutline.Size = size
                objects.boxOutline.Position = position

                objects.boxFill.Visible = show and EspLibrary.options.boxFill
                objects.boxFill.Color = color or EspLibrary.options.espColor
                objects.boxFill.Transparency = EspLibrary.options.boxFillTransparency
                objects.boxFill.Size = size
                objects.boxFill.Position = position

                objects.healthBar.Visible = show and EspLibrary.options.healthBars
                objects.healthBar.Color = color or EspLibrary.options.healthBarsColor
                objects.healthBar.Transparency = EspLibrary.options.healthBarsTransparency
                objects.healthBar.Size = healthBarSize
                objects.healthBar.Position = healthBarPosition

                objects.healthBarOutline.Visible = show and EspLibrary.options.healthBars
                objects.healthBarOutline.Transparency = EspLibrary.options.healthBarsTransparency
                objects.healthBarOutline.Size = round(vector2New(healthBarSize.X, -size.Y) + vector2New(2, -2))
                objects.healthBarOutline.Position = healthBarPosition - vector2New(1, -1)

                objects.line.Visible = show and EspLibrary.options.tracers
                objects.line.Color = color or EspLibrary.options.espColor
                objects.line.Transparency = EspLibrary.options.tracerTransparency
                objects.line.From =
                    origin == "Mouse" and userInputService:GetMouseLocation() or
                    origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                    origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y)
                objects.line.To = torsoPosition
            else
                for _, object in pairs(objects) do
                    object.Visible = false
                end
            end
        end
    end)
end

return EspLibrary
