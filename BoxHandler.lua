local BoxService = require(script.Parent:WaitForChild("BoxService"))
local CarrySpeed = require(script.Parent:WaitForChild("CarrySpeed"))
local plotsFolder = workspace:WaitForChild("Plots")

local function setupBox(box)
	local prompt = box:WaitForChild("ProximityPrompt")

	prompt.Triggered:Connect(function(player)
		if BoxService.Carrying[player] then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		prompt.Enabled = false

		box:SetAttribute("OnPallet", false)

		if not box.PrimaryPart then
			local center = box:FindFirstChild("Center", true)

			if not center or not center:IsA("BasePart") then
				warn(box.Name .. " has no valid Center part")
				prompt.Enabled = true
				return
			end

			box.PrimaryPart = center
		end

		for _, object in ipairs(box:GetDescendants()) do
			if object:IsA("BasePart") then
				object.Anchored = false
				object.CanCollide = false
				object.CanTouch = false
				object.CanQuery = false
				object.Massless = true
			end
		end

		box:PivotTo(hrp.CFrame * CFrame.new(0, 1.5, -3))

		local weld = Instance.new("WeldConstraint")
		weld.Name = "CarryWeld"
		weld.Part0 = box.PrimaryPart
		weld.Part1 = hrp
		weld.Parent = box.PrimaryPart

		BoxService.Carrying[player] = {
			Box = box,
			Weld = weld
		}

		CarrySpeed.Apply(player, true)
	end)
end

local function setupPlot(plot)
	local boxesFolder = plot:FindFirstChild("Boxes")
	if not boxesFolder then return end

	for _, box in ipairs(boxesFolder:GetChildren()) do
		setupBox(box)
	end

	boxesFolder.ChildAdded:Connect(function(box)
		setupBox(box)
	end)
end

for _, plot in ipairs(plotsFolder:GetChildren()) do
	setupPlot(plot)
end
