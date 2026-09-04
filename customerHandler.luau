local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OrderService = require(script.Parent:WaitForChild("OrderService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))

local updateOrderGui = ReplicatedStorage:WaitForChild("UpdateOrderGui")
local customerOrderCompleted =
	script.Parent:WaitForChild("CustomerOrderCompleted")

local customerTemplate =
	ServerStorage:WaitForChild("CustomerTemplate")

local activeCustomers = {}

local displayNames = {
	RedBox = "Red Boxes",
	BlueBox = "Blue Boxes",
	GreenBox = "Green Boxes",
	PurpleBox = "Purple Boxes",
	GoldBox = "Gold Boxes"
}

local function getDialogueLabel(customer)
	local head = customer:FindFirstChild("Head")
	if not head then
		return nil
	end

	local dialogueGui = head:FindFirstChild("CustomerDialogue")
	if not dialogueGui then
		return nil
	end

	return dialogueGui:FindFirstChild("DialogueLabel")
end

local function removeCustomer(player)
	local customer = activeCustomers[player]

	if customer then
		customer:Destroy()
	end

	activeCustomers[player] = nil
end

local function getCustomerSpawn(player)
	local plot = PlotService.GetPlot(player)
	if not plot then return nil end
	return plot:FindFirstChild("CustomerSpawn")
end

local function spawnCustomer(player)
	removeCustomer(player)

	local order = OrderService.GetOrder(player)

	if not order then
		order = OrderService.CreateOrder(player)
	end

	local customerSpawn = getCustomerSpawn(player)

	if not customerSpawn then
		return
	end

	local customer = customerTemplate:Clone()
	customer.Name = "Customer_" .. player.Name
	customer.Parent = workspace
	customer:PivotTo(customerSpawn.CFrame)

	activeCustomers[player] = customer

	local rootPart = customer:FindFirstChild("HumanoidRootPart")
	local head = customer:FindFirstChild("Head")

	if not rootPart or not head then
		warn("CustomerTemplate needs a HumanoidRootPart and Head")
		removeCustomer(player)
		return
	end

	rootPart.Anchored = true

	local acceptPrompt = Instance.new("ProximityPrompt")
	acceptPrompt.Name = "AcceptOrderPrompt"
	acceptPrompt.ActionText = "Accept Task"
	acceptPrompt.ObjectText = "Customer"
	acceptPrompt.KeyboardKeyCode = Enum.KeyCode.E
	acceptPrompt.HoldDuration = 0
	acceptPrompt.MaxActivationDistance = 15
	acceptPrompt.RequiresLineOfSight = false
	acceptPrompt.Parent = head

	local cancelPrompt = Instance.new("ProximityPrompt")
	cancelPrompt.Name = "CancelOrderPrompt"
	cancelPrompt.ActionText = "Cancel Task"
	cancelPrompt.ObjectText = "Customer"
	cancelPrompt.KeyboardKeyCode = Enum.KeyCode.R
	cancelPrompt.HoldDuration = 0
	cancelPrompt.MaxActivationDistance = 15
	cancelPrompt.RequiresLineOfSight = false
	cancelPrompt.Parent = head

	local dialogueLabel = getDialogueLabel(customer)
	local boxName = displayNames[order.BoxType] or order.BoxType

	if dialogueLabel then
		dialogueLabel.Text =
			"Hello!\nCan you get me "
			.. tostring(order.Needed)
			.. " "
			.. boxName
			.. "?"
	end

	acceptPrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player then
			return
		end

		local currentOrder = OrderService.GetOrder(player)

		if not currentOrder or currentOrder.Accepted then
			return
		end

		OrderService.AcceptOrder(player)

		acceptPrompt.Enabled = false
		cancelPrompt.Enabled = true

		if dialogueLabel then
			dialogueLabel.Text =
				"Great!\nPlease bring me "
				.. tostring(currentOrder.Needed)
				.. " "
				.. boxName
				.. " to Shelf "
				.. tostring(currentOrder.Shelf)
				.. "."
		end

		updateOrderGui:FireClient(
			player,
			currentOrder.BoxType,
			currentOrder.Delivered,
			currentOrder.Needed,
			currentOrder.Shelf
		)

		print(player.Name .. " accepted the customer task")
	end)

	cancelPrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player then
			return
		end

		acceptPrompt.Enabled = false
		cancelPrompt.Enabled = false

		if dialogueLabel then
			dialogueLabel.Text = "No problem!\nI'll find another worker."
		end

		updateOrderGui:FireClient(player, "WAITING", 0, 0)

		task.wait(1)

		removeCustomer(player)

		OrderService.RemoveOrder(player)
		OrderService.CreateOrder(player)

		task.wait(1)

		spawnCustomer(player)

		print(player.Name .. " cancelled the customer task")
	end)
end

Players.PlayerAdded:Connect(function(player)
	if not OrderService.GetOrder(player) then
		OrderService.CreateOrder(player)
	end

	task.wait(1)
	spawnCustomer(player)

	updateOrderGui:FireClient(player, "WAITING", 0, 0)
end)

customerOrderCompleted.Event:Connect(function(player)
	local customer = activeCustomers[player]

	if customer then
		local dialogueLabel = getDialogueLabel(customer)

		if dialogueLabel then
			dialogueLabel.Text = "Perfect!\nThank you!"
		end

		task.wait(2)
	end

	removeCustomer(player)

	updateOrderGui:FireClient(player, "WAITING", 0, 0)

	task.wait(2)

	OrderService.RemoveOrder(player)
	OrderService.CreateOrder(player)
	spawnCustomer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	removeCustomer(player)
	OrderService.RemoveOrder(player)
	PlotService.Release(player)
end)
