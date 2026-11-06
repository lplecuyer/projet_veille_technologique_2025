-- Arbitre du combat : le client joue ses animations et son dash lui-même (AnimateOverride),
-- le serveur valide les requêtes et gère cooldowns, invincibilité, hitboxes, dégâts, parry et stun
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local dashRemote = RemoteEvents:WaitForChild("DashRequest")
local attackRemote = RemoteEvents:WaitForChild("AttackRequest")
local parryRemote = RemoteEvents:WaitForChild("ParryRequest")

-- Créés ici pour ne pas dépendre de Studio
local function getOrCreateRemote(name)
	local existing = RemoteEvents:FindFirstChild(name)
	if existing then
		return existing
	end
	local created = Instance.new("RemoteEvent")
	created.Name = name
	created.Parent = RemoteEvents
	return created
end
-- Serveur → clients : un parry a réussi, on affiche les étincelles
local parryEffectRemote = getOrCreateRemote("ParryEffect")
-- Client → serveur : l'attaquant a vu son coup frapper un parry de son côté
local parryHitRemote = getOrCreateRemote("ParryHit")

local COMBO_DAMAGE = { 5, 10, 15 }
-- Délai max entre deux coups d'un même combo (durée de l'anim + fenêtre de buffer, avec marge)
local COMBO_MAX_GAP = 2.5
-- Délai min entre deux coups, contre le spam de requêtes
local MIN_ATTACK_INTERVAL = 0.2
-- Marge pour la gigue réseau : deux requêtes peuvent arriver plus rapprochées qu'envoyées
local LATENCY_TOLERANCE = 0.2
-- Distance max entre attaquant et cible pour accepter un parry signalé par le client
local MAX_PARRY_HIT_DISTANCE = 12

local lastDashTimes = {}
local lastParryTimes = {}
local lastAttacks = {} -- [player] = { step, time, parried } du dernier coup accepté

local isLocked = {} -- pour lock temporairement un joueur durant un parry ou etre parried
local isParrying = {}
local isInvincible = {}

-- Vrai si le joueur ne peut pas agir (cinématique, fin de match, mort simulée)
local function isActionBlocked(player)
	return workspace:GetAttribute("MatchOver")
		or player:GetAttribute("MovementLocked")
		or player:GetAttribute("SimulatedDead")
end

local function getHumanoid(player)
	local char = player.Character
	return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- Bloque le joueur pendant `duration`, puis le libère
local function lockPlayer(player, humanoid, duration, onUnlock)
	isLocked[player] = true
	lastAttacks[player] = nil

	local oldWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0

	task.delay(duration, function()
		isLocked[player] = false
		if onUnlock then
			onUnlock()
		end

		-- La fin du match a pu bloquer le joueur entre-temps
		if humanoid.Parent and not workspace:GetAttribute("MatchOver") then
			humanoid.WalkSpeed = oldWalkSpeed
		end
	end)
end

