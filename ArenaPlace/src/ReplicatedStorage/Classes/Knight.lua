local Knight = {}

Knight.Name = "Knight"
Knight.Weapons = { "Sword", "Shield" }

Knight.Moveset = {
    Q = "ShieldParry",
    LeftClick = "BasicAttack",
    RightClick = "HeavyAttack",
    Shift = "DirectionalDash",
    F = "BlockProjectiles"
}

return Knight
