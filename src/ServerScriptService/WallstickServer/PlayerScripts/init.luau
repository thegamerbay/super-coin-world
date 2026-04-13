--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local StarterCharacterScripts = StarterPlayer:WaitForChild("StarterCharacterScripts")

local ServerPackages = ServerScriptService.ServerPackages
local PlayerModulePackage = require(ServerPackages.PlayerModule)

local module = {}

local function replaceIfExists(parent: Instance, instance: Instance)
	local found = parent:FindFirstChild(instance.Name)
	if found then
		found:Destroy()
	end

	instance.Parent = parent
end

function module.setup()
	local patched = PlayerModulePackage.getCopy(true)
	local modifiers = require(patched:WaitForChild("Modifiers")) :: any
	modifiers.add(script.GravityCameraModifier)
	PlayerModulePackage.replace(patched)

	local renamedCharacterSounds = script.CharacterSounds:Clone()
	renamedCharacterSounds.Name = "RbxCharacterSounds"

	replaceIfExists(StarterCharacterScripts, script.Animate:Clone())
	replaceIfExists(StarterPlayerScripts, renamedCharacterSounds)
end

return module
