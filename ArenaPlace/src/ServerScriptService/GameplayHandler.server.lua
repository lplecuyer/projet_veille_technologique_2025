local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local showWinnerEvent = RemoteEvents:WaitForChild("ShowWinnerLabel")

local CharacterSpawner = require(ServerScriptService:WaitForChild("CharacterRespawn"))

local STARTING_LIVES = 3

local PlayerLives = {}
local matchOver = false

-- 🏆 Fin du match : on annonce le gagnant une seule fois et on bloque le combat
local function endMatch(winner)
	if matchOver then return end
	matchOver = true
	workspace:SetAttribute("MatchOver", true)

	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("MovementLocked", true)
		local humanoid = p.Character and p.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
		end
	end

	if winner then
		print("[Combat]", winner.Name, "a gagné le match")
		showWinnerEvent:FireAllClients(winner.Name .. " a gagné!")
	end
end

-- Le joueur encore en vie (autre que `loser`), s'il y en a un
local function findWinner(loser)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= loser and PlayerLives[p] and PlayerLives[p] > 0 then
			return p
		end
	end
	return nil
end

-- 🔁 Nouvelle manche : tout le monde retourne à son spawn
local function RespawnRound()
	task.wait(1.2)
	if matchOver then return end

	for _, p in ipairs(Players:GetPlayers()) do
		CharacterSpawner.teleportToSpawn(p)
	end

	print("[Combat] Nouvelle manche lancée")
end

-- 🧠 Logic principale DBNO (Down But Not Out)
local function handleCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	humanoid.HealthChanged:Connect(function(health)
		if health > 0 then return end
		if matchOver or player:GetAttribute("SimulatedDead") then return end
		if not PlayerLives[player] then return end

		player:SetAttribute("SimulatedDead", true)
		-- Bloque les dégâts pendant la transition
		player:SetAttribute("IsInvincible", true)

		-- Empêche la vraie mort
		humanoid.Health = 1

		PlayerLives[player] -= 1
		-- Attribut répliqué : HealthBarsUI affiche les cœurs de chaque joueur
		player:SetAttribute("Lives", PlayerLives[player])
		print("[Combat] Simulation de la mort de", player.Name, "- vies restantes :", PlayerLives[player])

		if PlayerLives[player] <= 0 then
			endMatch(findWinner(player))
			return
		end

		task.spawn(function()
			RespawnRound()
			humanoid.Health = humanoid.MaxHealth
			player:SetAttribute("IsInvincible", false)
			player:SetAttribute("SimulatedDead", false)
		end)
	end)
end

local function handlePlayer(player)
	PlayerLives[player] = STARTING_LIVES
	player:SetAttribute("Lives", STARTING_LIVES)

	player.CharacterAdded:Connect(handleCharacter)

	-- Le personnage peut déjà exister si MatchReciever l'a créé avant ce script
	if player.Character and player.Character.Parent then
		task.spawn(handleCharacter, player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	handlePlayer(player)
end
Players.PlayerAdded:Connect(handlePlayer)

-- Si un joueur quitte en plein match, l'autre gagne par forfait
Players.PlayerRemoving:Connect(function(player)
	PlayerLives[player] = nil

	if not matchOver and player:GetAttribute("Slot") then
		local winner = findWinner(player)
		if winner then
			endMatch(winner)
		end
	end
end)
