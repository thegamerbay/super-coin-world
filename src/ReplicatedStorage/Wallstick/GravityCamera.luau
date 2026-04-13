--!strict

--[=[
	@class GravityCamera

	This module acts as a typed interface for client-sided control of the modifications made to the camera controller.
]=]

local Players = game:GetService("Players")

-- stylua: ignore
local playerModuleObject = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")) :: any
local cameraModuleObject = playerModuleObject:GetCameras() :: any
local controlModuleObject = playerModuleObject:GetControls() :: any

local GravityCamera = {}

function GravityCamera.getUpVector(): Vector3
	return cameraModuleObject:GetUpVector()
end

function GravityCamera.setUpVector(target: Vector3)
	cameraModuleObject:SetTargetUpVector(target)
end

function GravityCamera.getSpinPart(): BasePart
	return cameraModuleObject:GetSpinPart()
end

function GravityCamera.setSpinPart(part: BasePart)
	cameraModuleObject:SetSpinPart(part)
end

function GravityCamera.getRotationType(): Enum.RotationType
	return cameraModuleObject:GetRotationType()
end

function GravityCamera.getMoveVector(cameraCF: CFrame, inputMove: Vector3?): Vector3
	local move = inputMove or controlModuleObject:GetMoveVector() :: Vector3
	local _, _, _, r00, r01, r02, _, r11, r12, _, _, r22 = cameraCF:GetComponents()

	local c, s
	local q = math.sign(r11)

	if r12 < 1 and r12 > -1 then
		c = r22
		s = r02
	else
		c = r00
		s = -r01 * math.sign(r12)
	end

	local norm = math.sqrt(c * c + s * s)
	local x = (c * move.X * q + s * move.Z) / norm
	local z = (c * move.Z - s * move.X * q) / norm

	return Vector3.new(x, 0, z)
end

return GravityCamera
