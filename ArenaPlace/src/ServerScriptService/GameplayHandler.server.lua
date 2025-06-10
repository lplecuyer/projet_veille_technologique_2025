local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UpdateHearts = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateHearts")
local PlayerLives = {} -- [player] = number

function UpdateHeartsUI(targetPlayer, lives)
	for _, plr in ipairs(Players:GetPlayers()) do
		UpdateHearts:FireClient(plr, targetPlayer, lives)
	end
end

Players.PlayerAdded:Connect(function(player)
	PlayerLives[player] = 3

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			PlayerLives[player] -= 1
			UpdateHeartsUI(player, PlayerLives[player])

			if PlayerLives[player] <= 0 then
				-- Gère élimination ici
				print(player.Name .. " a été éliminé.")
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerLives[player] = nil
end)

-- Initialisation au début du match
game.Players.PlayerAdded:Connect(function(player)
	task.delay(1, function()
		UpdateHeartsUI(player, 3)
	end)
end)