-- L'attribut "Stunned" se réplique : le client joue l'anim de stun de son côté
-- (l'attaquant l'a souvent déjà prédit en voyant l'attribut "Parrying" de sa cible)
local function stunPlayer(player, humanoid)
	if isLocked[player] then return end

	player:SetAttribute("Stunned", true)
	lockPlayer(player, humanoid, CombatConfig.STUN_DURATION, function()
		player:SetAttribute("Stunned", false)
	end)
end

-- Parry réussi : stun de l'attaquant et étincelles chez tout le monde, une seule fois par coup
local function resolveParry(attacker, attack, position)
	if attack.parried then return end
	attack.parried = true

	local attackerHumanoid = getHumanoid(attacker)
	if attackerHumanoid then
		stunPlayer(attacker, attackerHumanoid)
	end
	parryEffectRemote:FireAllClients(attacker, position)
end

local function connectHitboxes(player, step, attack)
	local char = player.Character
	local weaponNames = CombatConfig.ATTACK_WEAPONS[player:GetAttribute("Class")]
	if not char or not weaponNames then return end

	local damage = COMBO_DAMAGE[step] or COMBO_DAMAGE[1]
	local alreadyHit = {} -- partagé entre les armes : un seul coup par cible
	local connections = {}

	local function onTouched(hitbox, part)
		local targetChar = part:FindFirstAncestorOfClass("Model")
		if not targetChar or targetChar == player.Character then return end

		local humanoid = targetChar:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		if not targetPlayer then return end

		if isInvincible[targetPlayer] or targetPlayer:GetAttribute("IsInvincible") then
			return
		end

		if alreadyHit[humanoid] then return end
		alreadyHit[humanoid] = true

		if isParrying[targetPlayer] then
			-- STUN de l'attaquant (player) ; pas de dégâts
			resolveParry(player, attack, hitbox.Position)
			return
		end
		if attack.parried then return end

		humanoid:TakeDamage(damage)
	end

	for _, weaponName in ipairs(weaponNames) do
		local weapon = char:FindFirstChild(weaponName, true)
		local hitbox = weapon and weapon:FindFirstChild("Hitbox", true)
		if hitbox and hitbox:IsA("BasePart") then
			table.insert(connections, hitbox.Touched:Connect(function(part)
				onTouched(hitbox, part)
			end))
		end
	end

	-- Arrêter la détection après HITBOX_DURATION
	task.delay(CombatConfig.HITBOX_DURATION, function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end)
end

-- Attack : le client envoie le step du combo qu'il vient de jouer
attackRemote.OnServerEvent:Connect(function(player, step)
	if type(step) ~= "number" or step % 1 ~= 0 or step < 1 or step > CombatConfig.MAX_COMBO_STEP then
		return
	end
	if isLocked[player] or isActionBlocked(player) then return end

	local now = os.clock()
	local last = lastAttacks[player]
	if last and now - last.time < MIN_ATTACK_INTERVAL then return end

	-- Un step > 1 doit suivre le step précédent du même combo
	if step > 1 and not (last and last.step == step - 1 and now - last.time <= COMBO_MAX_GAP) then
		return
	end

	local attack = { step = step, time = now, parried = false }
	lastAttacks[player] = attack
	connectHitboxes(player, step, attack)
end)

-- L'attaquant a prédit un parry : son anim est coupée chez lui, donc le serveur ne verra
-- peut-être jamais le contact. On valide ce qu'on peut et on confirme pour tout le monde.
parryHitRemote.OnServerEvent:Connect(function(player, target, position)
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == player then return end
	if typeof(position) ~= "Vector3" then return end
	if not isParrying[target] then return end

	local attack = lastAttacks[player]
	if not attack or os.clock() - attack.time > CombatConfig.HITBOX_DURATION + LATENCY_TOLERANCE then return end

	local attackerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not (attackerRoot and targetRoot) then return end
	if (attackerRoot.Position - targetRoot.Position).Magnitude > MAX_PARRY_HIT_DISTANCE then return end

	-- Position venant du client : on la garde seulement si elle est proche des deux joueurs
	if (position - targetRoot.Position).Magnitude > MAX_PARRY_HIT_DISTANCE then
		position = (attackerRoot.Position + targetRoot.Position) / 2
	end

	resolveParry(player, attack, position)
end)

-- Parry
parryRemote.OnServerEvent:Connect(function(player)
	if isLocked[player] or isActionBlocked(player) then return end

	local now = os.clock()
	local lastParry = lastParryTimes[player]
	if lastParry and now - lastParry < CombatConfig.PARRY_COOLDOWN - LATENCY_TOLERANCE then
		return
	end

	local humanoid = getHumanoid(player)
	if not humanoid then return end

	lastParryTimes[player] = now
	isParrying[player] = true
	-- Attribut répliqué : le client de l'attaquant s'en sert pour prédire le stun
	player:SetAttribute("Parrying", true)
	lockPlayer(player, humanoid, CombatConfig.PARRY_DURATION, function()
		isParrying[player] = false
		player:SetAttribute("Parrying", false)
	end)
end)

-- Dash : le mouvement est appliqué par le client, le serveur gère cooldown et invincibilité
dashRemote.OnServerEvent:Connect(function(player, direction)
	if type(direction) ~= "string" or not CombatConfig.DASH_DIRECTIONS[direction] then return end
	if isLocked[player] or isActionBlocked(player) then return end

	local now = os.clock()
	local lastDash = lastDashTimes[player]
	if lastDash and now - lastDash < CombatConfig.DASH_COOLDOWN - LATENCY_TOLERANCE then
		return
	end
	lastDashTimes[player] = now

	isInvincible[player] = true
	task.delay(CombatConfig.DASH_DURATION, function()
		isInvincible[player] = false
	end)
end)

-- Nettoyage
Players.PlayerRemoving:Connect(function(player)
	lastDashTimes[player] = nil
	lastParryTimes[player] = nil
	lastAttacks[player] = nil
	isLocked[player] = nil
	isParrying[player] = nil
	isInvincible[player] = nil
end)
