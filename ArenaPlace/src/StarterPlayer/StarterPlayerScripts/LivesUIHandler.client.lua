local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local UpdateHearts = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateHearts")

local HEART_FULL = "rbxassetid://130588334075879"
local HEART_EMPTY = "rbxassetid://73063948247561"

local player1Frame, player2Frame

local function waitForUI()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	-- Attendre que LivesUI existe
	local livesUI = playerGui:FindFirstChild("LivesUI")
	local timeout = 5
	local t = 0

	while not livesUI and t < timeout do
		task.wait(0.1)
		t += 0.1
		livesUI = playerGui:FindFirstChild("LivesUI")
	end

	if not livesUI then
		warn("LivesUI introuvable dans PlayerGui après attente.")
		return
	end

	-- Maintenant, attendre les frames
	player1Frame = livesUI:FindFirstChild("Player1Lives")
	player2Frame = livesUI:FindFirstChild("Player2Lives")

	t = 0
	while (not player1Frame or not player2Frame) and t < timeout do
		task.wait(0.1)
		t += 0.1
		player1Frame = livesUI:FindFirstChild("Player1Lives")
		player2Frame = livesUI:FindFirstChild("Player2Lives")
	end

	if not player1Frame or not player2Frame then
		warn("Player1Lives ou Player2Lives introuvables dans LivesUI.")
	end
end

UpdateHearts.OnClientEvent:Connect(function(targetPlayer, lives)
	if not player1Frame or not player2Frame then
		waitForUI()
	end

	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)
	local targetFrame = (targetPlayer == players[1]) and player1Frame or player2Frame

	if not targetFrame then return end

	for i = 1, 3 do
		local heart = targetFrame:FindFirstChild("Heart" .. i)
		if heart then
			heart.Image = (i <= lives) and HEART_FULL or HEART_EMPTY
		end
	end
end)

waitForUI()
