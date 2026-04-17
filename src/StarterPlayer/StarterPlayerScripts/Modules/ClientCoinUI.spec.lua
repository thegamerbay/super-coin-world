--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientCoinUI = require(script.Parent.ClientCoinUI)
local Players = game:GetService("Players")

return function()
    describe("ClientCoinUI", function()
        beforeEach(function()
            ClientCoinUI._reset()
        end)

        afterEach(function()
            ClientCoinUI._reset()
        end)

        it("should initialize the UI correctly", function()
            ClientCoinUI.init()
            local container = ClientCoinUI._getContainer()
            expect(container).to.be.ok()
            
            -- Verify hierarchy and positioning
            expect(container.Name).to.equal("Container")
            expect(container.Parent).to.be.ok()
            expect(container.Parent.Name).to.equal("CoinCounterUI")
            expect(container.Parent:IsA("ScreenGui")).to.equal(true)
            
            -- Specifically placed at Top Center
            expect(container.AnchorPoint.X).to.equal(0.5)
            expect(container.Position.Y.Offset).to.equal(10)
            
            local valueLabel = container:FindFirstChild("Value")
            expect(valueLabel).to.be.ok()
            expect(valueLabel.Text).to.equal("0")
        end)

        it("should update the text safely", function()
            ClientCoinUI.init()
            local container = ClientCoinUI._getContainer()
            local valueLabel = container:FindFirstChild("Value") :: TextLabel
            
            ClientCoinUI.updateCoins(42)
            expect(valueLabel.Text).to.equal("42")
        end)
        
        it("should auto-initialize if updateCoins is called before init", function()
            ClientCoinUI.updateCoins(100)
            local container = ClientCoinUI._getContainer()
            expect(container).to.be.ok()
            
            local valueLabel = container:FindFirstChild("Value") :: TextLabel
            expect(valueLabel.Text).to.equal("100")
        end)
    end)
end
