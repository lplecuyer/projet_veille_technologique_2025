local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StartMatch = ReplicatedStorage:WaitForChild("StartMatch")

local ARENA_PLACE_ID = 76665182259647
local VALID_CLASSES = { Knight = true, Rogue = true }
local MAX_TELEPORT_ATTEMPTS = 3

local waitingPlayers = {} -- [player] = class
local teleportingPlayers = {} -- [player] = class pendant une téléportation

local tryMatch -- défini plus bas

-- Remet un joueur dans la file si sa téléportation échoue
local function requeue(player, className)
	if player.Parent == Players and not waitingPlayers[player] then
		waitingPlayers[player] = className
		print("[Matchmaking] Remis en file d’attente :", player.Name)
		task.spawn(tryMatch)
	end
end

local function teleportMatch(matchPlayers, teleportData)
	for _, p in ipairs(matchPlayers) do
		teleportingPlayers[p] = teleportData.Players[tostring(p.UserId)]
	end

	-- Les téléportations ne fonctionnent pas dans Studio : on affiche seulement ce qui serait envoyé
	if RunService:IsStudio() then
		print("[Matchmaking] Mode Studio : téléportation simulée vers l’arène avec :", teleportData)
		for _, p in ipairs(matchPlayers) do
			teleportingPlayers[p] = nil
		end
		return
	end

	-- Serveur réservé : chaque match a sa propre arène
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	options:SetTeleportData(teleportData)

	for attempt = 1, MAX_TELEPORT_ATTEMPTS do
		-- Si un joueur a quitté pendant les essais, on annule le match
		for _, p in ipairs(matchPlayers) do
			if p.Parent ~= Players then
				warn("[Matchmaking] Un joueur a quitté, match annulé")
				for _, other in ipairs(matchPlayers) do
					teleportingPlayers[other] = nil
					requeue(other, teleportData.Players[tostring(other.UserId)])
				end
				return
			end
		end

		local success, err = pcall(function()
			return TeleportService:TeleportAsync(ARENA_PLACE_ID, matchPlayers, options)
		end)

		if success then
			print("[Matchmaking] Téléportation lancée !")
			return
		end

		warn(("[Matchmaking] Erreur de téléportation (essai %d/%d) : %s"):format(attempt, MAX_TELEPORT_ATTEMPTS, tostring(err)))
		task.wait(2)
	end

	-- Échec définitif : on remet les joueurs encore présents dans la file
	for _, p in ipairs(matchPlayers) do
		teleportingPlayers[p] = nil
		requeue(p, teleportData.Players[tostring(p.UserId)])
	end
end

-- Jumelle les deux premiers joueurs en attente, s'il y en a deux
function tryMatch()
	local matchPlayers = {}
	for p in pairs(waitingPlayers) do
		table.insert(matchPlayers, p)
		if #matchPlayers == 2 then
			break
		end
	end

	if #matchPlayers < 2 then
		return
	end

	local player1, player2 = matchPlayers[1], matchPlayers[2]
	print("[Matchmaking] Paire trouvée :", player1.Name, "et", player2.Name)

	local teleportData = {
		Players = {
			[tostring(player1.UserId)] = waitingPlayers[player1],
			[tostring(player2.UserId)] = waitingPlayers[player2],
		},
	}

	waitingPlayers[player1] = nil
	waitingPlayers[player2] = nil

	teleportMatch(matchPlayers, teleportData)
end

-- Échec après le lancement de la téléportation (ex. serveur plein, réseau)
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	warn("[Matchmaking] Téléportation échouée pour", player.Name, teleportResult, errorMessage)
	local className = teleportingPlayers[player]
	teleportingPlayers[player] = nil
	if className then
		requeue(player, className)
	end
end)

StartMatch.OnServerEvent:Connect(function(player, selectedClass)
	print("[Matchmaking] Reçu Start de", player.Name, "avec classe:", selectedClass)

	-- Ne jamais faire confiance au client : on valide la classe
	if type(selectedClass) ~= "string" or not VALID_CLASSES[selectedClass] then
		warn("[Matchmaking] Classe invalide pour", player.Name)
		return
	end

	if waitingPlayers[player] or teleportingPlayers[player] then
		warn("[Matchmaking] Le joueur est déjà en attente :", player.Name)
		return
	end

	waitingPlayers[player] = selectedClass
	print("[Matchmaking] Ajouté", player.Name, "à la file d’attente")

	tryMatch()
end)

-- Nettoyage : un joueur parti ne doit pas rester dans la file
Players.PlayerRemoving:Connect(function(player)
	waitingPlayers[player] = nil
	teleportingPlayers[player] = nil
end)
