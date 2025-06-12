local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
player.CharacterAdded:Wait()
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MovementRequest")
local dashRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DashRequest")
local attackRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AttackRequest")
local parryRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ParryRequest")
local charLoadedRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CharacterLoaded")

local currentState = "Idle"

charLoadedRemote.OnClientEvent:Connect(function(character)
	local player = Players.LocalPlayer
	if player then
		player.Character = character
		workspace.CurrentCamera.CameraSubject = character:FindFirstChild("Humanoid") or character:FindFirstChildWhichIsA("Humanoid")
	end
end)

player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	Workspace.CurrentCamera.CameraSubject = humanoid
end)

-- 🔁 ATTAQUE (Clic gauche)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackRemote:FireServer(player)
	end
end)

-- 🛡️ PARRY (Clic droit)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		parryRemote:FireServer() -- pas besoin d'envoyer `player`, le serveur le reçoit automatiquement
	end
end)

-- 💨 DASH (Touche Q)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.Q then return end
	if not hrp then return end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude == 0 then return end

	local localMoveDir = hrp.CFrame:VectorToObjectSpace(moveDir)
	local direction

	if math.abs(localMoveDir.X) > math.abs(localMoveDir.Z) then
		direction = localMoveDir.X > 0 and "Right" or "Left"
	else
		direction = localMoveDir.Z > 0 and "Back" or "Front"
	end

	dashRemote:FireServer(direction)
end)

-- 🚶‍♂️ IDLE / WALK Animation Sync
RunService.RenderStepped:Connect(function()
	if not hrp then return end

	local velocity = hrp.Velocity * Vector3.new(1, 0, 1)
	local isMoving = velocity.Magnitude > 1

	if isMoving and currentState ~= "Walk" then
		currentState = "Walk"
		remote:FireServer("Walk")
	elseif not isMoving and currentState ~= "Idle" then
		currentState = "Idle"
		remote:FireServer("Idle")
	end
end)

-- 🚫 DÉSACTIVATION DU JUMP
local function disableJump()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
end

player.CharacterAdded:Connect(function()
	disableJump()
end)

if player.Character then
	disableJump()
end
