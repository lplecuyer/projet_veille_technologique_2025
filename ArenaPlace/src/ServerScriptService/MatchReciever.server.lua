local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassModels = ReplicatedStorage:WaitForChild("ClassModels")

-- Fonction pour souder les morceaux d’un Model (comme le Shield)
local function weldModel(model)
	if not model.PrimaryPart then
		local fallback = model:FindFirstChildWhichIsA("BasePart")
		if fallback then
			model.PrimaryPart = fallback
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
end

-- Fonction principale : remplacer le personnage du joueur par son modèle de classe
local function setupPlayerClass(player, className)
	player:SetAttribute("Class", className)
	print("[Arena] Classe assignée à", player.Name, ":", className)

	local model = ClassModels:FindFirstChild(className)
	if not model or not model:IsA("Model") then
		warn("[Arena] Aucun modèle 'Character' pour", className)
		return
	end

	local clone = model:Clone()
	clone.Name = player.Name

	-- Positionner à un spawn ou par défaut
	local spawnPart = workspace:FindFirstChild("ArenaSpawns") and workspace.ArenaSpawns:FindFirstChild("Spawn1")
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)
	clone:SetPrimaryPartCFrame(spawnCFrame + Vector3.new(0, 3, 0))

	-- 🔨 FIX pour Knight : souder le shield si présent
    if className == "Knight" then
        local leftArm = clone:FindFirstChild("Left Arm")
        if leftArm then
            local shield = leftArm:FindFirstChild("Shield")
            if shield and shield:IsA("Model") then
                weldModel(shield)

                if shield.PrimaryPart then
                    local motor = Instance.new("Motor6D")
                    motor.Name = "ShieldAttach"
                    motor.Part0 = leftArm
                    motor.Part1 = shield.PrimaryPart
                    motor.C0 = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), math.rad(90)) -- à ajuster selon visuel
                    motor.Parent = leftArm

                    shield.PrimaryPart.Anchored = false
                end
            end
        end
    end

	-- Associer le clone comme character
	clone.Parent = workspace
	player.Character = clone
end

-- Quand un joueur rejoint
Players.PlayerAdded:Connect(function(player)
	Players.CharacterAutoLoads = false
	local className

	if RunService:IsStudio() then
		-- Test local en studio
		className = "Knight"
	else
		local TeleportService = game:GetService("TeleportService")
		local data = TeleportService:GetLocalPlayerTeleportData()
		if data and data.ClassSelection then
			className = data.ClassSelection[player.UserId]
		end
	end

	if className then
		setupPlayerClass(player, className)
	else
		warn("[Arena] Classe introuvable pour", player.Name)
	end
end)
