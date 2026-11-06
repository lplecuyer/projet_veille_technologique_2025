-- État de combat du joueur local, partagé entre AnimateOverride (qui l'écrit) et ActionBarUI (qui l'affiche)
local CombatState = {}

local readyAt = {} -- [action] = os.clock() où l'action redevient dispo
local durations = {} -- [action] = durée totale du dernier cooldown

CombatState.comboStep = 0

function CombatState.startCooldown(action, duration)
	readyAt[action] = os.clock() + duration
	durations[action] = duration
end

function CombatState.isReady(action)
	return os.clock() >= (readyAt[action] or 0)
end

-- Temps restant et durée totale du cooldown (0, 0 si l'action est prête)
function CombatState.getCooldown(action)
	local remaining = math.max(0, (readyAt[action] or 0) - os.clock())
	return remaining, durations[action] or 0
end

return CombatState
