local Players = game:GetService("Players")
local PlotService = require(script.Parent:WaitForChild("PlotService"))

local function moveToPlotSpawn(player, plot)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local spawn = plot:FindFirstChild("PlayerSpawn")
	if not hrp or not spawn then return end

	hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
end

Players.PlayerAdded:Connect(function(player)
	local plot = PlotService.Assign(player)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		local assigned = PlotService.GetPlot(player) or plot
		if assigned then
			moveToPlotSpawn(player, assigned)
		end
	end)
end)
