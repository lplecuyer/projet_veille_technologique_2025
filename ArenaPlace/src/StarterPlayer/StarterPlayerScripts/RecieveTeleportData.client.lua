local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local classRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ClassAssignmentRequest")

if RunService:IsStudio() then
    local selectedClass = "Knight"
    print("[Client] Mode Studio détecté, envoi de la classe Knight")
    classRemote:FireServer(selectedClass)
else
    local teleportData = TeleportService:GetLocalPlayerTeleportData()
    print("teleport data table : ", teleportData)

    if teleportData and teleportData.Players then
        local userId = Players.LocalPlayer.UserId
        local selectedClass = teleportData.Players[tostring(game.Players.LocalPlayer.UserId)]


        print("[Client] TeleportData reçu :")
        print(teleportData)

        if selectedClass then
            print("[Client] Classe détectée :", selectedClass)
            classRemote:FireServer(selectedClass)
        else
            warn("[Client] Classe non trouvée pour userId", userId)
        end
    else
        warn("[Client] TeleportData est vide ou invalide")
    end
end
