-- Barres de vie des joueurs en haut de l'écran, avec l'icône de leur classe et leurs vies (cœurs)
-- Slot 1 à gauche, slot 2 à droite (miroir), construit entièrement en code
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

-- Remplacer par les ID obtenus après l'import des PNG de assets/ui dans Roblox
local CLASS_ICONS = {
	Knight = "rbxassetid://0",
	Rogue = "rbxassetid://0",
}
local HEART_FULL = "rbxassetid://0"
local HEART_EMPTY = "rbxassetid://0"

local MAX_SLOTS = 2
local PANEL_SIZE = UDim2.fromOffset(340, 92)
local ICON_SIZE = 72
local BAR_HEIGHT = 22
local MAX_LIVES = 3
local HEART_SIZE = 24

local COLOR_HIGH = Color3.fromRGB(86, 196, 92)
local COLOR_MID = Color3.fromRGB(230, 180, 60)
local COLOR_LOW = Color3.fromRGB(210, 60, 50)
local GOLD = Color3.fromRGB(201, 162, 74)
local INK = Color3.fromRGB(22, 17, 14)

local FILL_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DAMAGE_TWEEN = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.3)
local HEART_POP = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- On remplace la barre de vie par défaut de Roblox
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HealthBarsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local function healthColor(ratio)
	if ratio > 0.5 then
		return COLOR_MID:Lerp(COLOR_HIGH, (ratio - 0.5) * 2)
	end
	return COLOR_LOW:Lerp(COLOR_MID, ratio * 2)
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
end

-- Crée le panneau d'un slot ; le slot 2 est en miroir (icône à droite)
local function createPanel(slot)
	local mirrored = slot == 2

	local panel = Instance.new("Frame")
	panel.Name = "Player" .. slot .. "Health"
	panel.Size = PANEL_SIZE
	panel.AnchorPoint = Vector2.new(mirrored and 0 or 1, 0)
	panel.Position = UDim2.new(0.5, mirrored and 24 or -24, 0, 12)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = screenGui

	local icon = Instance.new("ImageLabel")
	icon.Name = "ClassIcon"
	icon.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
	icon.AnchorPoint = Vector2.new(mirrored and 1 or 0, 0)
	icon.Position = UDim2.fromScale(mirrored and 1 or 0, 0)
	icon.BackgroundTransparency = 1
	icon.ZIndex = 3
	icon.Parent = panel

	-- Lettre de secours tant que l'icône n'a pas d'ID
	local fallback = Instance.new("TextLabel")
	fallback.Name = "Fallback"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.BackgroundColor3 = INK
	fallback.TextColor3 = GOLD
	fallback.Font = Enum.Font.Fantasy
	fallback.TextScaled = true
	fallback.ZIndex = 2
	fallback.Parent = icon
	addCorner(fallback, ICON_SIZE / 2)
	addStroke(fallback, GOLD, 3)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, -(ICON_SIZE + 12), 0, 24)
	nameLabel.AnchorPoint = Vector2.new(mirrored and 0 or 1, 0)
	nameLabel.Position = UDim2.new(mirrored and 0 or 1, 0, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Font = Enum.Font.Fantasy
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = mirrored and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	nameLabel.Parent = panel

	local barBack = Instance.new("Frame")
	barBack.Name = "Bar"
	barBack.Size = UDim2.new(1, -(ICON_SIZE + 12), 0, BAR_HEIGHT)
	barBack.AnchorPoint = Vector2.new(mirrored and 0 or 1, 0)
	barBack.Position = UDim2.new(mirrored and 0 or 1, 0, 0, 38)
	barBack.BackgroundColor3 = INK
	barBack.ClipsDescendants = true
	barBack.Parent = panel
	addCorner(barBack, 6)
	addStroke(barBack, GOLD, 2)

	-- Traînée blanche qui rattrape la barre après un coup
	local damage = Instance.new("Frame")
	damage.Name = "Damage"
	damage.Size = UDim2.fromScale(1, 1)
	damage.AnchorPoint = Vector2.new(mirrored and 1 or 0, 0)
	damage.Position = UDim2.fromScale(mirrored and 1 or 0, 0)
	damage.BackgroundColor3 = Color3.fromRGB(255, 240, 220)
	damage.BorderSizePixel = 0
	damage.Parent = barBack
	addCorner(damage, 6)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.AnchorPoint = damage.AnchorPoint
	fill.Position = damage.Position
	fill.BackgroundColor3 = COLOR_HIGH
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = barBack
	addCorner(fill, 6)

	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.35),
	})
	shine.Parent = fill

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HealthText"
	hpLabel.Size = UDim2.fromScale(1, 1)
	hpLabel.BackgroundTransparency = 1
	hpLabel.TextColor3 = Color3.new(1, 1, 1)
	hpLabel.TextStrokeTransparency = 0.3
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.TextSize = 14
	hpLabel.ZIndex = 3
	hpLabel.Parent = barBack

	-- Cœurs sous la barre, alignés du même côté qu'elle
	local heartsRow = Instance.new("Frame")
	heartsRow.Name = "Lives"
	heartsRow.Size = UDim2.new(1, -(ICON_SIZE + 12), 0, HEART_SIZE)
	heartsRow.AnchorPoint = Vector2.new(mirrored and 0 or 1, 0)
	heartsRow.Position = UDim2.new(mirrored and 0 or 1, 0, 0, 66)
	heartsRow.BackgroundTransparency = 1
	heartsRow.Parent = panel

	local heartsLayout = Instance.new("UIListLayout")
	heartsLayout.FillDirection = Enum.FillDirection.Horizontal
	heartsLayout.HorizontalAlignment = mirrored and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	heartsLayout.Padding = UDim.new(0, 4)
	heartsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	heartsLayout.Parent = heartsRow

	local hearts = {}
	for i = 1, MAX_LIVES do
		local heart = Instance.new("ImageLabel")
		heart.Name = "Heart" .. i
		heart.Size = UDim2.fromOffset(HEART_SIZE, HEART_SIZE)
		-- Ordre inversé pour le slot 2 : chez les deux, les cœurs se vident à partir du centre de l'écran
		heart.LayoutOrder = mirrored and (MAX_LIVES - i) or i
		heart.BackgroundTransparency = 1
		heart.Parent = heartsRow

		local heartScale = Instance.new("UIScale")
		heartScale.Parent = heart

		-- ♥ en secours tant que les images n'ont pas d'ID
		local heartFallback = Instance.new("TextLabel")
		heartFallback.Name = "Fallback"
		heartFallback.Size = UDim2.fromScale(1, 1)
		heartFallback.BackgroundTransparency = 1
		heartFallback.Text = "♥"
		heartFallback.TextScaled = true
		heartFallback.TextStrokeColor3 = GOLD
		heartFallback.TextStrokeTransparency = 0
		heartFallback.Font = Enum.Font.GothamBold
		heartFallback.Parent = heart

		hearts[i] = { image = heart, scale = heartScale, fallback = heartFallback }
	end

	return {
		panel = panel,
		icon = icon,
		fallback = fallback,
		nameLabel = nameLabel,
		fill = fill,
		damage = damage,
		hpLabel = hpLabel,
		hearts = hearts,
		lives = MAX_LIVES,
	}
