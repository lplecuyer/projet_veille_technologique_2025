local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cameraRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StartCinematic")
local unlockRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UnlockMovement")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Tween util
local function cinematicTween(startPos, endPos, lookAt)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new(startPos, lookAt.Position)

	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local goal = { CFrame = CFrame.new(endPos, lookAt.Position) }

	local tween = TweenService:Create(cam, tweenInfo, goal)
	tween:Play()
	tween.Completed:Wait()
end

cameraRemote.OnClientEvent:Connect(function(opponentName)
	local myChar = player.Character or player.CharacterAdded:Wait()
	local myHRP = myChar:WaitForChild("HumanoidRootPart")

	local isPlayer1 = player.Name < opponentName
	local xOffset = isPlayer1 and 5 or -5

	-- Caméra vers mon perso
	cinematicTween(
		myHRP.Position + Vector3.new(-xOffset, 0, -2),
		myHRP.Position + Vector3.new(-xOffset, 0, 2),
		myHRP
	)

	task.wait(0.5)

	-- Caméra vers l’adversaire
	local opponent = Players:FindFirstChild(opponentName)
	if opponent and opponent.Character then
		local oppHRP = opponent.Character:FindFirstChild("HumanoidRootPart")
		if oppHRP then
			cinematicTween(
				oppHRP.Position + Vector3.new(xOffset, 0, -2),
				oppHRP.Position + Vector3.new(xOffset, 0, 2),
				oppHRP
			)
			task.wait(0.5)
		end
	end

	task.wait(0.5)

	cam.CameraType = Enum.CameraType.Custom
	unlockRemote:FireServer()
end)

