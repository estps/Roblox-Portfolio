local CarrySpeed = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopService = require(script.Parent:WaitForChild("ShopService"))
local updateCarrySpeed = ReplicatedStorage:WaitForChild("UpdateCarrySpeed")

local originals = {}

function CarrySpeed.Apply(player, carrying)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if carrying then
		if not originals[player] then
			originals[player] = humanoid.WalkSpeed
		end

		humanoid.WalkSpeed = ShopService.GetCarrySpeed(player)
		updateCarrySpeed:FireClient(player, humanoid.WalkSpeed)
	else
		local original = originals[player]

		if original then
			humanoid.WalkSpeed = original
			originals[player] = nil
		end

		updateCarrySpeed:FireClient(player, humanoid.WalkSpeed)
	end
end

Players.PlayerRemoving:Connect(function(player)
	originals[player] = nil
end)

return CarrySpeed