end

local panels = {}
for slot = 1, MAX_SLOTS do
	panels[slot] = createPanel(slot)
end

local function setHealth(ui, health, maxHealth, instant)
	local ratio = maxHealth > 0 and math.clamp(health / maxHealth, 0, 1) or 0
	local size = UDim2.fromScale(ratio, 1)

	ui.hpLabel.Text = string.format("%d / %d", math.ceil(health), maxHealth)

	if instant then
		ui.fill.Size = size
		ui.damage.Size = size
		ui.fill.BackgroundColor3 = healthColor(ratio)
		return
	end

	TweenService:Create(ui.fill, FILL_TWEEN, { Size = size, BackgroundColor3 = healthColor(ratio) }):Play()
	-- En cas de soin, la traînée suit tout de suite ; en cas de dégâts, elle rattrape avec un délai
	if ratio >= ui.damage.Size.X.Scale then
		ui.damage.Size = size
	else
		TweenService:Create(ui.damage, DAMAGE_TWEEN, { Size = size }):Play()
	end
end

local function setClass(ui, className)
	local image = className and CLASS_ICONS[className]
	local hasImage = image ~= nil and image ~= "rbxassetid://0"
	ui.icon.Image = hasImage and image or ""
	ui.fallback.Visible = not hasImage
	ui.fallback.Text = className and className:sub(1, 1) or "?"
end

local function setLives(ui, lives, animate)
	local hasImages = HEART_FULL ~= "rbxassetid://0" and HEART_EMPTY ~= "rbxassetid://0"

	for i, heart in ipairs(ui.hearts) do
		local full = i <= lives
		heart.image.Image = hasImages and (full and HEART_FULL or HEART_EMPTY) or ""
		heart.fallback.Visible = not hasImages
		heart.fallback.TextColor3 = full and Color3.fromRGB(220, 50, 45) or INK

		-- Le cœur qui vient d'être perdu fait un petit rebond
		if animate and not full and i <= ui.lives then
			heart.scale.Scale = 1.6
			TweenService:Create(heart.scale, HEART_POP, { Scale = 1 }):Play()
		end
	end
	ui.lives = lives
end

-- Connexions du joueur affiché dans chaque slot, pour pouvoir les couper
local slotConnections = {}

local function clearSlot(slot)
	for _, conn in ipairs(slotConnections[slot] or {}) do
		conn:Disconnect()
	end
	slotConnections[slot] = nil
	panels[slot].panel.Visible = false
end

local function bindCharacter(ui, connections, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	setHealth(ui, humanoid.Health, humanoid.MaxHealth, true)
	table.insert(connections, humanoid.HealthChanged:Connect(function(health)
		setHealth(ui, health, humanoid.MaxHealth, false)
	end))
	table.insert(connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		setHealth(ui, humanoid.Health, humanoid.MaxHealth, true)
	end))
end

local function bindPlayer(player)
	local slot = player:GetAttribute("Slot")
	if not (slot and panels[slot]) then return end

	clearSlot(slot)
	local ui = panels[slot]
	local connections = {}
	slotConnections[slot] = connections

	ui.nameLabel.Text = player.DisplayName
	setClass(ui, player:GetAttribute("Class"))
	setLives(ui, player:GetAttribute("Lives") or MAX_LIVES, false)
	ui.panel.Visible = true

	table.insert(connections, player:GetAttributeChangedSignal("Class"):Connect(function()
		setClass(ui, player:GetAttribute("Class"))
	end))
	table.insert(connections, player:GetAttributeChangedSignal("Lives"):Connect(function()
		setLives(ui, player:GetAttribute("Lives") or 0, true)
	end))
	table.insert(connections, player.CharacterAdded:Connect(function(character)
		bindCharacter(ui, connections, character)
	end))

	if player.Character then
		task.spawn(bindCharacter, ui, connections, player.Character)
	end
end

local function watchPlayer(player)
	-- Le slot est assigné par le serveur, parfois après l'arrivée du joueur côté client
	player:GetAttributeChangedSignal("Slot"):Connect(function()
		bindPlayer(player)
	end)
	bindPlayer(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

Players.PlayerRemoving:Connect(function(player)
	local slot = player:GetAttribute("Slot")
	if slot and panels[slot] then
		clearSlot(slot)
	end
end)
