--!strict
local MusicPlayer = {}
local SoundService = game:GetService("SoundService")

MusicPlayer.TRACK_LIST = {
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

function MusicPlayer.init()
    MusicPlayer.currentTrackIndex = 1
    
    local musicPlayer = Instance.new("Sound")
    musicPlayer.Name = "BackgroundMusic"
    musicPlayer.Volume = 0.3
    musicPlayer.Parent = SoundService
    
    MusicPlayer.sound = musicPlayer
    
    MusicPlayer.connection = musicPlayer.Ended:Connect(function()
        MusicPlayer.playNextTrack()
    end)
    
    MusicPlayer.playNextTrack()
end

function MusicPlayer.playNextTrack()
    if not MusicPlayer.sound then return end
    
    MusicPlayer.sound.SoundId = MusicPlayer.TRACK_LIST[MusicPlayer.currentTrackIndex]
    MusicPlayer.sound:Play()
    
    MusicPlayer.currentTrackIndex += 1
    if MusicPlayer.currentTrackIndex > #(MusicPlayer.TRACK_LIST) then
        MusicPlayer.currentTrackIndex = 1
    end
end

return MusicPlayer
