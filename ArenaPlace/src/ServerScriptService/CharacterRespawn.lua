-- CharacterSpawner : seule source de vérité pour les slots, les spawns et la création des personnages
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassModels = ReplicatedStorage:WaitForChild("ClassModels")

local MAX_SLOTS = 2

local module = {}

-- Donne au joueur le premier slot libre (1 ou 2), stocké dans l'attribut "Slot"
function module.assignSlot(player)
	local existing = player:GetAttribute("Slot")
	if existing then
		return existing
	end

	local taken = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local slot = p:GetAttribute("Slot")
		if slot then
			taken[slot] = true
		end
	end

	for slot = 1, MAX_SLOTS do
		if not taken[slot] then
			player:SetAttribute("Slot", slot)
			return slot
		end
	end

	warn("[CharacterSpawner] Arène pleine, aucun slot pour", player.Name)
	return nil
end

-- CFrame de spawn du slot, avec le perso tourné vers l'adversaire
function module.getSpawnCFrame(slot)
	local spawnsFolder = workspace:FindFirstChild("ArenaSpawns")
	local spawnPart = spawnsFolder and spawnsFolder:FindFirstChild("Spawn" .. slot)
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)

	return (spawnCFrame + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(slot == 1 and 90 or -90), 0)
end

-- Replace le personnage du joueur à son spawn
function module.teleportToSpawn(player)
	local slot = player:GetAttribute("Slot")
	local character = player.Character
	if slot and character then
		character:PivotTo(module.getSpawnCFrame(slot))
	end
end

function module.weldModel(model)
	if not model.PrimaryPart then
		local fallback = model:FindFirstChildWhichIsA("BasePart")
		if fallback then
			model.PrimaryPart = fallback
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
end

local function attachShield(clone)
	local leftArm = clone:FindFirstChild("Left Arm")
	if not leftArm then
		warn("[setupPlayerClass] Pas de bras gauche trouvé.")
		return
	end

	local shield = leftArm:FindFirstChild("Shield")
	if not (shield and shield:IsA("Model")) then
		warn("[setupPlayerClass] Pas de shield sur le bras.")
		return
	end

	module.weldModel(shield)
	if not shield.PrimaryPart then
		warn("[setupPlayerClass] Shield sans PrimaryPart.")
		return
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "ShieldAttach"
	motor.Part0 = leftArm
	motor.Part1 = shield.PrimaryPart
	motor.C0 = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), math.rad(90))
	motor.Parent = leftArm
end

-- Crée le personnage de la classe et l'assigne au joueur (une seule fois)
function module.setupPlayerClass(player, className)
	if player.Character then
		warn("[setupPlayerClass] Personnage déjà créé pour", player.Name)
		return
	end

	local slot = player:GetAttribute("Slot")
	if not slot then
		warn("[setupPlayerClass] Pas de slot pour", player.Name)
		return
	end

	local model = ClassModels:FindFirstChild(className)
	if not (model and model:IsA("Model")) then
		warn("[setupPlayerClass] Aucun modèle pour la classe", className)
		return
	end

	local clone = model:Clone()
	clone.Name = player.Name

	local humanoid = clone:FindFirstChildWhichIsA("Humanoid")
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then
		warn("[setupPlayerClass] Humanoid ou HumanoidRootPart manquant dans", className)
		clone:Destroy()
		return
	end

	-- Animator créé côté serveur pour que les animations se répliquent
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid
	end

	if className == "Knight" then
		attachShield(clone)
	end

	player:SetAttribute("Class", className)
	-- Bloqué jusqu'à la fin de la cinématique d'intro
	player:SetAttribute("MovementLocked", true)

	clone:PivotTo(module.getSpawnCFrame(slot))
	clone.Parent = workspace
	player.Character = clone
	print("[setupPlayerClass]", player.Name, "→", className, "(slot " .. slot .. ")")
end

return module
