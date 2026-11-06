-- Effet de parry réussi (étincelles + son), joué localement par chaque client
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatSounds = require(ReplicatedStorage:WaitForChild("CombatSounds"))

local ParryEffects = {}

local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SPARK_COUNT = 30
local LIFETIME = 0.6

function ParryEffects.play(position)
	CombatSounds.playAt("ParryClang", position)

	local anchor = Instance.new("Part")
	anchor.Name = "ParrySparks"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position

	local attachment = Instance.new("Attachment")
	attachment.Parent = anchor

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = SPARK_TEXTURE
	sparks.Enabled = false
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 220)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 200, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 110, 30)),
	})
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Lifetime = NumberRange.new(0.15, 0.4)
	sparks.Speed = NumberRange.new(18, 35)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 6
	sparks.Acceleration = Vector3.new(0, -40, 0)
	-- Étirées dans le sens du mouvement, comme de vraies étincelles
	sparks.Orientation = Enum.ParticleOrientation.VelocityParallel
	sparks.Squash = NumberSequence.new(-1.5)
	sparks.Parent = attachment

	-- Petit flash de lumière au point d'impact
	local flash = Instance.new("PointLight")
	flash.Color = Color3.fromRGB(255, 200, 100)
	flash.Brightness = 6
	flash.Range = 10
	flash.Parent = anchor

	anchor.Parent = workspace
	sparks:Emit(SPARK_COUNT)

	task.delay(0.12, function()
		flash.Enabled = false
	end)
	Debris:AddItem(anchor, LIFETIME)
end

return ParryEffects
