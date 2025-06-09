local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MovementRequest")
local dashRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DashRequest")
local attackRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AttackRequest")
local Animations = ReplicatedStorage:WaitForChild("Animations")

local DASH_SPEED = 100
local DASH_DURATION = 0.2
local DASH_COOLDOWN = 2

local lastDashTimes = {} -- stocke les timestamps des dashs

local comboState = {}

local function stopAllAnimations(humanoid)
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop(0.1)
	end
end

local function resetCombo(player, humanoid)
	comboState[player] = nil
	local idle = Animations:FindFirstChild("Idle")
	if idle then
		local idleTrack = humanoid:LoadAnimation(idle)
		idleTrack.Looped = true
		idleTrack:Play()
	end
end

attackRemote.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	local state = comboState[player]

	-- On bloque les inputs s'ils ne sont pas dans une fenêtre combo
	if state and not state.canBuffer then
		return
	end

	if not state then
		-- Début combo Hit1
		stopAllAnimations(humanoid)
		local track = humanoid:LoadAnimation(Animations:FindFirstChild("Hit1"))
		comboState[player] = {step = 1, buffer = false, canBuffer = false}
		track:Play()

		track:GetMarkerReachedSignal("ComboWindow"):Connect(function()
			comboState[player].canBuffer = true
			task.delay(0.6, function()
				if comboState[player] and comboState[player].buffer then
					comboState[player].canBuffer = false
					attackRemote:FireServer(player)
				else
					resetCombo(player, humanoid)
				end
			end)
		end)

		track.Stopped:Connect(function()
			if comboState[player] and comboState[player].step == 1 then
				resetCombo(player, humanoid)
			end
		end)
	elseif state.step == 1 then
		-- Hit2
		stopAllAnimations(humanoid)
		local track = humanoid:LoadAnimation(Animations:FindFirstChild("Hit2"))
		comboState[player] = {step = 2, buffer = false, canBuffer = false}
		track:Play()

		track:GetMarkerReachedSignal("ComboWindow2"):Connect(function()
            comboState[player] = {step = 2, buffer = false, canBuffer = false}
			comboState[player].canBuffer = true
			task.delay(0.6, function()
				if comboState[player] and comboState[player].buffer then
					comboState[player].canBuffer = false
					attackRemote:FireServer(player)
				else
					resetCombo(player, humanoid)
				end
			end)
		end)

		track.Stopped:Connect(function()
			if comboState[player] and comboState[player].step == 2 then
				resetCombo(player, humanoid)
			end
		end)
	elseif state.step == 2 then
		-- Hit3
		stopAllAnimations(humanoid)
		local track = humanoid:LoadAnimation(Animations:FindFirstChild("Hit3"))
		comboState[player] = nil
		track:Play()

		track.Stopped:Connect(function()
			resetCombo(player, humanoid)
		end)
	end
end)


-- Idle / Walk
remote.OnServerEvent:Connect(function(player, state)
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
	local now = tick()
	if lastDashTimes[player] and now - lastDashTimes[player] < DASH_COOLDOWN then
		return -- cooldown pas encore fini
	end
	lastDashTimes[player] = now

	print("[Dash] Direction:", direction)

	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

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


-- Nettoyage à la déconnexion
Players.PlayerRemoving:Connect(function(player)
	lastDashTimes[player] = nil
end)
