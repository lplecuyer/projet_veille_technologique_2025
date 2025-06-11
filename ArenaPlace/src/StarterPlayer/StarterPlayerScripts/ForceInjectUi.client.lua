local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- UIs qu’on veut injecter
local UINames = { "LivesUI", "WinnerLabelUI" }

local function injectUI()
	local playerGui = player:WaitForChild("PlayerGui")

	for _, uiName in ipairs(UINames) do
		if not playerGui:FindFirstChild(uiName) then
			local template = StarterGui:FindFirstChild(uiName)
			if template then
				local clone = template:Clone()
				clone.Parent = playerGui
				print("[Client] " .. uiName .. " injecté.")
			else
				warn("[Client] " .. uiName .. " manquant dans StarterGui!")
			end
		end
	end
end

-- Exécuter à l’arrivée du joueur
task.defer(function()
	task.wait(1)
	injectUI()

	-- Réinjecter à chaque respawn
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		injectUI()
	end)
end)
