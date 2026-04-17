--!strict
local VehicleGravity = {}
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

export type VehicleData = {
    model: Model,
    parts: {BasePart},
    forces: {VectorForce},
    connection: RBXScriptConnection?
}

local activeVehicles: { [Model]: VehicleData } = {}

function VehicleGravity.setupVehicle(model: Model)
    local parts = {}
    local forces = {}

    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            local attachment = Instance.new("Attachment")
            attachment.Name = "GravityAttachment"
            attachment.Parent = desc

            local force = Instance.new("VectorForce")
            force.Attachment0 = attachment
            force.RelativeTo = Enum.ActuatorRelativeTo.World
            force.ApplyAtCenterOfMass = true
            force.Parent = desc

            table.insert(parts, desc)
            table.insert(forces, force)
        end
    end

    local flipTimer = 0

    local connection = RunService.Heartbeat:Connect(function(dt)
        if not model or not model.Parent then
            VehicleGravity.removeVehicle(model)
            return
        end

        local hrp = model.PrimaryPart or parts[1]
        if not hrp then return end

        local closestPlanet: BasePart? = nil
        local shortestDist = math.huge

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

        if closestPlanet then
            local planetDir = (closestPlanet.Position - hrp.Position).Unit
            local globalGravity = Workspace.Gravity

            -- 🔄 SPHERICAL ANTI-FLIP LOGIC
            local upVector = -planetDir
            local dot = hrp.CFrame.UpVector:Dot(upVector)
            
            -- If tilted > 60 degrees (dot < 0.5) and mostly stopped (so we don't interrupt active air stunts)
            if dot < 0.5 and hrp.AssemblyLinearVelocity.Magnitude < 2.5 then
                flipTimer += dt
                if flipTimer > 2.0 then
                    -- Unflip teleport towards the current planet
                    local currentLook = hrp.CFrame.LookVector
                    local right = currentLook:Cross(upVector)
                    
                    if right.Magnitude < 0.01 then
                        right = hrp.CFrame.RightVector
                    end
                    
                    local newLook = upVector:Cross(right).Unit
                    local newCFrame = CFrame.lookAt(hrp.Position, hrp.Position + newLook, upVector)
                    
                    model:PivotTo(newCFrame + upVector * 3) -- Lift slightly to prevent ground clipping
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    flipTimer = 0
                end
            else
                flipTimer = 0
            end

            for i, part in ipairs(parts) do
                local mass = part:GetMass()
                -- Lower values (like 0.2) reduce friction and create a fun "drifting" or slippery effect.
                -- WARNING: High multipliers (> 1.0) compress the car's suspension springs to their limits, 
                -- causing the physics engine to violently repel the car into the air.
                local GRAVITY_MULTIPLIER = 0.2
                
                -- Cancel global gravity (pulling down) by pushing up
                local cancelGravity = Vector3.new(0, globalGravity, 0)
                -- Apply custom gravity towards planet
                local sphericalGravity = planetDir * (globalGravity * GRAVITY_MULTIPLIER)
                
                forces[i].Force = mass * (cancelGravity + sphericalGravity)
            end
        end
    end)

    activeVehicles[model] = {
        model = model,
        parts = parts,
        forces = forces,
        connection = connection
    }
end

function VehicleGravity.removeVehicle(model: Model)
    local data = activeVehicles[model]
    if data then
        if data.connection then
            data.connection:Disconnect()
        end
        activeVehicles[model] = nil
    end
end

return VehicleGravity
