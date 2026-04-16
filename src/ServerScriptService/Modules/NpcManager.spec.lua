-- selene:allow(undefined_variable)
return function()
    local NpcManager = require(script.Parent.NpcManager)
    local Workspace = game:GetService("Workspace")

    describe("NpcManager.spawnNpc", function()
        it("should gracefully handle an invalid asset id without crashing the thread", function()
            local dummyPlanet = Instance.new("Part")
            dummyPlanet.Size = Vector3.new(20, 20, 20)
            
            -- This should fail to load but safely return without throwing an unhandled Lua error
            expect(function()
                NpcManager.spawnNpc(dummyPlanet, -12345, 10, "FailNPC")
            end).never.to.throw()
            
            dummyPlanet:Destroy()
        end)
        
        it("should spawn a valid standard NPC, apply spherical constraints, and clean it up", function()
            local dummyPlanet = Instance.new("Part")
            dummyPlanet.Size = Vector3.new(50, 50, 50)
            dummyPlanet.Position = Vector3.new(1000, 1000, 1000)
            
            -- Keep track of all NPCs to know what is newly spawned
            local existingModels = {}
            for _, child in pairs(Workspace:GetChildren()) do
                if child.Name == "TestZombie" then
                    existingModels[child] = true
                end
            end
            
            -- 187789986 is the Drooling Zombie
            expect(function()
                NpcManager.spawnNpc(dummyPlanet, 187789986, 12, "TestZombie")
            end).never.to.throw()
            
            -- Verify it appeared in Workspace
            local spawnedZombie = nil
            for _, child in pairs(Workspace:GetChildren()) do
                if child.Name == "TestZombie" and not existingModels[child] then
                    spawnedZombie = child
                    break
                end
            end
            
            -- If it failed to load due to network, we can't assert on physical logic
            if spawnedZombie then
                local rootPart = spawnedZombie:FindFirstChild("HumanoidRootPart") or spawnedZombie:FindFirstChild("Torso")
                expect(rootPart).to.be.ok()
                
                -- Verify gravity constraints were successfully injected
                local alignPos = rootPart:FindFirstChildWhichIsA("AlignPosition")
                local alignOri = rootPart:FindFirstChildWhichIsA("AlignOrientation")
                
                expect(alignPos).to.be.ok()
                expect(alignOri).to.be.ok()
                expect(alignPos.Mode).to.equal(Enum.PositionAlignmentMode.OneAttachment)
                
                -- Verify WalkSpeed
                local humanoid = spawnedZombie:FindFirstChildWhichIsA("Humanoid")
                expect(humanoid).to.be.ok()
                expect(humanoid.WalkSpeed).to.equal(12)
                
                -- Clean up
                spawnedZombie:Destroy()
            end
            
            dummyPlanet:Destroy()
        end)

        it("should successfully trigger Master Rig Construction for an old override model", function()
            local dummyPlanet = Instance.new("Part")
            dummyPlanet.Size = Vector3.new(50, 50, 50)
            dummyPlanet.Position = Vector3.new(2000, 2000, 2000)
            
            -- Noob ID: 27387485, Zombie ID: 187789986
            expect(function()
                NpcManager.spawnNpc(dummyPlanet, 27387485, 24, "TestNoob", 187789986)
            end).never.to.throw()
            
            -- Verify it appeared in Workspace
            local spawnedNoob = nil
            for _, child in pairs(Workspace:GetChildren()) do
                if child.Name == "TestNoob" then
                    spawnedNoob = child
                    break
                end
            end
            
            if spawnedNoob then
                -- Master Rig construction should have built a HumanoidRootPart explicitly
                local hrp = spawnedNoob:FindFirstChild("HumanoidRootPart")
                expect(hrp).to.be.ok()
                
                -- Verify Rigging (Motor6Ds)
                local torso = spawnedNoob:FindFirstChild("Torso")
                expect(torso).to.be.ok()
                
                local rootJoint = hrp:FindFirstChild("RootJoint")
                expect(rootJoint).to.be.ok()
                expect(rootJoint:IsA("Motor6D")).to.equal(true)
                
                local rightShoulder = torso:FindFirstChild("Right Shoulder")
                expect(rightShoulder).to.be.ok()
                expect(rightShoulder:IsA("Motor6D")).to.equal(true)
                
                -- Clean up
                spawnedNoob:Destroy()
            end
            
            dummyPlanet:Destroy()
        end)
    end)
end
