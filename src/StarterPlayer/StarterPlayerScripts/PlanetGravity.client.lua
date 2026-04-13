--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Path to Wallstick module
local WallstickClass = require(ReplicatedStorage:WaitForChild("Wallstick"))
local Replication = require(ReplicatedStorage.Wallstick.Replication)

local function onCharacterAdded(character: Model)
    local wallstickModel = workspace:WaitForChild("Wallstick") :: Model
    local wallstickOrigin = wallstickModel:WaitForChild("Origin") :: BasePart

    local wallstick = WallstickClass.new({
        parent = wallstickModel,
        origin = wallstickOrigin.CFrame,
        retainWorldVelocity = true,
        camera = {
            tilt = true,
            spin = true,
        },
    })

    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

    -- Every frame before physics simulation
    local simulationConnection = RunService.PreSimulation:Connect(function(dt)
        if wallstick:getFallDistance() < -300 then
            -- Fall into abyss = reset gravity
            wallstick:set(workspace.Terrain, Vector3.yAxis)
            return
        end

        local closestPlanet: BasePart? = nil
        local shortestDist = math.huge

        -- 1. Find closest planet
        for _, planet in ipairs(CollectionService:GetTagged("PlanetNode")) do
            local pl = planet :: BasePart
            local dist = (hrp.Position - pl.Position).Magnitude
            -- Distance to surface
            local distToSurface = dist - (pl.Size.X / 2)
            
            if distToSurface < shortestDist then
                shortestDist = distToSurface
                closestPlanet = pl
            end
        end

        -- 2. Apply gravity to found planet
        if closestPlanet then
            -- Vector from planet center to player
            local worldNormal = (hrp.Position - closestPlanet.Position).Unit
            
            -- EgoMoose controller needs normal in object space
            local localNormal = closestPlanet.CFrame:VectorToObjectSpace(worldNormal)
            
            wallstick:set(closestPlanet, localNormal)
        end
    end)

    humanoid.Died:Wait()
    simulationConnection:Disconnect()
    wallstick:Destroy()
end

if Players.LocalPlayer.Character then
    onCharacterAdded(Players.LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
Replication.listenClient()
