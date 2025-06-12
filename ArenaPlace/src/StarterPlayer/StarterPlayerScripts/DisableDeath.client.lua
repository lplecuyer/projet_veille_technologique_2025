local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Fonction pour désactiver l'état "Dead" à chaque respawn
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	print("[Client] État Dead désactivé pour", player.Name)
end

-- Déjà un character ?
if player.Character and player.Character.Parent then
	onCharacterAdded(player.Character)
end

-- Sinon, écoute chaque respawn
player.CharacterAdded:Connect(onCharacterAdded)
