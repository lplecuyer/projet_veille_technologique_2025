local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MovementRequest")
local dashRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DashRequest")
local attackRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AttackRequest")

local currentState = "Idle"

local UserInputService = game:GetService("UserInputService")


UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackRemote:FireServer(player)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.Q then return end
	if not hrp then return end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude == 0 then return end

	-- Convertir en repère local du joueur
	local localMoveDir = hrp.CFrame:VectorToObjectSpace(moveDir)

	local direction
	if math.abs(localMoveDir.X) > math.abs(localMoveDir.Z) then
		if localMoveDir.X > 0 then
			direction = "Right"
		else
			direction = "Left"
		end
	else
		if localMoveDir.Z > 0 then
			direction = "Back"
		else
			direction = "Front"
		end
	end

	dashRemote:FireServer(direction)
end)


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




-- Footsteps & jump

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