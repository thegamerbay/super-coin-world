--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedPackages = ReplicatedStorage.SharedPackages
local CharacterSounds = require(SharedPackages.CharacterSounds)

local module = {}

-- Private

type PlayerState = {
	performer: Model?,
	terminateSound: (() -> ())?,
	connections: { RBXScriptConnection },
}

local playerStates: { [Player]: PlayerState } = {}

local function terminateSound(player: Player)
	local state = playerStates[player]
	if state and state.terminateSound then
		state.terminateSound()
		state.terminateSound = nil
	end
end

local function characterRemoving(player: Player, _character: Model)
	terminateSound(player)
end

local function characterAdded(player: Player, character: Model)
	characterRemoving(player, character)

	local state = playerStates[player]
	if state then
		local performer = state.performer or character
		local controller = CharacterSounds.listen(performer, character)

		state.terminateSound = controller.cleanup
	end
end

local function playerRemoving(player: Player)
	terminateSound(player)

	local state = playerStates[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
	end

	playerStates[player] = nil
end

local function playerAdded(player: Player)
	playerRemoving(player)

	local state = {
		performer = nil,
		connections = {},
		terminateSound = nil,
	}

	if player.Character then
		characterAdded(player, player.Character)
	end

	table.insert(
		state.connections,
		player.CharacterAdded:Connect(function(character)
			characterAdded(player, character)
		end)
	)

	table.insert(
		state.connections,
		player.CharacterRemoving:Connect(function(character)
			characterRemoving(player, character)
		end)
	)

	playerStates[player] = state
end

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

-- Public

function module.setPerformer(player: Player, performer: Model?)
	local state = playerStates[player]
	if state then
		state.performer = performer

		local character = player.Character
		if character then
			characterAdded(player, character)
		end
	end
end

--

return module
