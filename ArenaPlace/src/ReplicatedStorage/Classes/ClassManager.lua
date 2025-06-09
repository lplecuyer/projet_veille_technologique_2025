local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassModels = ReplicatedStorage:WaitForChild("ClassModels")

local ClassManager = {}

ClassManager.Classes = {
    Knight = {
        Name = "Knight",
        CharacterModel = ClassModels.Knight:FindFirstChild("Character"),
        Weapons = {
            ClassModels.Knight:FindFirstChild("Sword"),
            ClassModels.Knight:FindFirstChild("Shield")
        },
        Moveset = {
            Q = "ShieldParry",
            LeftClick = "BasicAttack",
            RightClick = "HeavyAttack",
            Shift = "DirectionalDash",
            F = "BlockProjectiles"
        }
    },
    
    Rogue = {
        Name = "Rogue",
        CharacterModel = ClassModels.Rogue:FindFirstChild("Character"),
        Weapons = {
            ClassModels.Rogue:FindFirstChild("Dagger1"),
            ClassModels.Rogue:FindFirstChild("Dagger2")
        },
        Moveset = {
            Q = "Invisibility",
            LeftClick = "BasicAttack",
            RightClick = "DaggerThrow",
            Shift = "RollDash"
        }
    }
}

function ClassManager:GetClass(name)
    return self.Classes[name]
end

return ClassManager
