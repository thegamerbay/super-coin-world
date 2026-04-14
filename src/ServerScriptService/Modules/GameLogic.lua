--!strict
local GameLogic = {}
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

local coinStore
local leaderboardStore
pcall(function()
    coinStore = DataStoreService:GetDataStore("PlayerCoinsStore")
    leaderboardStore = DataStoreService:GetOrderedDataStore("GlobalCoinLeaderboard")
end)

local CoinManager = require(script.Parent.CoinManager)
local EnvironmentManager = require(script.Parent.EnvironmentManager)
local ShopManager = require(script.Parent.ShopManager)

-- Updated save function
local function savePlayerData(player: Player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins and coins:IsA("IntValue") then
            
            -- NEW: Save an entire table (Dictionary) of data
            local dataToSave = {
                coins = coins.Value,
                SpeedPurchases = player:GetAttribute("SpeedPurchases") or 0,
                JumpPurchases = player:GetAttribute("JumpPurchases") or 0
            }
            
            if coinStore then
                pcall(function()
                    coinStore:SetAsync(tostring(player.UserId), dataToSave)
                end)
            end
            
            -- For the leaderboard, we continue to save just one number
            if leaderboardStore then
                pcall(function()
                    leaderboardStore:SetAsync(tostring(player.UserId), coins.Value)
                end)
            end
        end
    end
end

function GameLogic.init()
    ShopManager.init()

    -- Remove any pre-existing Baseplate (like from Roblox templates)
    local existingBaseplate = Workspace:FindFirstChild("Baseplate")
    if existingBaseplate then
        existingBaseplate:Destroy()
    end

    -- 1. Create Start Planet
    local planet1 = Instance.new("Part")
    planet1.Name = "Planet_Start"
    planet1.Shape = Enum.PartType.Ball
    planet1.Size = Vector3.new(80, 80, 80)
    planet1.Position = Vector3.new(0, 0, 0) 
    planet1.Anchored = true
    planet1.BrickColor = BrickColor.new("Dark green")
    planet1.Material = Enum.Material.Grass
    planet1.Parent = Workspace
    CollectionService:AddTag(planet1, "PlanetNode")

    -- 2. Create Ice Planet
    local planet2 = Instance.new("Part")
    planet2.Name = "Planet_Ice"
    planet2.Shape = Enum.PartType.Ball
    planet2.Size = Vector3.new(50, 50, 50)
    planet2.Position = Vector3.new(120, 50, 0)
    planet2.Anchored = true
    planet2.BrickColor = BrickColor.new("Institutional white")
    planet2.Material = Enum.Material.Ice
    planet2.Parent = Workspace
    CollectionService:AddTag(planet2, "PlanetNode")

    -- 3. Create Sand Planet
    local planet3 = Instance.new("Part")
    planet3.Name = "Planet_Sand"
    planet3.Shape = Enum.PartType.Ball
    planet3.Size = Vector3.new(160, 160, 160)
    -- Opposite direction of Ice, distance of centers = 250
    planet3.Position = Vector3.new(-230.77, -96.15, 0)
    planet3.Anchored = true
    planet3.BrickColor = BrickColor.new("Sand")
    planet3.Material = Enum.Material.Sand
    planet3.Parent = Workspace
    CollectionService:AddTag(planet3, "PlanetNode")

    -- 4. Spawn point on top of first planet
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Size = Vector3.new(6, 1, 6)
    spawnLocation.Position = Vector3.new(0, 40, 0) -- Y = 40 (half size of planet 80)
    spawnLocation.Anchored = true
    spawnLocation.Transparency = 1
    spawnLocation.Parent = Workspace

    task.spawn(function()
        EnvironmentManager.spawnTrees()
    end)

    Players.PlayerAdded:Connect(GameLogic.onPlayerAdded)
    Players.PlayerRemoving:Connect(function(player: Player)
        savePlayerData(player)
    end)

    for _, planet in ipairs(CollectionService:GetTagged("PlanetNode")) do
        local maxCoins = 8
        if planet.Name == "Planet_Ice" then
            maxCoins = 16
        elseif planet.Name == "Planet_Sand" then
            maxCoins = 64
        end
        for i = 1, maxCoins do
            CoinManager.spawnCoin(planet :: BasePart)
        end
    end

    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                savePlayerData(player)
            end
        end
    end)
end

function GameLogic.onPlayerAdded(player: Player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    -- Load data
    local success, savedData = false, nil
    if coinStore then
        success, savedData = pcall(function()
            return coinStore:GetAsync(tostring(player.UserId))
        end)
    end

    if success and savedData then
        -- DATA MIGRATION: If the player played before, their save is a number
        if type(savedData) == "number" then
            coins.Value = savedData
        -- If they already have a new save, it's a table
        elseif type(savedData) == "table" then
            coins.Value = savedData.coins or 0
            player:SetAttribute("SpeedPurchases", savedData.SpeedPurchases or 0)
            player:SetAttribute("JumpPurchases", savedData.JumpPurchases or 0)
        end
    end

    -- NEW: Every time the character spawns/respawns, apply the boosts
    player.CharacterAdded:Connect(function(character)
        ShopManager.applyUpgrades(player, character)
    end)
end

return GameLogic
