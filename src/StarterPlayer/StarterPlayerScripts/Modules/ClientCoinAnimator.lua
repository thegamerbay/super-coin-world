--!strict
local ClientCoinAnimator = {}
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

ClientCoinAnimator.activeCoins = {}

-- Create a visual dummy for a given coin hitbox
function ClientCoinAnimator.onCoinAdded(coin: BasePart)
    if not coin:IsA("BasePart") then return end
    -- CRITICAL FIX: EgoMoose's Wallstick system creates proxy clones of objects for gravity physics.
    -- These clones inherit the "AnimatedCoin" CollectionService tag! 
    -- We MUST ignore the Wallstick clones to prevent creating a second "ghost" spinning coin.
    local wallstickFolder = Workspace:FindFirstChild("Wallstick")
    if wallstickFolder and coin:IsDescendantOf(wallstickFolder) then return end
    if coin.Parent ~= Workspace then return end

    if ClientCoinAnimator.activeCoins[coin] then return end -- Prevent duplicates

    -- Use attributes for original visual size (fallback to coin.Size if original is missing)
    local thickness = coin:GetAttribute("VisualThickness") or coin.Size.X
    local diameter = coin:GetAttribute("VisualDiameter") or coin.Size.Y
    local targetSize = Vector3.new(thickness, diameter, diameter)

    -- Generate purely visual replica
    local clone = Instance.new("Part")
    clone.Name = "Visual" .. coin.Name
    clone.Shape = coin.Shape
    clone.Size = Vector3.new(0.01, 0.01, 0.01) -- Start near zero
    clone.Color = coin.Color -- Copied exact precise RGB color

    clone.Material = coin.Material
    clone.Anchored = true
    clone.CanCollide = false
    clone.CastShadow = false -- Optimization
    clone.Position = coin.Position
    clone.Parent = Workspace
    
    -- Ensure the server coin hitbox is completely invisible locally
    coin.Transparency = 1

    ClientCoinAnimator.activeCoins[coin] = {
        part = clone,
        baseCFrame = coin.CFrame, -- Store the original orientation relative to the planet
        timePassed = 0,
        targetSize = targetSize
    }
end

-- Destroy the visual dummy when the server removes the hitbox
function ClientCoinAnimator.onCoinRemoved(coin: BasePart)
    local data = ClientCoinAnimator.activeCoins[coin]
    if data then
        if data.part then
            data.part:Destroy()
        end
        ClientCoinAnimator.activeCoins[coin] = nil
    end
end

-- Animate all visual dummies every frame
function ClientCoinAnimator.onRenderStepped(deltaTime: number)
    for _, data in pairs(ClientCoinAnimator.activeCoins) do
        data.timePassed += deltaTime
        
        -- Manual size animation to prevent engine visual tearing
        if data.timePassed < 0.5 then
            local alpha = TweenService:GetValue(data.timePassed / 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            data.part.Size = Vector3.new(0.01, 0.01, 0.01):Lerp(data.targetSize, alpha)
        elseif data.part.Size ~= data.targetSize then
            data.part.Size = data.targetSize
        end
        
        -- Rotation around the local Y axis
        local rotation = CFrame.Angles(0, math.rad(100) * data.timePassed, 0)
        
        -- Hovering (offset along the local Y axis via CFrame)
        local hoverOffset = CFrame.new(0, math.sin(data.timePassed * 3) * 0.5, 0)
        
        -- Apply offset and rotation to the coin's base CFrame
        if data.part and data.part.Parent then
            data.part.CFrame = data.baseCFrame * hoverOffset * rotation
        end
    end
end

function ClientCoinAnimator.init()
    if ClientCoinAnimator.isInitialized then return {} end
    ClientCoinAnimator.isInitialized = true

    local connections = {}

    -- Animate all visual dummies every frame
    table.insert(connections, RunService.RenderStepped:Connect(ClientCoinAnimator.onRenderStepped))

    -- Monitor the CollectionService for existing and new coins
    table.insert(connections, CollectionService:GetInstanceAddedSignal("AnimatedCoin"):Connect(function(instance)
        ClientCoinAnimator.onCoinAdded(instance :: BasePart)
    end))

    table.insert(connections, CollectionService:GetInstanceRemovedSignal("AnimatedCoin"):Connect(function(instance)
        ClientCoinAnimator.onCoinRemoved(instance :: BasePart)
    end))

    -- Catch any coins that might have spawned before this specific script ran
    for _, instance in pairs(CollectionService:GetTagged("AnimatedCoin")) do
        ClientCoinAnimator.onCoinAdded(instance :: BasePart)
    end

    return connections
end

return ClientCoinAnimator
