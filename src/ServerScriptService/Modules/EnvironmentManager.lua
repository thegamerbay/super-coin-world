--!strict
local EnvironmentManager = {}
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local TREE_IDS = {
    12549617200
}

-- Removed flat SPAWN_ZONES

function EnvironmentManager.spawnTrees()
    -- Only spawn trees on planets
    local planets = CollectionService:GetTagged("PlanetNode")
    if #planets == 0 then return end

    -- Create overlap parameters to ignore planets
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = planets

    for _, targetPlanet in ipairs(planets) do
        local pl = targetPlanet :: BasePart
        
        local treeCount = 5
        if pl.Name == "Planet_Start" then
            treeCount = 10
        elseif pl.Name == "Planet_Sand" then
            treeCount = 40
        end

        local radius = (pl.Size.X / 2)
        
        for i = 1, treeCount do
            local randomId = TREE_IDS[math.random(1, #TREE_IDS)]
            
            -- Load the asset model from the Roblox cloud
        local success, loadedModel = pcall(function()
            return InsertService:LoadAsset(randomId)
        end)

        if success and loadedModel then
            -- Extract the tree itself from the InsertService wrapper
            local tree = loadedModel:GetChildren()[1]
            if not tree or not tree:IsA("Model") then
                loadedModel:Destroy()
                continue
            end

            -- 🛡️ ANTI-VIRUS: Remove any scripts from the free model
            for _, desc in pairs(tree:GetDescendants()) do
                if desc:IsA("Script") or desc:IsA("LocalScript") then
                    desc:Destroy()
                end
            end

            -- Anchor all parts so the tree doesn't fall apart
            for _, part in pairs(tree:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                end
            end

            tree.Parent = Workspace
            local boundingBoxCFrame, size = tree:GetBoundingBox()
            
            -- Search for a free spot on the planet's surface (up to 15 attempts)
            local finalCFrame = nil
            for _ = 1, 15 do
                local u = math.random()
                local v = math.random()
                local theta = 2 * math.pi * u
                local phi = math.acos(2 * v - 1)

                -- Offset by half the tree's height so it sits on the surface
                -- Minus 1.5 studs so the roots sink into the ground and don't hover
                local spawnRadius = radius + (size.Y / 2) - 1.5

                local x = spawnRadius * math.sin(phi) * math.cos(theta)
                local y = spawnRadius * math.sin(phi) * math.sin(theta)
                local z = spawnRadius * math.cos(phi)

                local worldPos = targetPlanet.Position + Vector3.new(x, y, z)
                
                -- The tree base usually needs to look away from the center
                -- And usually models stand up on the Y axis
                local testCFrame = CFrame.lookAt(worldPos, targetPlanet.Position) * CFrame.Angles(math.pi/2, 0, 0)

                -- Check if there's another tree or object here
                local partsInside = Workspace:GetPartBoundsInBox(testCFrame, size, overlapParams)

                if #partsInside == 0 then
                    finalCFrame = testCFrame
                    break
                end
            end

            if finalCFrame then
                -- Smoothly move the model to the found spherical location
                -- Determine the offset between the model's Pivot and its bounding box center
                local pivotOffset = tree:GetPivot():ToObjectSpace(boundingBoxCFrame)
                tree:PivotTo(finalCFrame * pivotOffset:Inverse())
            else
                -- If we couldn't find a spot, delete the tree
                tree:Destroy()
            end
            
            loadedModel:Destroy()
        else
            if loadedModel then
                loadedModel:Destroy()
            end
        end
    end
    end
end

return EnvironmentManager
