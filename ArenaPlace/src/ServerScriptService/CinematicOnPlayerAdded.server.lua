local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local cameraRemote = RemoteEvents:WaitForChild("StartCinematic")
local unlockRemote = RemoteEvents:WaitForChild("UnlockMovement")

local WALK_SPEED = 16
-- Si le client ne confirme jamais la fin de la cinématique, on débloque quand même
local UNLOCK_TIMEOUT = 10
-- En Studio, délai d'attente d'un 2e joueur avant de débloquer un joueur seul
local STUDIO_SOLO_DELAY = 6

local readyPlayers = {} -- joueurs dont le personnage est prêt, en ordre d'arrivée
local awaitingUnlock = {} -- [player] = true pendant la cinématique
local cinematicStarted = false

local function unlockPlayer(player)
	if not awaitingUnlock[player] then return end
	awaitingUnlock[player] = nil

	if workspace:GetAttribute("MatchOver") then return end

	player:SetAttribute("MovementLocked", false)
	local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = WALK_SPEED
	end
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	-- L'anim Idle est jouée par le client (AnimateOverride)
	humanoid.WalkSpeed = 0

	if cinematicStarted or table.find(readyPlayers, player) then return end
	table.insert(readyPlayers, player)

	-- Quand 2 joueurs sont prêts, on déclenche chez les deux
	if #readyPlayers == 2 then
		cinematicStarted = true
		local player1, player2 = readyPlayers[1], readyPlayers[2]

		for _, p in ipairs(readyPlayers) do
			awaitingUnlock[p] = true
			task.delay(UNLOCK_TIMEOUT, unlockPlayer, p)
		end

		cameraRemote:FireClient(player1, player2.Name)
		cameraRemote:FireClient(player2, player1.Name)
	elseif RunService:IsStudio() then
		-- Play solo dans Studio : personne d'autre ne viendra, on saute la cinématique
		task.delay(STUDIO_SOLO_DELAY, function()
			if cinematicStarted or #readyPlayers ~= 1 or readyPlayers[1] ~= player then return end
			print("[Cinematic] Studio solo : cinématique sautée pour", player.Name)
			awaitingUnlock[player] = true
			unlockPlayer(player)
		end)
	end
end

-- Le client confirme la fin de sa cinématique ; accepté seulement pendant une cinématique
unlockRemote.OnServerEvent:Connect(unlockPlayer)

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)

	-- Le personnage peut déjà exister si MatchReciever l'a créé avant ce script
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	awaitingUnlock[player] = nil
	local index = table.find(readyPlayers, player)
	if index and not cinematicStarted then
		table.remove(readyPlayers, index)
	end
end)
