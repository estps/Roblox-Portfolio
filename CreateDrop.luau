local Players = game:GetService("Players")

local CRATE_INTERVAL = 10
local CRATE_AMMO = 3
local ARENA_HALF = 38

local crates = Instance.new("Folder")
crates.Name = "Crates"
crates.Parent = workspace

local function spawnCrate()
	local crate = Instance.new("Part")
	crate.Name = "AmmoCrate"
	crate.Size = Vector3.new(3, 3, 3)
	crate.Position = Vector3.new(
		math.random(-ARENA_HALF, ARENA_HALF),
		40,
		math.random(-ARENA_HALF, ARENA_HALF)
	)
	crate.Anchored = false
	crate.Material = Enum.Material.WoodPlanks
	crate.Color = Color3.fromRGB(150, 111, 51)
	crate.Parent = crates

	crate.Touched:Connect(function(hit)
		if crate:GetAttribute("Claimed") then
			return
		end
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		crate:SetAttribute("Claimed", true)
		player:SetAttribute("Ammo", (player:GetAttribute("Ammo") or 12) + CRATE_AMMO)
		crate:Destroy()
	end)

	task.delay(30, function()
		if crate.Parent then
			crate:Destroy()
		end
	end)
end

while true do
	spawnCrate()
	task.wait(CRATE_INTERVAL)
end
