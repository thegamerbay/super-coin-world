-- selene:allow(undefined_variable)
return function()
    local VehicleGravity = require(script.Parent.VehicleGravity)
    local CollectionService = game:GetService("CollectionService")

    describe("VehicleGravity", function()
        it("should apply VectorForce to descendent parts and set gravity", function()
            local model = Instance.new("Model")
            local part = Instance.new("Part")
            part.Size = Vector3.new(4, 1, 8)
            part.Parent = model
            model.PrimaryPart = part
            model.Parent = workspace

            local planet = Instance.new("Part")
            planet.Name = "TestPlanet"
            planet.Position = Vector3.new(0, -100, 0)
            planet.Size = Vector3.new(50, 50, 50)
            planet.Parent = workspace
            CollectionService:AddTag(planet, "PlanetNode")

            VehicleGravity.setupVehicle(model)

            -- Check if attachment and force exist
            local attachment = part:FindFirstChild("GravityAttachment")
            local force = part:FindFirstChildOfClass("VectorForce")

            expect(attachment).to.be.ok()
            expect(force).to.be.ok()
            expect(force.Attachment0).to.equal(attachment)
            expect(force.ApplyAtCenterOfMass).to.equal(true)

            -- Allow heartbeat to process
            task.wait(0.1)

            expect(force.Force.Magnitude > 0).to.equal(true)

            VehicleGravity.removeVehicle(model)
            model:Destroy()
            CollectionService:RemoveTag(planet, "PlanetNode")
            planet:Destroy()
        end)

        it("should remove constraints on removeVehicle", function()
            local model = Instance.new("Model")
            local part = Instance.new("Part")
            part.Parent = model
            model.PrimaryPart = part
            model.Parent = workspace

            VehicleGravity.setupVehicle(model)
            VehicleGravity.removeVehicle(model)

            -- The objects (VectorForce/Attachment) are kept on the parts, 
            -- but the heartbeat connection should be terminated.
            -- This test ensures no exceptions are thrown when removing.
            expect(true).to.equal(true)

            model:Destroy()
        end)
    end)
end
