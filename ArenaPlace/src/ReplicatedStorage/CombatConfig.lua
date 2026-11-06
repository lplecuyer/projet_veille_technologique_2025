-- Constantes de combat partagées : le client s'en sert pour prédire, le serveur pour valider
local CombatConfig = {}

CombatConfig.DASH_SPEED = 100
CombatConfig.DASH_DURATION = 0.2
CombatConfig.DASH_COOLDOWN = 2
CombatConfig.DASH_DIRECTIONS = { Front = true, Back = true, Left = true, Right = true }

CombatConfig.MAX_COMBO_STEP = 3
CombatConfig.COMBO_BUFFER_WINDOW = 0.6
CombatConfig.COMBO_MARKERS = { "ComboWindow", "ComboWindow2" } -- marker du step 1, puis du step 2
CombatConfig.HITBOX_DURATION = 0.7

-- Armes qui portent une Hitbox, par classe
CombatConfig.ATTACK_WEAPONS = {
	Knight = { "Sword" },
	Rogue = { "Dagger1", "Dagger2" },
}

CombatConfig.PARRY_DURATION = 1.5
-- Délai entre le début d'un parry et le suivant (inclut la durée du parry)
CombatConfig.PARRY_COOLDOWN = 4
CombatConfig.STUN_DURATION = 2.25

return CombatConfig
