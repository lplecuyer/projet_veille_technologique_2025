local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassModels = ReplicatedStorage:WaitForChild("ClassModels")
local charLoadedRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CharacterLoaded")

Players.CharacterAutoLoads = false

local classRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ClassAssignmentRequest")

-- Fonction pour souder un modèle
local function weldModel(model)
	print("[weldModel] Welding model:", model.Name)
	if not model.PrimaryPart then
		local fallback = model:FindFirstChildWhichIsA("BasePart")
		if fallback then
			model.PrimaryPart = fallback
			print("[weldModel] Fallback PrimaryPart:", fallback.Name)
		else
			warn("[weldModel] Aucun BasePart trouvé pour", model.Name)
			return
		end
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = part
			weld.Parent = model.PrimaryPart
			part.Anchored = false
		end
	end

	model.PrimaryPart.Anchored = false
	print("[weldModel] Welding completed for", model.Name)
end

-- Fonction principale
local function setupPlayerClass(player, className)
	print("[setupPlayerClass] Setting up class for", player.Name, "→", className)

	player:SetAttribute("Class", className)

	local model = ClassModels:FindFirstChild(className)
	if not model or not model:IsA("Model") then
		warn("[setupPlayerClass] Aucun modèle pour la classe", className)
		return
	end

	local clone = model:Clone()
	clone.Name = player.Name
	print("[setupPlayerClass] Clone fait:", clone.Name)

	local humanoid = clone:FindFirstChildWhichIsA("Humanoid")
	local hrp = clone:FindFirstChild("HumanoidRootPart")

	if not humanoid then
		warn("[setupPlayerClass] Humanoid manquant dans", className)
	end
	if not hrp then
		warn("[setupPlayerClass] HumanoidRootPart manquant dans", className)
	end
	if not humanoid or not hrp then return end

	local spawnsFolder = workspace:FindFirstChild("ArenaSpawns")
	local spawnName = "Spawn" .. tostring(#Players:GetPlayers())
	local spawnPart = spawnsFolder and spawnsFolder:FindFirstChild(spawnName)
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)

	print("[setupPlayerClass] Spawn:", spawnName, "→", spawnCFrame.Position)

	clone:SetPrimaryPartCFrame(spawnCFrame + Vector3.new(0, 3, 0))

	-- Knight special shield
	if className == "Knight" then
		print("[setupPlayerClass] Knight détecté, ajout du bouclier.")
		local leftArm = clone:FindFirstChild("Left Arm")
		if leftArm then
			local shield = leftArm:FindFirstChild("Shield")
			if shield and shield:IsA("Model") then
				print("[setupPlayerClass] Shield trouvé, welding en cours...")
				weldModel(shield)

				if shield.PrimaryPart then
					local motor = Instance.new("Motor6D")
					motor.Name = "ShieldAttach"
					motor.Part0 = leftArm
					motor.Part1 = shield.PrimaryPart
					motor.C0 = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), math.rad(90))
					motor.Parent = leftArm
					shield.PrimaryPart.Anchored = false
					print("[setupPlayerClass] Shield attaché avec Motor6D.")
				else
					warn("[setupPlayerClass] Shield sans PrimaryPart.")
				end
			else
				warn("[setupPlayerClass] Pas de shield sur le bras.")
			end
		else
			warn("[setupPlayerClass] Pas de bras gauche trouvé.")
		end
	end

	-- Finalisation
	clone.Parent = workspace
	player.Character = clone
	print("[setupPlayerClass] Character assigné à", player.Name)

	charLoadedRemote:FireClient(player, clone)
	print("[setupPlayerClass] RemoteEvent envoyé au client")

end

classRemote.OnServerEvent:Connect(function(player, className)
	if RunService:IsStudio() then
		className = "Knight"
		setupPlayerClass(player, className)
	else
		if className then
			print("[Arena] Reçu class depuis client:", player.Name, className)
			setupPlayerClass(player, className)
		else
			warn("[Arena] Classe manquante depuis client:", player.Name)
		end
	end
end)



