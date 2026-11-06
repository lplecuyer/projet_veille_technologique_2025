local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("MenuGui")

local StartMatch = ReplicatedStorage:WaitForChild("StartMatch")
local ViewportModels = ReplicatedStorage:WaitForChild("ViewportModels")

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
local isSearching = false

-- === FONCTION POUR AFFICHER UN MODELE DANS UN VIEWPORTFRAME ===
local function setupViewport(viewportFrame, modelName, angleOffset)
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local model = ViewportModels:WaitForChild(modelName):Clone()
	model:PivotTo(CFrame.Angles(0, math.rad(angleOffset or 0), 0))
	model.Parent = worldModel

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 2, -5), Vector3.new(0, 1.5, 0))
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera
end

-- === AFFICHER LES CLASSES DANS LES BOUTONS ===
setupViewport(knightBtn:WaitForChild("KnightViewport"), "Knight", -15)
setupViewport(rogueBtn:WaitForChild("RogueViewport"), "Rogue", 15)

-- === AFFICHER LE DECOR PRINCIPAL (BattleViewport) ===
do
	local viewport = mainMenu:WaitForChild("BattleViewport")

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local knightModel = ViewportModels:WaitForChild("Knight"):Clone()
	local rogueModel = ViewportModels:WaitForChild("Rogue"):Clone()

	knightModel:PivotTo(CFrame.new(5, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
	rogueModel:PivotTo(CFrame.new(-5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))

	knightModel.Parent = world
	rogueModel.Parent = world

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 3, -6.5), Vector3.new(0, 1.5, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

-- === GESTION VISUELLE DE LA SELECTION ===
local knightStroke = knightBtn:WaitForChild("UIStroke")
local rogueStroke = rogueBtn:WaitForChild("UIStroke")

local function updateButtonBorders()
	knightStroke.Transparency = (selectedClass == "Knight") and 0 or 1
	rogueStroke.Transparency = (selectedClass == "Rogue") and 0 or 1
end

-- === MESSAGE D’ERREUR ===
local errorToken = 0

local function showError(text)
	-- Le token empêche un ancien délai de cacher un message plus récent
	errorToken += 1
	local myToken = errorToken

	errorLabel.Text = text
	errorLabel.Visible = true

	task.delay(2, function()
		if errorToken == myToken then
			errorLabel.Visible = false
		end
	end)
end

-- === UI Events ===
chooseClassButton.MouseButton1Click:Connect(function()
	mainMenu.Visible = false
	classSelection.Visible = true
	selectedClass = confirmedClass
	updateButtonBorders()
end)

backBtn.MouseButton1Click:Connect(function()
	mainMenu.Visible = true
	classSelection.Visible = false
	selectedClass = nil
	updateButtonBorders()
end)

knightBtn.MouseButton1Click:Connect(function()
	selectedClass = "Knight"
	updateButtonBorders()
end)

rogueBtn.MouseButton1Click:Connect(function()
	selectedClass = "Rogue"
	updateButtonBorders()
end)

selectClassBtn.MouseButton1Click:Connect(function()
	if not selectedClass then
		showError("Please choose a class before proceeding.")
		return
	end
	confirmedClass = selectedClass
	selectedClassLabel.Text = "Selected class : " .. confirmedClass
	mainMenu.Visible = true
	classSelection.Visible = false
end)

startButton.MouseButton1Click:Connect(function()
	if not confirmedClass then
		showError("You must choose a class")
		return
	end
	if isSearching then
		return
	end

	isSearching = true
	selectedClassLabel.Text = "Searching for an opponent..."
	StartMatch:FireServer(confirmedClass)
end)
