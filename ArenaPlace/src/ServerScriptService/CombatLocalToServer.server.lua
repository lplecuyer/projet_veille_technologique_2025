local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MovementRequest")
local dashRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DashRequest")
local attackRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AttackRequest")
local parryRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ParryRequest")
local Animations = ReplicatedStorage:WaitForChild("Animations")

local DASH_SPEED = 100
local DASH_DURATION = 0.2
local DASH_COOLDOWN = 2

local lastDashTimes = {}
local comboState = {}

local isAttacking = {} -- état d'attaque actif par joueur
local isLocked = {} -- pour lock temporairement un joueur durant un parry ou etre parried
local isParrying = {}
local isInvincible = {}


local function stopAllAnimations(humanoid)
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop(0.1)
	end
end

local function resetCombo(player, humanoid)
	comboState[player] = nil
	isAttacking[player] = false

	local idle = Animations:FindFirstChild("Idle")
	local walk = Animations:FindFirstChild("Walk")

	if humanoid.MoveDirection.Magnitude > 0.1 and walk then
		local walkTrack = humanoid:LoadAnimation(walk)
		walkTrack.Looped = true
		walkTrack:Play()
	elseif idle then
		local idleTrack = humanoid:LoadAnimation(idle)
		idleTrack.Looped = true
		idleTrack:Play()
	end
end

local function stunPlayer(player, humanoid)
	if isLocked[player] then return end

	isLocked[player] = true
	isAttacking[player] = true
	comboState[player] = nil

	stopAllAnimations(humanoid)

	local stunAnim = Animations:FindFirstChild("Stun")
	if stunAnim then
		local track = humanoid:LoadAnimation(stunAnim)
		track:Play()
	end

	-- Désactive le mouvement
	local oldWalkSpeed = humanoid.WalkSpeed

	humanoid.WalkSpeed = 0

	task.delay(2.25, function()
		isLocked[player] = false
		isAttacking[player] = false

		humanoid.WalkSpeed = oldWalkSpeed

		-- Rejoue anim selon s'il bouge
		if humanoid.MoveDirection.Magnitude > 0.1 then
			local walk = Animations:FindFirstChild("Walk")
			if walk then
				local track = humanoid:LoadAnimation(walk)
				track.Looped = true
				track:Play()
			end
		else
			local idle = Animations:FindFirstChild("Idle")
			if idle then
				local track = humanoid:LoadAnimation(idle)
				track.Looped = true
				track:Play()
			end
		end
	end)
end

local function connectHitbox(player, weaponModel, duration, step)
	local hitbox = weaponModel:FindFirstChild("Hitbox")
	if not hitbox then return end

	local alreadyHit = {}
	local connection

	local damage = 5
	if step == 2 then
		damage = 10
	elseif step == 3 then
		damage = 15
	end

	connection = hitbox.Touched:Connect(function(part)
		local targetChar = part:FindFirstAncestorOfClass("Model")
		if not targetChar or targetChar == player.Character then return end

		local humanoid = targetChar:FindFirstChildWhichIsA("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		if not targetPlayer then return end

		if isInvincible[targetPlayer] then
			print(targetPlayer.Name .. " a esquivé grâce à i-frames")
			return
		end


		if alreadyHit[humanoid] then return end
		alreadyHit[humanoid] = true

		if isParrying[targetPlayer] then
			-- STUN de l'attaquant (player)
			local attackerChar = player.Character
			if attackerChar then
				local attackerHumanoid = attackerChar:FindFirstChildWhichIsA("Humanoid")
				if attackerHumanoid then
					stunPlayer(player, attackerHumanoid)
				end
			end

			return -- ne pas infliger de dégâts
		end

		humanoid:TakeDamage(damage)

		-- (optionnel) ajouter un son, effet, etc. ici
	end)

	-- Arrêter la détection après `duration`
	task.delay(duration, function()
		if connection then connection:Disconnect() end
	end)
end


local function playAttack(player, humanoid, step)
	local animName = "Hit" .. step
	local anim = Animations:FindFirstChild(animName)
	if not anim then return end

	stopAllAnimations(humanoid)
	local track = humanoid:LoadAnimation(anim)

	isAttacking[player] = true

	track:Play()

	local RightArm = player.Character and player.Character:FindFirstChild("Right Arm")
	local weapon = RightArm:FindFirstChild("Sword")
	if weapon then
		connectHitbox(player, weapon, 0.7, step)
	end

	comboState[player] = {
		step = step,
		buffer = false,
		canBuffer = false,
	}

	-- Détermine le bon keyframe selon le step
	local keyframeName = (step == 1) and "ComboWindow" or (step == 2 and "ComboWindow2") or nil
	if keyframeName then
		track:GetMarkerReachedSignal(keyframeName):Connect(function()
			local state = comboState[player]
			if not state or state.step ~= step then return end

			state.canBuffer = true
			task.delay(0.6, function()
				if comboState[player] == state then
					if state.buffer then
						attackRemote:FireServer(player) -- envoie le prochain combo
					else
						resetCombo(player, humanoid)
					end
				end
			end)
		end)
	end

	track.Stopped:Connect(function()
		local state = comboState[player]
		if state and state.step == step then
			resetCombo(player, humanoid)
		end
	end)
end

-- Attack
attackRemote.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	if isLocked[player] then return end

	local state = comboState[player]

	if not state then
		-- Premier coup
		playAttack(player, humanoid, 1)
	elseif state.canBuffer then
		-- Enchaînement combo
		playAttack(player, humanoid, state.step + 1)
	else
		-- Clique trop tôt
		state.buffer = true
	end
end)

