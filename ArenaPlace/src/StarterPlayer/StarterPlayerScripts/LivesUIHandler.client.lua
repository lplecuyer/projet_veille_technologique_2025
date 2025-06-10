local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local UpdateHearts = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateHearts")

local HEART_FULL = "rbxassetid://130588334075879" -- remplace par ton ID cœur plein
local HEART_EMPTY = "rbxassetid://73063948247561" -- remplace par ton ID cœur vide

local livesUI = localPlayer:WaitForChild("PlayerGui"):WaitForChild("LivesUI")
local player1Frame = livesUI:WaitForChild("Player1Lives")
local player2Frame = livesUI:WaitForChild("Player2Lives")

local function getFrameForPlayer(targetPlayer)
	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)
	
	if targetPlayer == players[1] then
		return player1Frame
	else
		return player2Frame
	end
end

UpdateHearts.OnClientEvent:Connect(function(targetPlayer, lives)
	local targetFrame = getFrameForPlayer(targetPlayer)
	if not targetFrame then return end

	for i = 1, 3 do
		local heart = targetFrame:FindFirstChild("Heart" .. i)
		if heart then
			heart.Image = (i <= lives) and HEART_FULL or HEART_EMPTY
		end
	end
end)
