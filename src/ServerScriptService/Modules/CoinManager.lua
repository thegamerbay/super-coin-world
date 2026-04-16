--!strict
local CoinManager = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

export type CoinStats = {
    value: number,
    diameter: number,
    thickness: number,
    color: Color3
}

-- ==========================================
-- 1. PURE LOGIC (Ideal for testing)
-- ==========================================
CoinManager.Logic = {}

-- Check if a rare coin should drop (20% chance)
function CoinManager.Logic.isRare(randomRoll: number): boolean
    return randomRoll <= 20
end

-- Get all coin stats based on rarity
function CoinManager.Logic.getCoinStats(isRare: boolean): CoinStats
    if isRare then
        return { value = 5, diameter = 4, thickness = 0.4, color = Color3.fromRGB(255, 120, 0) } -- Crisp glowing orange
    else
        return { value = 1, diameter = 2.5, thickness = 0.2, color = Color3.fromRGB(255, 235, 0) } -- Classic yellow
    end
end

-- ==========================================
-- 2. ROBLOX ENGINE LOGIC (Effects and Spawn)
-- ==========================================
function CoinManager.createCollectEffect(position: Vector3, color: Color3)
    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = Workspace.Terrain

    local particle = Instance.new("ParticleEmitter")
    particle.Color = ColorSequence.new(color)
    particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
    particle.Speed = NumberRange.new(15, 25)
    particle.Lifetime = NumberRange.new(0.5, 1)
    particle.SpreadAngle = Vector2.new(180, 180)
    particle.Parent = attachment

    particle:Emit(30)
    Debris:AddItem(attachment, 1.5)
end

function CoinManager.spawnCoin(specificPlanet: BasePart?)
    -- Use our testable logic
    local randomRoll = math.random(1, 100)
    local isRare = CoinManager.Logic.isRare(randomRoll)
    local stats = CoinManager.Logic.getCoinStats(isRare)

    -- Create physical object (Hitbox only)
    local coin = Instance.new("Part")
    coin.Name = isRare and "RareCoin" or "Coin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Size = Vector3.new(stats.thickness, stats.diameter, stats.diameter)
    
    -- === SPHERICAL GENERATION LOGIC ===
    local finalPos: Vector3 = Vector3.new(0, 0, 0)
    local targetPlanet: BasePart? = specificPlanet

    if specificPlanet then
        -- Create overlap parameters to ignore planets for spawn clearance
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {specificPlanet}
        
        local radius = (specificPlanet.Size.X / 2) + (stats.diameter / 2) -- Radius + coin half-height

        for iter = 1, 15 do
            -- Generate a random point on a sphere (uniform distribution)
            local u = math.random()
            local v = math.random()
            local theta = 2 * math.pi * u
            local phi = math.acos(2 * v - 1)

            local x = radius * math.sin(phi) * math.cos(theta)
            local y = radius * math.sin(phi) * math.sin(theta)
            local z = radius * math.cos(phi)

            local testPos = targetPlanet.Position + Vector3.new(x, y, z)
            
            -- Check if spot is free
            local partsInside = Workspace:GetPartBoundsInBox(CFrame.new(testPos), coin.Size, overlapParams)
            if #partsInside == 0 then
                finalPos = testPos
                break
            end
        end
    end

    if targetPlanet then
        -- Look away from the planet so the coin isn't "laying flat" against it
        coin.CFrame = CFrame.lookAt(finalPos, targetPlanet.Position) * CFrame.Angles(math.pi/2, 0, 0)
    else
        coin.Position = finalPos
    end
    -- =======================================
    coin.Transparency = 1 -- Invisible on the server
    coin.Color = stats.color
    coin.Material = Enum.Material.Neon
    coin.Anchored = true
    coin.CanCollide = false
    
    -- Tag the coin so the client knows to animate it
    CollectionService:AddTag(coin, "AnimatedCoin")

    coin.Parent = Workspace

    -- Setup Memory Management
    local coinTrove = Trove.new()
    coinTrove:AttachToInstance(coin) -- Ensures trove cleans up if coin is destroyed externally

    -- Collecting event
    local touchConnection = coin.Touched:Connect(function(otherPart)
        CoinManager.handleCoinTouched(otherPart, coin, coinTrove, stats, targetPlanet)
    end)
    
    coinTrove:Add(touchConnection)
end

function CoinManager.handleCoinTouched(otherPart: BasePart, coin: BasePart, coinTrove: any, stats: CoinStats, originPlanet: BasePart?)
    local character = otherPart.Parent
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")

    if humanoid then
        local player = Players:GetPlayerFromCharacter(character)
        local isCoinCollectorNpc = CollectionService:HasTag(character, "CoinCollector")
        
        if player or isCoinCollectorNpc then
            local collectPos = coin.Position
            local collectColor = coin.Color

            -- This will disconnect touched event and destroy the coin
            coinTrove:Clean() 
            if coin and coin.Parent then
                coin:Destroy()
            end

            if player then
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    local coins = leaderstats:FindFirstChild("Coins")
                    if coins and coins:IsA("IntValue") then
                        coins.Value += stats.value
                    end
                end
            end
            
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://127645268874265"
            sound.Volume = 0.8
            sound.Parent = character:FindFirstChild("Head") or Workspace
            sound:Play()
            Debris:AddItem(sound, 2)

            CoinManager.createCollectEffect(collectPos, collectColor)
            
            task.wait(1)
            CoinManager.spawnCoin(originPlanet)
        end
    end
end

return CoinManager
