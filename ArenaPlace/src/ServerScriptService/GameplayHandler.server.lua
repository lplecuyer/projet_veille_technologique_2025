local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundSpawns = workspace:WaitForChild("ArenaSpawns")

local PlayerLives = {}
local UpdateHearts = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateHearts")
local classRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ClassAssignmentRequest")

local CharacterSpawner = require(game.ServerScriptService:WaitForChild("CharacterRespawn"))

local showWinnerEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShowWinnerLabel")
local Winner = nil

-- 🔁 Obtenir le bon spawn selon l'ordre des UserId
local function getSpawnForPlayer(player)
	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)

	if player == players[1] then
		return RoundSpawns:WaitForChild("Spawn1")
	else
		return RoundSpawns:WaitForChild("Spawn2")
	end
end

-- 📦 Fonction utilitaire de téléport
local function TeleportToSpawn(player)
	local spawnPart = getSpawnForPlayer(player)
	local character = player.Character
	if character and character.PrimaryPart then
		character:SetPrimaryPartCFrame(spawnPart.CFrame + Vector3.new(0, 3, 0))
	end
end

-- 🔁 Respawn round
local function RespawnRound(player)
	if PlayerLives[player] <= 0 then return end

	local className = player:GetAttribute("Class")
	if not className then
		warn("Pas de classe pour " .. player.Name)
		return
	end

	task.delay(1, function()
		task.wait(0.2)
		TeleportToSpawn(player)

		-- TP les autres joueurs aussi
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				TeleportToSpawn(p)
			end
		end

		print("[Combat] Nouvelle manche lancée")
	end)
end

-- 🧠 Logic principale DBNO (Down But Not Out)
local function handleCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local rootPart = character:WaitForChild("HumanoidRootPart")

	humanoid.HealthChanged:Connect(function(health)
		print(health)
		if health > 0 then return end

		if not player:GetAttribute("SimulatedDead") then
			print("test")
			player:SetAttribute("SimulatedDead", true)

			PlayerLives[player] -= 1
			UpdateHearts:FireAllClients(player, PlayerLives[player])

			print("[Combat] Simulation de la mort de", player.Name)

			-- Empêche la vraie mort
			humanoid.Health = 1
			player:SetAttribute("IsInvincible", true)

			if PlayerLives[player] <= 0 then
				
				-- Cherche le joueur encore vivant
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= player and PlayerLives[p] and PlayerLives[p] > 0 then
						Winner = p
						break
					end
				end

				if Winner then
					showWinnerEvent:FireAllClients(Winner.Name .. " a gagné!")
				end
			end


			task.delay(0.25, function()
				RespawnRound(player)
				humanoid.Health = humanoid.MaxHealth
				player:SetAttribute("IsInvincible", false)
				player:SetAttribute("SimulatedDead", false)
			end)
		end
	end)
end

local function handlePlayer(player)
	PlayerLives[player] = 3

	-- Démarrage immédiat si Character déjà présent
	if player.Character and player.Character.Parent then
		handleCharacter(player.Character)
	end

	player.CharacterAdded:Connect(handleCharacter)
end

for _, player in Players:GetPlayers() do
	handlePlayer(player)
end

Players.PlayerAdded:Connect(handlePlayer)

Players.PlayerRemoving:Connect(function(player)
	PlayerLives[player] = nil
end)

-- Classe assignée par RemoteEvent
classRemote.OnServerEvent:Connect(function(player, className)
	if className then
		player:SetAttribute("Class", className)
		CharacterSpawner.setupPlayerClass(player, className)
	else
		warn("Classe manquante pour", player.Name)
	end
end)
