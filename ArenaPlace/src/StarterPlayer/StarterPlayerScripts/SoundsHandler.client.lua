-- Sons de combat pour tous les personnages, déduits de ce que le client voit déjà :
-- les animations qui jouent (coups, parry, dash) et la vie qui baisse (coups reçus).
-- Nos propres anims démarrent sur ce client, donc nos sons sont instantanés.
-- Le son du parry réussi est joué avec les étincelles (ParryEffects).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatSounds = require(ReplicatedStorage:WaitForChild("CombatSounds"))
local Animations = ReplicatedStorage:WaitForChild("Animations")

-- Nom d'anim → son à jouer quand elle démarre
local ANIMATION_SOUNDS = {
	Hit1 = "Swing",
	Hit2 = "Swing",
	Hit3 = "Swing",
	Parry = "ParryWhiff",
	DashFront = "Dash",
	DashBack = "Dash",
	DashLeft = "Dash",
	DashRight = "Dash",
}

-- Les tracks répliquées n'ont pas toujours le bon nom d'Animation : on les reconnaît par leur ID
local function normalizeId(animationId)
	return animationId:match("(%d+)$")
end

local soundByAnimationId = {}
for _, anim in ipairs(Animations:GetDescendants()) do
	if anim:IsA("Animation") and ANIMATION_SOUNDS[anim.Name] then
		local id = normalizeId(anim.AnimationId)
		if id then
			soundByAnimationId[id] = ANIMATION_SOUNDS[anim.Name]
		end
	end
end

local function watchCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not (humanoid and root) then return end

	local animator = humanoid:WaitForChild("Animator", 10)
	if animator then
		animator.AnimationPlayed:Connect(function(track)
			local id = track.Animation and normalizeId(track.Animation.AnimationId)
			local soundName = id and soundByAnimationId[id]
			if soundName then
				CombatSounds.playOn(soundName, root)
			end
		end)
	end

	-- Seule une épée fait perdre de la vie : chaque baisse = un coup reçu
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			CombatSounds.playOn("Hit", root)
		end
		lastHealth = health
	end)
end

local function watchPlayer(player)
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

CombatSounds.startAmbience()
