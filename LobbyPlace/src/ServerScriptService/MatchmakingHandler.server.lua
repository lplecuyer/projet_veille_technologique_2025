local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StartMatch = ReplicatedStorage:WaitForChild("StartMatch")

local ARENA_PLACE_ID = 76665182259647
local waitingPlayers = {} -- [player] = class

StartMatch.OnServerEvent:Connect(function(player, selectedClass)
	print("[Matchmaking] Reçu Start de", player.Name, "avec classe:", selectedClass)

	if not selectedClass then
		warn("[Matchmaking] Classe invalide pour", player.Name)
		return
	end

	if waitingPlayers[player] then
		warn("[Matchmaking] Le joueur est déjà en attente :", player.Name)
		return
	end

	waitingPlayers[player] = selectedClass
	print("[Matchmaking] Ajouté", player.Name, "à la file d’attente")

	print("Type de player:", typeof(player))
	print("player.Name:", player.Name)

	-- Afficher l’état de la file d’attente
	for p, c in pairs(waitingPlayers) do
		print(" - En attente :", p.Name, "(", c, ")")
	end

	-- Matchmaking
	local otherPlayer, otherClass = nil, nil
	for p, c in pairs(waitingPlayers) do
		if p ~= player then
			otherPlayer, otherClass = p, c
			break
		end
	end

	if otherPlayer then
		print("[Matchmaking] Paire trouvée :", player.Name, "et", otherPlayer.Name)

		local class1 = waitingPlayers[player]
		local class2 = waitingPlayers[otherPlayer]

		waitingPlayers[player] = nil
		waitingPlayers[otherPlayer] = nil

		local teleportData = {
			Players = {
				[player.UserId] = class1,
				[otherPlayer.UserId] = class2
			}
		}

		local success, err = pcall(function()
			TeleportService:TeleportPartyAsync(
				ARENA_PLACE_ID,
				{player, otherPlayer},
				teleportData
			)
		end)


		if success then
			print("[Matchmaking] Téléportation lancée !")
		else
			warn("[Matchmaking] Erreur de téléportation :", err)
		end
	end
end)
