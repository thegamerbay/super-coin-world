--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ClientCoinUI = {}

local container: Frame? = nil
local valueTextLabel: TextLabel? = nil
local uiScale: UIScale? = nil

local isInitialized = false

function ClientCoinUI.init()
    if isInitialized then return end
    isInitialized = true

    local player = Players.LocalPlayer
    local playerGui
    if player then
        playerGui = player:WaitForChild("PlayerGui")
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CoinCounterUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if playerGui then
        screenGui.Parent = playerGui
    end

    -- Main Container Frame
    local newContainer = Instance.new("Frame")
    newContainer.Name = "Container"
    newContainer.Size = UDim2.new(0, 180, 0, 50)
    -- Positioned Top Center
    newContainer.Position = UDim2.new(0.5, 0, 0, 10)
    newContainer.AnchorPoint = Vector2.new(0.5, 0)
    newContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    newContainer.BackgroundTransparency = 0.3
    newContainer.Parent = screenGui

    -- Scale component for smooth pumping animation
    uiScale = Instance.new("UIScale")
    uiScale.Scale = 1
    uiScale.Parent = newContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = newContainer

    local backgroundStroke = Instance.new("UIStroke")
    backgroundStroke.Color = Color3.fromRGB(255, 215, 0)
    backgroundStroke.Transparency = 0.5
    backgroundStroke.Thickness = 2
    backgroundStroke.Parent = newContainer

    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    })
    uiGradient.Rotation = 90
    uiGradient.Parent = newContainer

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = newContainer

    -- Icon placeholder (Image or Emoji)
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 40, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "🟡" -- Universal gold coin/circle representation
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.GothamBlack
    iconLabel.LayoutOrder = 1
    iconLabel.Parent = newContainer

    local iconPadding = Instance.new("UIPadding")
    iconPadding.PaddingTop = UDim.new(0, 10)
    iconPadding.PaddingBottom = UDim.new(0, 10)
    iconPadding.Parent = iconLabel

    -- Value Text
    valueTextLabel = Instance.new("TextLabel")
    valueTextLabel.Name = "Value"
    valueTextLabel.Size = UDim2.new(0, 90, 1, 0)
    valueTextLabel.BackgroundTransparency = 1
    valueTextLabel.Text = "0"
    valueTextLabel.TextScaled = true
    valueTextLabel.Font = Enum.Font.FredokaOne
    valueTextLabel.TextColor3 = Color3.fromRGB(255, 235, 120) -- Bright Gold
    valueTextLabel.LayoutOrder = 2
    valueTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueTextLabel.Parent = newContainer

    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(80, 50, 0)
    textStroke.Thickness = 2
    textStroke.Parent = valueTextLabel

    local textPadding = Instance.new("UIPadding")
    textPadding.PaddingTop = UDim.new(0, 7)
    textPadding.PaddingBottom = UDim.new(0, 7)
    textPadding.Parent = valueTextLabel

    container = newContainer
end

function ClientCoinUI.updateCoins(amount: number)
    if not isInitialized then
        ClientCoinUI.init()
    end

    if valueTextLabel then
        valueTextLabel.Text = tostring(amount)
    end

    -- Play a pulse animation if uiScale exists
    if uiScale then
        -- Cancel any current tween implicitly by starting a new one
        local pumpTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local pumpTween = TweenService:Create(uiScale, pumpTweenInfo, {Scale = 1.15})
        
        local relaxTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
        local relaxTween = TweenService:Create(uiScale, relaxTweenInfo, {Scale = 1.0})

        pumpTween.Completed:Connect(function()
            relaxTween:Play()
        end)
        pumpTween:Play()
    end
end

-- Exported for testing purposes
function ClientCoinUI._getContainer()
    return container
end

function ClientCoinUI._reset()
    if container and container.Parent then
        container.Parent:Destroy() -- Destroys the ScreenGui
    end
    container = nil
    valueTextLabel = nil
    uiScale = nil
    isInitialized = false
end

return ClientCoinUI
