--!strict
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local TRACK_LIST = {
    "rbxassetid://127101042421527",  -- The Unspooling
    "rbxassetid://74079001171026",   -- Beneath The Canopy
    "rbxassetid://140569894436239",  -- Wooden Path at Low Tide
    "rbxassetid://130795024593881",  -- Among The Stratus Isles
    "rbxassetid://132551074585454",  -- Beneath The Winter Boughs
    "rbxassetid://104518893185196",  -- Found by The Dripping Well
    "rbxassetid://131007752735335",  -- Above The Timberline
    "rbxassetid://90123960516963",   -- Marshmallow Sprint
    "rbxassetid://88394781409730",   -- Twelve Turns of The Key
    "rbxassetid://136930306279725",  -- The Copper Leaf Parade
    "rbxassetid://90823583619433",   -- Beneath The Woolly Tides
    "rbxassetid://139558261935474",  -- Beneath The Starry Loom
    "rbxassetid://84051935700286",   -- Above The Molten Flow
    "rbxassetid://108076345214227",  -- Velvet Dune Ascent
}

local currentTrackIndex = 1
local rng = Random.new()

-- Shuffle tracks
for i = #TRACK_LIST, 2, -1 do
    local j = rng:NextInteger(1, i)
    TRACK_LIST[i], TRACK_LIST[j] = TRACK_LIST[j], TRACK_LIST[i]
end

local musicPlayer = Instance.new("Sound")
musicPlayer.Name = "BackgroundMusic"
musicPlayer.Volume = 0.3
musicPlayer.Parent = SoundService

local function playNextTrack()
    local nextId = TRACK_LIST[currentTrackIndex]
    musicPlayer.SoundId = nextId

    -- Preload heavy/long tracks before playback
    if not musicPlayer.IsLoaded then
        ContentProvider:PreloadAsync({musicPlayer})
    end

    musicPlayer:Play()

    currentTrackIndex += 1
    if currentTrackIndex > #TRACK_LIST then
        currentTrackIndex = 1
    end
end

musicPlayer.Ended:Connect(playNextTrack)
playNextTrack()
