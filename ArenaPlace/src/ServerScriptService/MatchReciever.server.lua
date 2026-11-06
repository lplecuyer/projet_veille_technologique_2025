-- Reçoit les joueurs téléportés depuis le lobby et crée leur personnage selon leur classe
local Players = game:GetService("Players")
-- Avant tout yield : sinon un joueur arrivé tôt reçoit un perso par défaut
Players.CharacterAutoLoads = false

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterSpawner = require(ServerScriptService:WaitForChild("CharacterRespawn"))

local VALID_CLASSES = { Knight = true, Rogue = true }
-- En Studio, pas de TeleportData : tous les joueurs de test sont Knight (Rogue pas encore fonctionnel)
local STUDIO_CLASS = "Knight"

-- Lit la classe envoyée par le lobby (TeleportOptions:SetTeleportData)
local function getClassForPlayer(player)
	if RunService:IsStudio() then
		return STUDIO_CLASS
	end

	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	local className = type(teleportData) == "table"
		and type(teleportData.Players) == "table"
		and teleportData.Players[tostring(player.UserId)]

	if type(className) == "string" and VALID_CLASSES[className] then
		return className
	end

	warn("[Arena] Classe invalide ou manquante pour", player.Name, "- Knight par défaut")
	return "Knight"
end

local function onPlayerAdded(player)
	local slot = CharacterSpawner.assignSlot(player)
	if not slot then
		player:Kick("Cette arène est pleine.")
		return
	end

	local className = getClassForPlayer(player)
	print("[Arena]", player.Name, "a rejoint avec la classe", className)
	CharacterSpawner.setupPlayerClass(player, className)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
