local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local showWinnerEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShowWinnerLabel")

local UI_TIMEOUT = 10

showWinnerEvent.OnClientEvent:Connect(function(winningText)
	local playerGui = player:WaitForChild("PlayerGui")
	local winnerGui = playerGui:WaitForChild("WinnerLabelUI", UI_TIMEOUT)
	local label = winnerGui and winnerGui:WaitForChild("WinnerLabel", UI_TIMEOUT)
	if not label then
		warn("[Client] WinnerLabelUI/WinnerLabel introuvable, gagnant :", winningText)
		return
	end

	label.Text = winningText
	label.Visible = true
end)
