local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MenuGui")

-- UI sections
local mainMenu = gui:WaitForChild("MainMenu")
local classSelection = gui:WaitForChild("ClassSelection")

-- Boutons
local startButton = mainMenu:WaitForChild("StartButton")
local chooseClassButton = mainMenu:WaitForChild("ChooseClassButton")

local knightBtn = classSelection:WaitForChild("KnightButton")
local rogueBtn = classSelection:WaitForChild("RogueButton")

local selectedClass = nil

-- === FONCTION POUR AFFICHER UN MODELE DANS UN VIEWPORTFRAME ===
local function setupViewport(viewportFrame, modelName, angleOffset)
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local model = ReplicatedStorage:WaitForChild("ViewportModels"):WaitForChild(modelName):Clone()
	model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(angleOffset or 0), 0))
	model.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 2, -5), Vector3.new(0, 0, 0))
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera
end

-- === AFFICHER BATTLE VIEWPORT PRINCIPAL (DÉCOR GLOBAL) ===
do
	local viewport = gui.MainMenu:WaitForChild("BattleViewport")

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local knightModel = ReplicatedStorage:WaitForChild("ViewportModels"):WaitForChild("Knight"):Clone()
	local rogueModel = ReplicatedStorage:WaitForChild("ViewportModels"):WaitForChild("Rogue"):Clone()

	-- Position décorative
	knightModel:SetPrimaryPartCFrame(CFrame.new(5, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
	rogueModel:SetPrimaryPartCFrame(CFrame.new(-5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))

	knightModel.Parent = world
	rogueModel.Parent = world

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 3, -6.5), Vector3.new(0, 1.5, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

-- === AFFICHER LES CLASSES DANS LES BOUTONS ===
setupViewport(knightBtn:WaitForChild("KnightViewport"), "Knight", 0)
setupViewport(rogueBtn:WaitForChild("RogueViewport"), "Rogue", 0)

-- === UI Interaction ===

chooseClassButton.MouseButton1Click:Connect(function()
	mainMenu.Visible = false
	classSelection.Visible = true
end)

knightBtn.MouseButton1Click:Connect(function()
	selectedClass = "Knight"
end)

rogueBtn.MouseButton1Click:Connect(function()
	selectedClass = "Rogue"
end)

startButton.MouseButton1Click:Connect(function()
	if selectedClass then
		ReplicatedStorage:WaitForChild("StartMatch"):FireServer(selectedClass)
	else
		warn("Choisis une classe d'abord.")
	end
end)
