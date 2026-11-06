-- Le client joue les animations et le dash de son propre personnage dès l'input :
-- elles se répliquent toutes seules aux autres joueurs, sans attendre l'aller-retour serveur.
-- Le serveur (CombatLocalToServer) reste l'arbitre : cooldowns, hitboxes, dégâts, parry, stun.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local ParryEffects = require(ReplicatedStorage:WaitForChild("ParryEffects"))
local CombatState = require(script.Parent:WaitForChild("CombatState"))

local player = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local dashRemote = RemoteEvents:WaitForChild("DashRequest")
local attackRemote = RemoteEvents:WaitForChild("AttackRequest")
local parryRemote = RemoteEvents:WaitForChild("ParryRequest")
local parryEffectRemote = RemoteEvents:WaitForChild("ParryEffect")
local parryHitRemote = RemoteEvents:WaitForChild("ParryHit")
local Animations = ReplicatedStorage:WaitForChild("Animations")

-- Si on a prédit un parry il y a moins que ça, l'annonce du serveur est le même parry
local PARRY_PREDICTION_WINDOW = 1

local hrp, humanoid, animator
local trackCache = {} -- [nom d'anim] = AnimationTrack, pour le personnage actuel
local currentLocomotion = nil -- "Idle", "Walk" ou nil si rien ne joue
local comboState = nil
local isParrying = false
local isStunned = false
local lastPredictedParry = -math.huge

-- 🚫 DÉSACTIVATION DU JUMP
local function disableJump(hum)
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	hum.JumpPower = 0
	hum.JumpHeight = 0
end

local function setCombo(state)
	comboState = state
	CombatState.comboStep = state and state.step or 0
end

local function onCharacterAdded(char)
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
	-- L'Animator doit venir du serveur (CharacterRespawn) pour que nos anims se répliquent
	animator = humanoid:WaitForChild("Animator")

	trackCache = {}
	currentLocomotion = nil
	setCombo(nil)
	isParrying = false
	isStunned = false

	Workspace.CurrentCamera.CameraSubject = humanoid
	disableJump(humanoid)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

local function getTrack(name)
	local track = trackCache[name]
	if not track then
		local anim = Animations:FindFirstChild(name)
		if not anim then return nil end
		track = animator:LoadAnimation(anim)
		trackCache[name] = track
	end
	return track
end

local function stopAllAnimations()
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.1)
	end
	currentLocomotion = nil
end

-- Vrai si une action (combo, parry, stun) occupe le personnage
local function isBusy()
	return comboState ~= nil or isParrying or isStunned
end

-- Vrai si le joueur ne peut pas agir (cinématique, fin de match, mort simulée, parry, stun)
local function isActionBlocked()
	return not animator
		or Workspace:GetAttribute("MatchOver")
		or player:GetAttribute("MovementLocked")
		or player:GetAttribute("SimulatedDead")
		or isParrying
		or isStunned
end

-- Fige le perso tout de suite sans attendre le WalkSpeed du serveur (qui suit peu après).
-- Si le serveur n'a finalement rien bloqué, on remet la vitesse nous-mêmes.
local function freezeLocally(duration)
	local hum = humanoid
	local savedSpeed = hum.WalkSpeed
	if savedSpeed <= 0 then return end
	hum.WalkSpeed = 0

	task.delay(duration, function()
		if hum.Parent and hum.WalkSpeed == 0 and not (
			Workspace:GetAttribute("MatchOver")
			or player:GetAttribute("MovementLocked")
			or player:GetAttribute("Stunned")
		) then
			hum.WalkSpeed = savedSpeed
		end
	end)
end

-- 💫 STUN : prédit localement quand on frappe un parry, ou annoncé par le serveur
local function enterStun()
	if isStunned or not animator then return end
	isStunned = true

	setCombo(nil)
	stopAllAnimations()
	freezeLocally(CombatConfig.STUN_DURATION)
	local track = getTrack("Stun")
	if track then
		track:Play(0)
	end

	task.delay(CombatConfig.STUN_DURATION, function()
		-- Le serveur peut encore nous garder stun s'il a reçu le coup en retard
		if not player:GetAttribute("Stunned") then
			isStunned = false
		end
	end)
end

player:GetAttributeChangedSignal("Stunned"):Connect(function()
	if player:GetAttribute("Stunned") then
		enterStun()
	else
		isStunned = false
	end
end)

-- Le serveur annonce un parry réussi : étincelles, sauf si on les a déjà prédites
parryEffectRemote.OnClientEvent:Connect(function(attacker, position)
	if attacker == player and os.clock() - lastPredictedParry < PARRY_PREDICTION_WINDOW then
		return
	end
	ParryEffects.play(position)
end)

-- Écoute nos propres hitboxes : si on touche quelqu'un qui parry, on prédit le stun tout de suite
local function watchParryHits()
	local char = player.Character
	local weaponNames = CombatConfig.ATTACK_WEAPONS[player:GetAttribute("Class")]
	if not char or not weaponNames then return end

	local connections = {}
	local function disconnectAll()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	local function onTouched(hitbox, part)
		local targetChar = part:FindFirstAncestorOfClass("Model")
		if not targetChar or targetChar == char then return end

		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		if not (targetPlayer and targetPlayer:GetAttribute("Parrying")) then return end

		disconnectAll()
		lastPredictedParry = os.clock()
		ParryEffects.play(hitbox.Position)
		enterStun()
		-- Notre anim est coupée : on prévient le serveur pour que l'autre joueur voie le parry aussi
		parryHitRemote:FireServer(targetPlayer, hitbox.Position)
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

	task.delay(CombatConfig.HITBOX_DURATION, disconnectAll)
