-- Sons du jeu, joués localement par chaque client (voir SoundsHandler et ParryEffects)
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local CombatSounds = {}

-- Remplacer les ID par des sons de la Creator Store (Toolbox > Audio)
-- pitch : plage de PlaybackSpeed aléatoire, pour que deux coups ne sonnent pas pareil
local SOUNDS = {
	Ambience = { id = "rbxassetid://0", volume = 0.3 }, -- foule d'arène, en boucle
	Swing = { id = "rbxassetid://0", volume = 0.6, pitch = { 0.9, 1.1 } }, -- épée qui fend l'air
	Hit = { id = "rbxassetid://0", volume = 0.8, pitch = { 0.9, 1.05 } }, -- épée qui touche un joueur
	ParryWhiff = { id = "rbxassetid://0", volume = 0.5, pitch = { 0.95, 1.05 } }, -- parry levé dans le vide
	ParryClang = { id = "rbxassetid://0", volume = 1, pitch = { 0.95, 1.1 } }, -- parry réussi, métal contre métal
	Dash = { id = "rbxassetid://0", volume = 0.6, pitch = { 0.95, 1.1 } },
}

-- Distance (studs) où les sons 3D commencent à baisser, puis deviennent inaudibles
local ROLLOFF_MIN = 10
local ROLLOFF_MAX = 120
-- Filet de sécurité si un son ne déclenche jamais Ended (ID invalide, etc.)
local MAX_SOUND_LIFETIME = 10

local function getDefinition(name)
	local def = SOUNDS[name]
	if def and def.id ~= "rbxassetid://0" then
		return def
	end
	return nil
end

local function createSound(def)
	local sound = Instance.new("Sound")
	sound.SoundId = def.id
	sound.Volume = def.volume
	if def.pitch then
		sound.PlaybackSpeed = def.pitch[1] + math.random() * (def.pitch[2] - def.pitch[1])
	end
	return sound
end

-- Joue un son 3D attaché à `parent` (une BasePart ou une Attachment)
function CombatSounds.playOn(name, parent)
	local def = getDefinition(name)
	if not def or not parent then return end

	local sound = createSound(def)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = ROLLOFF_MIN
	sound.RollOffMaxDistance = ROLLOFF_MAX
	sound.Parent = parent
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, MAX_SOUND_LIFETIME)
end

-- Joue un son 3D à une position du monde
function CombatSounds.playAt(name, position)
	if not getDefinition(name) then return end

	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.WorldPosition = position
	CombatSounds.playOn(name, attachment)
	Debris:AddItem(attachment, MAX_SOUND_LIFETIME)
end

-- Ambiance de foule en boucle, non spatialisée
function CombatSounds.startAmbience()
	local def = getDefinition("Ambience")
	if not def then return end

	local sound = createSound(def)
	sound.Name = "Ambience"
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()
end

return CombatSounds
