local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUDSync = ReplicatedStorage:WaitForChild("HUDSync")
local Pads = workspace:WaitForChild("SpawnPads")
local Arrows = workspace:WaitForChild("Arrows")

local INTERMISSION_TIME = 10
local ROUND_TIME = 120
local END_TIME = 6

local state = "Intermission"
local timeLeft = 0

local function leaderboard()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(list, {
			Name = player.Name,
			Kills = player:GetAttribute("Kills") or 0,
		})
	end
	table.sort(list, function(a, b)
		return a.Kills > b.Kills
	end)
	return list
end

local function sync()
	for _, player in ipairs(Players:GetPlayers()) do
		HUDSync:FireClient(player, {
			State = state,
			Time = timeLeft,
			Ammo = player:GetAttribute("Ammo") or 12,
			Board = leaderboard(),
		})
	end
end

local function startIntermission()
	local pads = Pads:GetChildren()
	for _, arrow in ipairs(Arrows:GetChildren()) do
		arrow:Destroy()
	end
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Kills", 0)
		player:SetAttribute("Ammo", 12)
		if #pads > 0 then
			local character = player.Character
			if character then
				character:PivotTo(pads[math.random(1, #pads)].CFrame * CFrame.new(0, 3, 0))
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = humanoid.MaxHealth
				end
			end
		end
	end
end

local function countdown(nextState, seconds)
	state = nextState
	timeLeft = seconds
	while timeLeft > 0 do
		sync()
		timeLeft = timeLeft - 1
		task.wait(1)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Kills", 0)
	player:SetAttribute("Ammo", 12)
end)

while true do
	startIntermission()
	countdown("Intermission", INTERMISSION_TIME)
	countdown("Round", ROUND_TIME)
	countdown("End", END_TIME)
end
