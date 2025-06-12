local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local showWinnerEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShowWinnerLabel")

showWinnerEvent.OnClientEvent:Connect(function(winningText)
	local playerGui = player:WaitForChild("PlayerGui")
	local winnerGui = playerGui:WaitForChild("WinnerLabelUI")
	local label = winnerGui:WaitForChild("WinnerLabel")

	label.Text = winningText
	label.Visible = true
end)
