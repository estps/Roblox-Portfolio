local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoxService = require(script.Parent:WaitForChild("BoxService"))
local OrderService = require(script.Parent:WaitForChild("OrderService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local DeliverService = require(script.Parent:WaitForChild("DeliverService"))

local CarrySpeed = require(script.Parent:WaitForChild("CarrySpeed"))

local plotsFolder = workspace:WaitForChild("Plots")

local function setupPrompt(prompt, shelfName, plot)
	prompt.Triggered:Connect(function(player)
		if PlotService.GetPlot(player) ~= plot then
			return
		end

		local carriedData = BoxService.Carrying[player]

		if not carriedData then
			return
		end

		local box = carriedData.Box
		local weld = carriedData.Weld

		if not box then
			return
		end

		local order = OrderService.GetOrder(player)

		if not order then
			return
		end

		if not order.Accepted then
			warn(player.Name .. " has not accepted the task")
			return
		end

		if order.Shelf ~= shelfName then
			warn(player.Name .. " delivered to the wrong shelf")
			return
		end

		if weld then
			weld:Destroy()
		end

		BoxService.Carrying[player] = nil
		CarrySpeed.Apply(player, false)

		DeliverService.TryDeliver(player, box)
	end)
end

for _, plot in ipairs(plotsFolder:GetChildren()) do
	local shelves = plot:FindFirstChild("DeliveryShelves")
	if not shelves then continue end

	for _, shelfName in ipairs({ "ShelfA", "ShelfB" }) do
		local shelf = shelves:FindFirstChild(shelfName)
		local sign = shelf and shelf:FindFirstChild("Sign")
		local prompt = sign and sign:FindFirstChild("ShelfPrompt")

		if prompt then
			setupPrompt(prompt, shelfName == "ShelfA" and "A" or "B", plot)
		end
	end
end
