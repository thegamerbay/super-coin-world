--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedPackages = ReplicatedStorage.SharedPackages
local CharacterAnimate = require(SharedPackages.CharacterAnimate)

local animate = script.Parent
local character = animate.Parent
local performer = character:WaitForChild("Humanoid")

local module = {}
local controller

function module.matchAnimate(director: Humanoid)
	if controller then
		controller.cleanup()
	end

	controller = CharacterAnimate.animate(animate, director, performer)
end

animate:WaitForChild("PlayEmote").OnInvoke = function(emote)
	return controller.playEmote(emote)
end

module.matchAnimate(performer)

return module
