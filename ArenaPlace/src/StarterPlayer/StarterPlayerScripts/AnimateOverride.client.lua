local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animations = ReplicatedStorage:WaitForChild("Animations")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local idleAnim = humanoid:LoadAnimation(Animations:WaitForChild("Idle"))
local walkAnim = humanoid:LoadAnimation(Animations:WaitForChild("Walk"))

local currentState = "Idle"

-- Démarre l'idle par défaut
idleAnim:Play()
idleAnim.Looped = true
walkAnim.Looped = true

RunService.RenderStepped:Connect(function()
	local velocity = character:FindFirstChild("HumanoidRootPart").Velocity
	local isMoving = velocity.Magnitude > 1

	if isMoving and currentState ~= "Walk" then
		idleAnim:Stop()
		walkAnim:Play()
		currentState = "Walk"
	elseif not isMoving and currentState ~= "Idle" then
		walkAnim:Stop()
		idleAnim:Play()
		currentState = "Idle"
	end
end)
