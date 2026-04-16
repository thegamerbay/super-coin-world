--!strict
local NpcManager = {}
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local overrideCache = {}

local function getOverrideData(assetId: number)
    if overrideCache[assetId] then return overrideCache[assetId] end
    
    local data = { scripts = {} }
    local success, model = pcall(function() return InsertService:LoadAsset(assetId) end)
    if success and model then
        local npc = model:GetChildren()[1]
        if npc then
            for _, desc in ipairs(npc:GetDescendants()) do
                if (desc:IsA("Script") or desc:IsA("LocalScript")) and desc.Name == "Animate" then
                    table.insert(data.scripts, desc:Clone())
                end
            end
        end
        model:Destroy()
    end
    
    overrideCache[assetId] = data
    return data
end


local function getPointOnSphere(center: Vector3, radius: number): Vector3
    local u = math.random()
    local v = math.random()
    local theta = 2 * math.pi * u
    local phi = math.acos(2 * v - 1)

    local x = radius * math.sin(phi) * math.cos(theta)
    local y = radius * math.sin(phi) * math.sin(theta)
    local z = radius * math.cos(phi)

    return center + Vector3.new(x, y, z)
end

local function getClearPointOnSphere(currentPos: Vector3, planetPos: Vector3, radius: number, rayParams: RaycastParams): Vector3
    local upNormal = (currentPos - planetPos).Unit
    for i = 1, 10 do
        local candidate = getPointOnSphere(planetPos, radius)
        local rawDir = (candidate - currentPos)
        if rawDir.Magnitude > 0.01 then
            local dot = rawDir:Dot(upNormal)
            local tangentDir = (rawDir - dot * upNormal).Unit
            -- Check if the line to candidate is clear for at least 15 studs (parallel to planet)
            if not Workspace:Raycast(currentPos, tangentDir * 15, rayParams) then
                return candidate
            end
        end
    end
    return getPointOnSphere(planetPos, radius)
end

