local ServerStorage = game:GetService("ServerStorage")
local PlotService = require(script.Parent:WaitForChild("PlotService"))

local templates = ServerStorage:WaitForChild("BoxTemplates")
local plotsFolder = workspace:WaitForChild("Plots")

local CHANGE_TIME = 5
local START_DELAY_BETWEEN_CRATES = 1

local boxChances = {
	{ Name = "RedBox", Chance = 40 },
	{ Name = "BlueBox", Chance = 30 },
	{ Name = "GreenBox", Chance = 15 },
	{ Name = "PurpleBox", Chance = 10 },
	{ Name = "GoldBox", Chance = 5 }
}

local function chooseRandomBox(previousName)
	local chosenName

	repeat
		local roll = math.random(1, 100)
		local runningTotal = 0

		for _, boxData in ipairs(boxChances) do
			runningTotal += boxData.Chance

			if roll <= runningTotal then
				chosenName = boxData.Name
				break
			end
		end
	until chosenName and chosenName ~= previousName

	return chosenName
end

local function makeBox(boxesFolder, spawnPoint, previousName)
	local boxName = chooseRandomBox(previousName)
	local template = templates:FindFirstChild(boxName)

	if not template then
		warn("Missing box template: " .. boxName)
		return nil, nil
	end

	local newBox = template:Clone()
	newBox.Parent = boxesFolder

	if not newBox.PrimaryPart then
		local center = newBox:FindFirstChild("Center", true)

		if not center or not center:IsA("BasePart") then
			warn(newBox.Name .. " has no valid Center part")
			newBox:Destroy()
			return nil, nil
		end

		newBox.PrimaryPart = center
	end

	newBox:SetAttribute("OnPallet", true)

	newBox:PivotTo(spawnPoint.CFrame)

	return newBox, boxName
end

local function runSpawnPoint(boxesFolder, spawnPoint, startingDelay)
	task.wait(startingDelay)

	local previousName = nil

	while true do
		local box, boxName = makeBox(boxesFolder, spawnPoint, previousName)

		if box then
			previousName = boxName

			task.wait(CHANGE_TIME)

			if box.Parent and box:GetAttribute("OnPallet") == true then
				box:Destroy()
			end
		else
			task.wait(1)
		end
	end
end

local function findSpawnPoints(palletsFolder)
	local spawnPoints = {}

	for _, pallet in ipairs(palletsFolder:GetChildren()) do
		for _, object in ipairs(pallet:GetDescendants()) do
			if object:IsA("BasePart")
				and string.match(object.Name, "^BoxSpawn%d+$") then

				table.insert(spawnPoints, object)
			end
		end
	end

	table.sort(spawnPoints, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	return spawnPoints
end

task.wait(1)

for _, plot in ipairs(plotsFolder:GetChildren()) do
	local palletsFolder = plot:FindFirstChild("Pallets")
	local boxesFolder = plot:FindFirstChild("Boxes")
	if not palletsFolder or not boxesFolder then continue end

	local spawnPoints = findSpawnPoints(palletsFolder)

	if #spawnPoints > 0 then
		for index, spawnPoint in ipairs(spawnPoints) do
			local startingDelay = (index - 1) * START_DELAY_BETWEEN_CRATES

			task.spawn(function()
				runSpawnPoint(boxesFolder, spawnPoint, startingDelay)
			end)
		end
	end
end
