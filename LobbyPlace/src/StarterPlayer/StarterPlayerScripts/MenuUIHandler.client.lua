local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MenuGui")

-- UI elements
local mainMenu = gui:WaitForChild("MainMenu")
local classSelection = gui:WaitForChild("ClassSelection")

local startButton = mainMenu:WaitForChild("StartButton")
local chooseClassButton = mainMenu:WaitForChild("ChooseClassButton")

local knightBtn = classSelection:WaitForChild("KnightButton")
local rogueBtn = classSelection:WaitForChild("RogueButton")
local backBtn = classSelection:WaitForChild("BackButton")
local selectClassBtn = classSelection:WaitForChild("SelectClassButton")

local errorLabel = gui:WaitForChild("ErrorLabel")
local selectedClassLabel = mainMenu:WaitForChild("SelectedClassLabel")

local selectedClass = nil
local confirmedClass = nil

-- === FONCTION POUR AFFICHER UN MODELE DANS UN VIEWPORTFRAME ===
local function setupViewport(viewportFrame, modelName, angleOffset)
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local model = ReplicatedStorage:WaitForChild("ViewportModels"):WaitForChild(modelName):Clone()
	model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(angleOffset or 0), 0))
	model.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 2, -5), Vector3.new(0, 1.5, 0))
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera
end

-- === AFFICHER LES CLASSES DANS LES BOUTONS ===
setupViewport(knightBtn:WaitForChild("KnightViewport"), "Knight", -15)
setupViewport(rogueBtn:WaitForChild("RogueViewport"), "Rogue", 15)

-- === AFFICHER LE DECOR PRINCIPAL (BattleViewport) ===
do
	local viewport = gui.MainMenu:WaitForChild("BattleViewport")

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local knightModel = ReplicatedStorage:WaitForChild("ViewportModels"):WaitForChild("Knight"):Clone()
	local rogueModel = ReplicatedStorage:WaitForChild("ViewportModels"):WaitForChild("Rogue"):Clone()

	knightModel:SetPrimaryPartCFrame(CFrame.new(5, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
	rogueModel:SetPrimaryPartCFrame(CFrame.new(-5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))

	knightModel.Parent = world
	rogueModel.Parent = world

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 3, -6.5), Vector3.new(0, 1.5, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

-- === GESTION VISUELLE DE LA SELECTION ===
local knightStroke = knightBtn:WaitForChild("UIStroke")
local rogueStroke = rogueBtn:WaitForChild("UIStroke")

local function updateButtonBorders()
	if selectedClass == "Knight" then
		knightStroke.Transparency = 0
		rogueStroke.Transparency = 1
	elseif selectedClass == "Rogue" then
		rogueStroke.Transparency = 0
		knightStroke.Transparency = 1
	else
		knightStroke.Transparency = 1
		rogueStroke.Transparency = 1
	end
end

-- === MESSAGE D’ERREUR ===
local function showError(text)
	errorLabel.Text = text
	errorLabel.Visible = true
	wait(2)
	errorLabel.Visible = false
end

-- === UI Events ===
chooseClassButton.MouseButton1Click:Connect(function()
	mainMenu.Visible = false
	classSelection.Visible = true
end)

backBtn.MouseButton1Click:Connect(function()
	mainMenu.Visible = true
	classSelection.Visible = false
	selectedClass = nil
	updateButtonBorders()
end)

knightBtn.MouseButton1Click:Connect(function()
	selectedClass = "Knight"
	selectedClassLabel.Text = "Selected class : Knight"
	updateButtonBorders()
end)

rogueBtn.MouseButton1Click:Connect(function()
	selectedClass = "Rogue"
	selectedClassLabel.Text = "Selected class : Rogue"
	updateButtonBorders()
end)

selectClassBtn.MouseButton1Click:Connect(function()
	if not selectedClass then
		showError("Please choose a class before proceeding.")
		return
	end
	confirmedClass = selectedClass
	mainMenu.Visible = true
	classSelection.Visible = false
end)

startButton.MouseButton1Click:Connect(function()
	print("test")
	if confirmedClass then
		print("test2")
		print(confirmedClass)
		ReplicatedStorage:WaitForChild("StartMatch"):FireServer(confirmedClass)
	else
		showError("You must choose a class")
	end
end)