function NpcManager.spawnNpc(planet: BasePart, assetId: number, speed: number, npcName: string, overrideScriptsAssetId: number?)
    local success, loadResult = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    
    if not success or not loadResult then
        warn("NpcManager: Failed to load asset ID " .. tostring(assetId) .. ". Error: " .. tostring(loadResult))
        if typeof(loadResult) == "Instance" then loadResult:Destroy() end
        return
    end
    
    local loadedModel = loadResult :: Model
    local npc = nil
    for _, child in ipairs(loadedModel:GetChildren()) do
        if child:IsA("Model") then
            npc = child
            break
        end
    end
    
    if not npc then 
        warn("NpcManager: Asset ID " .. tostring(assetId) .. " did not contain a Model.")
        loadedModel:Destroy()
        return 
    end
    
    -- Rename to standard
    npc.Name = npcName or "NPC"
    
    if overrideScriptsAssetId then
        local data = getOverrideData(overrideScriptsAssetId)
        
        -- Strip ALL old or broken free model scripts
        for _, desc in pairs(npc:GetDescendants()) do
            if desc:IsA("Script") or desc:IsA("LocalScript") then
                desc:Destroy()
            end
        end
        
        -- Fix missing HumanoidRootPart for ancient models
        local torso = npc:FindFirstChild("Torso")
        if torso and not npc:FindFirstChild("HumanoidRootPart") then
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.CFrame = torso.CFrame
            hrp.Transparency = 1
            hrp.CanCollide = false
            hrp.Parent = npc
            npc.PrimaryPart = hrp
        end
        
        -- Normalize ancient limb names just in case ("RightArm" -> "Right Arm")
        local standardNames = {"Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
        for _, name in ipairs(standardNames) do
            if not npc:FindFirstChild(name) then
                local alt = name:gsub(" ", "")
                local altPart = npc:FindFirstChild(alt)
                if altPart then altPart.Name = name end
            end
        end
        
        -- Vaporize old broken joints (Welds, Snaps, static Motors)
        for _, desc in pairs(npc:GetDescendants()) do
            if desc:IsA("JointInstance") then
                desc:Destroy()
            end
        end
        
        -- Master Rig Construction: Safely build R6 Motor6Ds exactly to spec
        local function makeMotor(name, p0Name, p1Name, c0, c1)
            local p0 = npc:FindFirstChild(p0Name)
            local p1 = npc:FindFirstChild(p1Name)
            if not p0 or not p1 then return end
            
            local motor = Instance.new("Motor6D")
            motor.Name = name
            motor.C0 = c0
            motor.C1 = c1
            motor.Part0 = p0
            motor.Part1 = p1
            motor.Parent = p0
        end

        makeMotor("RootJoint", "HumanoidRootPart", "Torso", CFrame.new(0,0,0, -1,0,0, 0,0,1, 0,1,0), CFrame.new(0,0,0, -1,0,0, 0,0,1, 0,1,0))
        makeMotor("Neck", "Torso", "Head", CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
        makeMotor("Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
        makeMotor("Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
        makeMotor("Right Hip", "Torso", "Right Leg", CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
        makeMotor("Left Hip", "Torso", "Left Leg", CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
        
        -- Inject scripts from the override asset
        for _, scriptObj in ipairs(data.scripts) do
            local clone = scriptObj:Clone()
            clone.Parent = npc
            clone.Enabled = false
            clone.Enabled = true
        end
    end
    
    -- Strip malicious or broken free model scripts (like old ZombieAI which spams 64 AnimationTracks)
    for _, desc in pairs(npc:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            if desc.Name ~= "Animate" then
                desc:Destroy()
            end
        end
    end
    
    local humanoid = npc:FindFirstChildWhichIsA("Humanoid") :: Humanoid
    local rootPart = (npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChild("Torso")) :: BasePart
    if not humanoid or not rootPart then
        warn("NpcManager: Asset ID " .. tostring(assetId) .. " is missing a Humanoid or RootPart/Torso.")
        loadedModel:Destroy()
        return
    end
    
    -- Setup Humanoid 
    humanoid.WalkSpeed = speed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- Hide the nametag
    
    -- Unanchor all parts so physics works
    for _, part in pairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
    
    -- Remove any old unusable sounds (like swoosh.wav) that cause console spam
    for _, desc in pairs(npc:GetDescendants()) do
        if desc:IsA("Sound") then
            desc:Destroy()
        end
    end
    
    -- Prevent normal physics states from messing up our custom gravity and triggering old falling sounds
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)

    -- Tag for CoinManager
    CollectionService:AddTag(npc, "CoinCollector")

    -- Fix the Zombie's native walk animation! The reason he looked like a Noob was because
    -- the Zombie speeds up into a "Run" state, and the default model has a normal Run animation.
    if npcName == "Drooling Zombie" then
        local animate = npc:FindFirstChild("Animate")
        if animate then
            local runValue = animate:FindFirstChild("run")
            if runValue then
                local runAnim = runValue:FindFirstChildWhichIsA("Animation")
                if runAnim then
                    runAnim.AnimationId = "http://www.roblox.com/asset/?id=183294396"
                end
            end
        end
    end

    -- Setup physical constraints for spherical walking
    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart

    -- Anti-gravity: keep upright
    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Attachment0 = attachment
    alignOrientation.Responsiveness = 200
    alignOrientation.MaxTorque = 100000000
    alignOrientation.Parent = rootPart
    
    -- Pull character to target position over the sphere
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPosition.Attachment0 = attachment
    alignPosition.ForceLimitMode = Enum.ForceLimitMode.Magnitude
    alignPosition.MaxForce = 100000000
    alignPosition.Responsiveness = 40
    alignPosition.Parent = rootPart
    
    local radius = planet.Size.X / 2
    local planetPos = planet.Position
    local spawnRadius = radius + 2.25 -- Adjusted static height offset (between 1.5 and 3)
    
    local initialTarget = getPointOnSphere(planetPos, radius)
    -- Initial Pivot to correctly face outward
    local upVector = (initialTarget - planetPos).Unit
    npc:PivotTo(CFrame.lookAt(initialTarget, initialTarget + Vector3.xAxis, upVector))
    
    alignPosition.Position = planetPos + upVector * spawnRadius
    alignOrientation.CFrame = CFrame.lookAt(initialTarget, initialTarget + Vector3.xAxis, upVector)
    
    npc.Parent = Workspace
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- AI Physics Loop
    task.spawn(function()
        local currentTarget = getClearPointOnSphere(rootPart.Position, planetPos, radius, rayParams)
        local lastPos = rootPart.Position
        local lastPosTime = os.clock()
        
        while npc and npc.Parent do
            task.wait(0.05) -- Fast update frequency for smooth movement
            
            local currentPos = rootPart.Position
            local upNormal = (currentPos - planetPos).Unit
            
            -- Find closest visible coin
            local coins = CollectionService:GetTagged("AnimatedCoin")
            local closestCoin = nil
            local closestDist = math.huge
            
            -- Exclude npc and all coins from blocking vision
            local excludeList = {npc}
            for _, c in ipairs(coins) do table.insert(excludeList, c) end
            rayParams.FilterDescendantsInstances = excludeList
            
            for _, coin in ipairs(coins) do
                -- check if coin is roughly on the same planet
                if (coin.Position - planetPos).Magnitude <= spawnRadius + 5 then
                    local dist = (coin.Position - currentPos).Magnitude
                    if dist < closestDist then
                        -- Line of sight raycast directly to coin (using tangent to avoid planet self-intersection)
                        local rawDirToCoin = coin.Position - currentPos
                        local dotCoin = rawDirToCoin:Dot(upNormal)
                        local tangentCoinDir = (rawDirToCoin - dotCoin * upNormal).Unit
                        
                        local rayHit = Workspace:Raycast(currentPos, tangentCoinDir * dist, rayParams)
                        -- If no obstacle hit, we can see the coin
                        if not rayHit then
                            closestDist = dist
                            closestCoin = coin
                        end
                    end
                end
            end
            
            if closestCoin then
                currentTarget = closestCoin.Position
            end

            -- Stuck check (1 second interval)
            if os.clock() - lastPosTime > 1.0 then
                if (currentPos - lastPos).Magnitude < 1.0 then
                    -- Stuck! Pick new point to avoid tree
                    currentTarget = getClearPointOnSphere(currentPos, planetPos, radius, rayParams)
                end
                lastPos = currentPos
                lastPosTime = os.clock()
            end
            
            -- Movement direction calculation (initial)
            local rawDir = (currentTarget - currentPos)
            local dot = rawDir:Dot(upNormal)
            local tangentDir = (rawDir - dot * upNormal).Unit
            
            -- Check if reached target (if tracking random point)
            if not closestCoin then
                local targetDist = (currentPos - (planetPos + ((currentTarget - planetPos).Unit * spawnRadius))).Magnitude
                if targetDist < 5 then
                    -- Reached target, pick a new clear one
                    currentTarget = getClearPointOnSphere(currentPos, planetPos, radius, rayParams)
                else
                    -- Predict collision using "feelers" 8 studs forward (uses tangent to avoid planet ground!)
                    if tangentDir.Magnitude > 0 then
                        local forwardHit = Workspace:Raycast(currentPos, tangentDir * 8, rayParams)
                        if forwardHit then
                            -- Obstacle ahead! Abandon current target and pick a new clear path
                            currentTarget = getClearPointOnSphere(currentPos, planetPos, radius, rayParams)
                        end
                    end
                end
            end
            
            -- Recalculate direction in case target was updated
            rawDir = (currentTarget - currentPos)
            dot = rawDir:Dot(upNormal)
            tangentDir = (rawDir - dot * upNormal).Unit
            
            -- Advance step towards target
            local stepPos = currentPos + (tangentDir * humanoid.WalkSpeed * 0.05)
            
            -- Constrain to spherical shell using static distance
            stepPos = planetPos + ((stepPos - planetPos).Unit * spawnRadius)
            alignPosition.Position = stepPos
            
            -- Update orientation to face direction of travel, with upVector=upNormal
            if tangentDir.Magnitude > 0.01 then
                local lookCFrame = CFrame.lookAt(currentPos, currentPos + tangentDir, upNormal)
                alignOrientation.CFrame = lookCFrame
            end
            
            -- Send humanoid move command to trigger walking animation
            humanoid:Move(Vector3.new(0, 0, -1)) 
        end
    end)
    
    loadedModel:Destroy()
end

return NpcManager
