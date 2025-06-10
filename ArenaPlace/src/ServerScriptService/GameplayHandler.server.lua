local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundSpawns = workspace:WaitForChild("ArenaSpawns")

local PlayerLives = {}
local UpdateHearts = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateHearts")

local CharacterSpawner = require(game.ServerScriptService:WaitForChild("CharacterRespawn"))
local classRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ClassAssignmentRequest")

-- Associe les spawns par ordre de UserId
local function getSpawnForPlayer(player)
	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)

	if player == players[1] then
		return RoundSpawns:WaitForChild("Spawn1")
	else
		return RoundSpawns:WaitForChild("Spawn2")
	end
end

local function TeleportToSpawn(player)
	local spawnPart = getSpawnForPlayer(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character:SetPrimaryPartCFrame(spawnPart.CFrame + Vector3.new(0, 3, 0))
	end
end

local function RespawnRound(deadPlayer)
	if PlayerLives[deadPlayer] <= 0 then return end

	local className = deadPlayer:GetAttribute("Class")
	if not className then warn("Pas de classe pour " .. deadPlayer.Name); return end

	-- Respawn le joueur avec sa classe
	task.delay(1, function()
		CharacterSpawner.setupPlayerClass(deadPlayer, className)
		task.wait(0.2)
		TeleportToSpawn(deadPlayer)

		-- TP l’autre joueur aussi
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= deadPlayer then
				TeleportToSpawn(p)
			end
		end

		print("Nouvelle manche lancée")
	end)
end

classRemote.OnServerEvent:Connect(function(player, className)
	if className then
		player:SetAttribute("Class", className)
		CharacterSpawner.setupPlayerClass(player, className)
	else
		warn("Classe manquante pour", player.Name)
	end
end)


-- Gestion de la mort
Players.PlayerAdded:Connect(function(player)
	PlayerLives[player] = 3

	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			PlayerLives[player] -= 1
			UpdateHearts:FireAllClients(player, PlayerLives[player])

			if PlayerLives[player] <= 0 then
				print(player.Name .. " est éliminé.")
				-- Ici, on peut appeler EndMatch(player)
			else
				RespawnRound(player)
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerLives[player] = nil
end)
