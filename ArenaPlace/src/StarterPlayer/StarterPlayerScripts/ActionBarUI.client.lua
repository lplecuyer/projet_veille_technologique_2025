-- Barre d'actions en bas de l'écran (style RPG) : une case par action avec son cooldown
-- Les cooldowns viennent de CombatState, écrit par AnimateOverride
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CombatState = require(script.Parent:WaitForChild("CombatState"))

local localPlayer = Players.LocalPlayer

-- Remplacer par les ID obtenus après l'import des PNG de assets/ui dans Roblox
local ACTIONS = {
	{ name = "Attack", label = "Attaque", key = "Clic G", icon = "rbxassetid://0" },
	{ name = "Parry", label = "Parry", key = "Clic D", icon = "rbxassetid://0" },
	{ name = "Dash", label = "Dash", key = "Q", icon = "rbxassetid://0" },
}

local SLOT_SIZE = 76
local GOLD = Color3.fromRGB(201, 162, 74)
local INK = Color3.fromRGB(22, 17, 14)
local READY_FLASH = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ActionBarGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "ActionBar"
bar.AutomaticSize = Enum.AutomaticSize.XY
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -20)
bar.BackgroundTransparency = 1
bar.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 14)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function createSlot(action, order)
	-- Case + nom de l'action en dessous
	local holder = Instance.new("Frame")
	holder.Name = action.name
	holder.LayoutOrder = order
	holder.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE + 22)
	holder.BackgroundTransparency = 1
	holder.Parent = bar

	local slot = Instance.new("Frame")
	slot.Name = "Slot"
	slot.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	slot.BackgroundColor3 = INK
	slot.BackgroundTransparency = 0.15
	slot.Parent = holder
	addCorner(slot, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = slot

	local scale = Instance.new("UIScale")
	scale.Parent = slot

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, -14, 1, -14)
	icon.Position = UDim2.fromOffset(7, 7)
	icon.BackgroundTransparency = 1
	icon.Parent = slot

	local hasImage = action.icon ~= "rbxassetid://0"
	if hasImage then
		icon.Image = action.icon
	else
		-- Nom de l'action en secours tant que l'icône n'a pas d'ID
		local fallback = Instance.new("TextLabel")
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1
		fallback.Text = action.label
		fallback.TextColor3 = GOLD
		fallback.Font = Enum.Font.Fantasy
		fallback.TextSize = 16
		fallback.Parent = icon
	end

	-- Voile sombre qui descend à mesure que le cooldown se termine
	local overlay = Instance.new("Frame")
	overlay.Name = "Cooldown"
	overlay.AnchorPoint = Vector2.new(0, 1)
	overlay.Position = UDim2.fromScale(0, 1)
	overlay.Size = UDim2.fromScale(1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 2
	overlay.Parent = slot
	addCorner(overlay, 10)

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.fromScale(1, 1)
	timer.BackgroundTransparency = 1
	timer.TextColor3 = Color3.new(1, 1, 1)
	timer.TextStrokeTransparency = 0.2
	timer.Font = Enum.Font.GothamBold
	timer.TextSize = 26
	timer.Text = ""
	timer.ZIndex = 3
	timer.Parent = slot

	-- Touche dans le coin haut-gauche
	local keyBadge = Instance.new("TextLabel")
	keyBadge.Name = "Key"
	keyBadge.AutomaticSize = Enum.AutomaticSize.X
	keyBadge.Size = UDim2.fromOffset(18, 18)
	keyBadge.Position = UDim2.fromOffset(-6, -6)
	keyBadge.BackgroundColor3 = GOLD
	keyBadge.TextColor3 = INK
	keyBadge.Font = Enum.Font.GothamBold
	keyBadge.TextSize = 12
	keyBadge.Text = action.key
	keyBadge.ZIndex = 4
	keyBadge.Parent = slot
	addCorner(keyBadge, 5)

	local badgePadding = Instance.new("UIPadding")
	badgePadding.PaddingLeft = UDim.new(0, 5)
	badgePadding.PaddingRight = UDim.new(0, 5)
	badgePadding.Parent = keyBadge

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Label"
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.Position = UDim2.fromOffset(0, SLOT_SIZE + 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Font = Enum.Font.Fantasy
	nameLabel.TextSize = 16
	nameLabel.Text = action.label
	nameLabel.Parent = holder

	return {
		stroke = stroke,
		scale = scale,
		overlay = overlay,
		timer = timer,
		wasOnCooldown = false,
	}
end

-- Pastilles du combo dans le bas de la case d'attaque
local function createComboPips(slot)
	local row = Instance.new("Frame")
	row.Name = "ComboPips"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -5)
	row.Size = UDim2.fromOffset(46, 10)
	row.BackgroundTransparency = 1
	row.ZIndex = 4
	row.Parent = slot

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = row

	local pips = {}
	for i = 1, 3 do
		local pip = Instance.new("Frame")
		pip.Size = UDim2.fromOffset(10, 10)
		pip.LayoutOrder = i
		pip.BackgroundColor3 = INK
		pip.ZIndex = 4
		pip.Parent = row
		addCorner(pip, 5)

		local pipStroke = Instance.new("UIStroke")
		pipStroke.Color = GOLD
		pipStroke.Thickness = 1.5
		pipStroke.Parent = pip

		pips[i] = pip
	end
	return pips
end

local slots = {}
for order, action in ipairs(ACTIONS) do
	slots[action.name] = createSlot(action, order)
end
local comboPips = createComboPips(bar.Attack.Slot)

-- Petit flash doré + rebond quand l'action redevient dispo
local function flashReady(ui)
	ui.stroke.Color = Color3.new(1, 1, 1)
	ui.stroke.Thickness = 4
	ui.scale.Scale = 1.12
	TweenService:Create(ui.stroke, READY_FLASH, { Color = GOLD, Thickness = 2 }):Play()
	TweenService:Create(ui.scale, READY_FLASH, { Scale = 1 }):Play()
end

RunService.RenderStepped:Connect(function()
	for name, ui in pairs(slots) do
		local remaining, duration = CombatState.getCooldown(name)
		local onCooldown = remaining > 0 and duration > 0

		if onCooldown then
			ui.overlay.Size = UDim2.fromScale(1, remaining / duration)
			ui.timer.Text = remaining < 1 and string.format("%.1f", remaining) or tostring(math.ceil(remaining))
		elseif ui.wasOnCooldown then
			ui.overlay.Size = UDim2.fromScale(1, 0)
			ui.timer.Text = ""
			flashReady(ui)
		end
		ui.wasOnCooldown = onCooldown
	end

	for i, pip in ipairs(comboPips) do
		pip.BackgroundColor3 = i <= CombatState.comboStep and GOLD or INK
	end
end)
