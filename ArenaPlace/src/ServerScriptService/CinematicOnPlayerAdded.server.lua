local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cameraRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StartCinematic")
local unlockRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UnlockMovement")

local joinedPlayers = {}

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 0

	-- Force idle anim
	local Animations = ReplicatedStorage:WaitForChild("Animations")
	local idleAnim = Animations:WaitForChild("Idle")
	local animTrack = humanoid:LoadAnimation(idleAnim)
	animTrack:Play()

	-- Ajoute le joueur à la file d'attente pour cinématique
	table.insert(joinedPlayers, player)

	-- Quand 2 joueurs sont prêts, on déclenche
	if #joinedPlayers == 2 then
		local player1 = joinedPlayers[1]
		local player2 = joinedPlayers[2]

		-- Déclenche cinématique chez les deux joueurs
		cameraRemote:FireClient(player1, player2.Name)
		cameraRemote:FireClient(player2, player1.Name)

		-- Vide la liste si tu veux réutiliser plus tard
		joinedPlayers = {}
	end
end

unlockRemote.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid.WalkSpeed = 16
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end)
