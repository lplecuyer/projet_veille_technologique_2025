-- CharacterSpawner.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassModels = ReplicatedStorage:WaitForChild("ClassModels")

local module = {}

function module.weldModel(model)
    print("[weldModel] Welding model:", model.Name)
	if not model.PrimaryPart then
		local fallback = model:FindFirstChildWhichIsA("BasePart")
		if fallback then
			model.PrimaryPart = fallback
			print("[weldModel] Fallback PrimaryPart:", fallback.Name)
		else
			warn("[weldModel] Aucun BasePart trouvé pour", model.Name)
			return
		end
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = part
			weld.Parent = model.PrimaryPart
			part.Anchored = false
		end
	end

	model.PrimaryPart.Anchored = false
	print("[weldModel] Welding completed for", model.Name)
end

function module.setupPlayerClass(player, className)
	player:SetAttribute("Class", className)
	local model = ClassModels:FindFirstChild(className)
	if not model then return end

	local clone = model:Clone()
	clone.Name = player.Name

	local humanoid = clone:FindFirstChildWhichIsA("Humanoid")
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	local spawnsFolder = workspace:FindFirstChild("ArenaSpawns")
	local players = game:GetService("Players"):GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)
	local isPlayer1 = players[1] == player

	local spawnName = isPlayer1 and "Spawn1" or "Spawn2"
	local spawnPart = spawnsFolder and spawnsFolder:FindFirstChild(spawnName)
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)
	local rotatedCFrame = spawnCFrame + Vector3.new(0, 3, 0)
	rotatedCFrame = rotatedCFrame * CFrame.Angles(0, math.rad(isPlayer1 and 90 or -90), 0)
	clone:SetPrimaryPartCFrame(rotatedCFrame)

	if player:GetAttribute("Class") == "Knight" then
		-- (le code de welding de shield)
        print("[setupPlayerClass] Knight détecté, ajout du bouclier.")
		local leftArm = clone:FindFirstChild("Left Arm")
		if leftArm then
			local shield = leftArm:FindFirstChild("Shield")
			if shield and shield:IsA("Model") then
				print("[setupPlayerClass] Shield trouvé, welding en cours...")
				module.weldModel(shield)

				if shield.PrimaryPart then
					local motor = Instance.new("Motor6D")
					motor.Name = "ShieldAttach"
					motor.Part0 = leftArm
					motor.Part1 = shield.PrimaryPart
					motor.C0 = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), math.rad(90))
					motor.Parent = leftArm
					shield.PrimaryPart.Anchored = false
					print("[setupPlayerClass] Shield attaché avec Motor6D.")
				else
					warn("[setupPlayerClass] Shield sans PrimaryPart.")
				end
			else
				warn("[setupPlayerClass] Pas de shield sur le bras.")
			end
		else
			warn("[setupPlayerClass] Pas de bras gauche trouvé.")
		end
	end

	clone.Parent = workspace
	player.Character = clone

	local charLoadedRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CharacterLoaded")
	charLoadedRemote:FireClient(player, clone)
end

return module
