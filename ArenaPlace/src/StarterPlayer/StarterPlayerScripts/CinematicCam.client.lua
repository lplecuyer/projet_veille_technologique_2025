local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local cameraRemote = RemoteEvents:WaitForChild("StartCinematic")
local unlockRemote = RemoteEvents:WaitForChild("UnlockMovement")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Tween util
local function cinematicTween(startPos, endPos, lookAt)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(startPos, lookAt.Position)

	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local goal = { CFrame = CFrame.lookAt(endPos, lookAt.Position) }

	local tween = TweenService:Create(cam, tweenInfo, goal)
	tween:Play()
	tween.Completed:Wait()
end

cameraRemote.OnClientEvent:Connect(function(opponentName)
	-- pcall : la caméra doit revenir et le mouvement se débloquer même si la cinématique plante
	local ok, err = pcall(function()
		local myChar = player.Character or player.CharacterAdded:Wait()
		local myHRP = myChar:WaitForChild("HumanoidRootPart")

		-- Même ordre que les spawns côté serveur (attribut Slot)
		local isPlayer1 = player:GetAttribute("Slot") == 1
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
		local oppHRP = opponent and opponent.Character and opponent.Character:FindFirstChild("HumanoidRootPart")
		if oppHRP then
			cinematicTween(
				oppHRP.Position + Vector3.new(xOffset, 0, -2),
				oppHRP.Position + Vector3.new(xOffset, 0, 2),
				oppHRP
			)
			task.wait(0.5)
		end

		task.wait(0.5)
	end)

	if not ok then
		warn("[Cinematic] Erreur :", err)
	end

	cam.CameraType = Enum.CameraType.Custom
	unlockRemote:FireServer()
end)