-- Parry
parryRemote.OnServerEvent:Connect(function(player)
	if isLocked[player] then return end

	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	local parryAnim = Animations:FindFirstChild("Parry")
	if not parryAnim then return end

	isParrying[player] = true

	-- Lock les inputs
	isLocked[player] = true
	isAttacking[player] = true
	comboState[player] = nil

	stopAllAnimations(humanoid)

	-- Sauvegarde des valeurs originales
	local oldWalkSpeed = humanoid.WalkSpeed

	humanoid.WalkSpeed = 0

	local track = humanoid:LoadAnimation(parryAnim)
	track:Play()

	task.delay(1.5, function()
		isLocked[player] = false
		isAttacking[player] = false
		isParrying[player] = false

		-- Restaure les valeurs normales
		humanoid.WalkSpeed = oldWalkSpeed

		-- Rejoue l'anim selon le mouvement
		if humanoid.MoveDirection.Magnitude > 0.1 then
			local walk = Animations:FindFirstChild("Walk")
			if walk then
				local walkTrack = humanoid:LoadAnimation(walk)
				walkTrack.Looped = true
				walkTrack:Play()
			end
		else
			local idle = Animations:FindFirstChild("Idle")
			if idle then
				local idleTrack = humanoid:LoadAnimation(idle)
				idleTrack.Looped = true
				idleTrack:Play()
			end
		end
	end)
end)


-- Idle / Walk
remote.OnServerEvent:Connect(function(player, state)
	if isAttacking[player] then return end -- Ignore les requêtes de déplacement si en attaque
	if isLocked[player] then return end

	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	local animObj = Animations:FindFirstChild(state)
	if animObj then
		stopAllAnimations(hum)
		local track = hum:LoadAnimation(animObj)
		track.Looped = true
		track:Play()
	end
end)


-- Dash avec cooldown
dashRemote.OnServerEvent:Connect(function(player, direction)
	if isLocked[player] then return end

	local now = tick()
	if lastDashTimes[player] and now - lastDashTimes[player] < DASH_COOLDOWN then
		return
	end
	lastDashTimes[player] = now

	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	isInvincible[player] = true

	task.delay(DASH_DURATION, function()
		isInvincible[player] = false
	end)


	for _, track in pairs(hum:GetPlayingAnimationTracks()) do
		if track.Animation.Name:match("^Dash") then
			track:Stop(0.1)
		end
	end

	local dashAnim = Animations:FindFirstChild("Dash" .. direction)
	if dashAnim then
		local track = hum:LoadAnimation(dashAnim)
		track:Play()
	end

	local moveDir = Vector3.zero
	if direction == "Front" then
		moveDir = hum.MoveDirection
	elseif direction == "Back" then
		moveDir = hum.MoveDirection
	elseif direction == "Left" then
		moveDir = -hrp.CFrame.RightVector
	elseif direction == "Right" then
		moveDir = hrp.CFrame.RightVector
	end

	if moveDir.Magnitude > 0.1 then
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = moveDir.Unit * DASH_SPEED
		bv.MaxForce = Vector3.new(1, 0, 1) * 500000
		bv.P = 1250
		bv.Parent = hrp

		Debris:AddItem(bv, DASH_DURATION)
	end
end)

-- Nettoyage
Players.PlayerRemoving:Connect(function(player)
	lastDashTimes[player] = nil
	comboState[player] = nil
	isAttacking[player] = nil
end)