end

-- 🚶‍♂️ IDLE / WALK selon la vitesse, seulement quand aucune action ne joue
local function updateLocomotion()
	if not (hrp and animator) or isBusy() then return end

	local velocity = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	local state = velocity.Magnitude > 1 and "Walk" or "Idle"
	if state == currentLocomotion then return end

	local track = getTrack(state)
	if not track then return end

	local previous = currentLocomotion and trackCache[currentLocomotion]
	if previous then
		previous:Stop(0.2)
	end
	track.Looped = true
	track:Play(0.2)
	currentLocomotion = state
end

local playAttack

-- Ouvre la fenêtre de combo quand l'anim atteint son marker
local function setupComboWindow(track, state)
	local markerName = CombatConfig.COMBO_MARKERS[state.step]
	if not markerName then return end

	local connection
	connection = track:GetMarkerReachedSignal(markerName):Connect(function()
		connection:Disconnect()
		if comboState ~= state then return end

		state.canBuffer = true
		-- Le joueur a cliqué trop tôt : on enchaîne direct
		if state.buffer then
			playAttack(state.step + 1)
			return
		end

		task.delay(CombatConfig.COMBO_BUFFER_WINDOW, function()
			if comboState == state then
				setCombo(nil)
			end
		end)
	end)

	-- On coupe l'écoute si l'anim s'arrête avant le marker
	track.Stopped:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end

function playAttack(step)
	if step > CombatConfig.MAX_COMBO_STEP then return end

	local anim = Animations:FindFirstChild("Hit" .. step)
	if not anim then return end

	-- Le nouvel état passe avant l'arrêt des anims, pour que le Stopped du coup précédent ne reset pas ce combo
	local state = {
		step = step,
		buffer = false,
		canBuffer = false,
	}
	setCombo(state)

	stopAllAnimations()

	-- Track neuve à chaque coup : ses signaux ne concernent que ce coup-là
	local track = animator:LoadAnimation(anim)
	track:Play()
	attackRemote:FireServer(step)
	watchParryHits()
	setupComboWindow(track, state)

	track.Stopped:Once(function()
		if comboState == state then
			setCombo(nil)
		end
	end)
end

local function onAttack()
	if isActionBlocked() then return end

	local state = comboState
	if not state then
		-- Premier coup
		playAttack(1)
	elseif state.canBuffer then
		-- Enchaînement combo
		playAttack(state.step + 1)
	else
		-- Clique trop tôt : enchaîne dès que la fenêtre s'ouvre
		state.buffer = true
	end
end

local function onParry()
	if isActionBlocked() or not CombatState.isReady("Parry") then return end

	isParrying = true
	setCombo(nil)
	stopAllAnimations()
	freezeLocally(CombatConfig.PARRY_DURATION)
	CombatState.startCooldown("Parry", CombatConfig.PARRY_COOLDOWN)

	local track = getTrack("Parry")
	if track then
		track:Play()
	end
	parryRemote:FireServer()

	task.delay(CombatConfig.PARRY_DURATION, function()
		isParrying = false
	end)
end

local function onDash()
	if isActionBlocked() or not CombatState.isReady("Dash") then return end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.1 then return end

	local localMoveDir = hrp.CFrame:VectorToObjectSpace(moveDir)
	local direction
	if math.abs(localMoveDir.X) > math.abs(localMoveDir.Z) then
		direction = localMoveDir.X > 0 and "Right" or "Left"
	else
		direction = localMoveDir.Z > 0 and "Back" or "Front"
	end

	CombatState.startCooldown("Dash", CombatConfig.DASH_COOLDOWN)
	dashRemote:FireServer(direction)

	for name in pairs(CombatConfig.DASH_DIRECTIONS) do
		local track = trackCache["Dash" .. name]
		if track and track.IsPlaying then
			track:Stop(0.1)
		end
	end
	local dashTrack = getTrack("Dash" .. direction)
	if dashTrack then
		dashTrack:Play()
	end

	local dashDir = moveDir
	if direction == "Left" then
		dashDir = -hrp.CFrame.RightVector
	elseif direction == "Right" then
		dashDir = hrp.CFrame.RightVector
	end

	-- Le client possède la physique de son perso : la vélocité s'applique sans délai
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = dashDir.Unit * CombatConfig.DASH_SPEED
	bv.MaxForce = Vector3.new(1, 0, 1) * 500000
	bv.P = 1250
	bv.Parent = hrp
	Debris:AddItem(bv, CombatConfig.DASH_DURATION)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not humanoid then return end

	-- 🔁 ATTAQUE (Clic gauche)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		onAttack()

	-- 🛡️ PARRY (Clic droit)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		onParry()

	-- 💨 DASH (Touche Q)
	elseif input.KeyCode == Enum.KeyCode.Q then
		onDash()
	end
end)

RunService.RenderStepped:Connect(updateLocomotion)
