local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ArrowFire = ReplicatedStorage:WaitForChild("ArrowFire")
local Targets = workspace:WaitForChild("Targets")
local Template = ServerStorage:WaitForChild("TargetDummy")
local Arrows = workspace:WaitForChild("Arrows")

local GRAVITY = Vector3.new(0, -58, 0)
local BASE_SPEED = 95
local MAX_SPEED = 175

local active = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function creditKill(shooter)
	shooter:SetAttribute("Kills", (shooter:GetAttribute("Kills") or 0) + 1)
end

local function hitTarget(part, amount, shooter)
	local dummy = part.Parent
	local health = dummy:GetAttribute("Health")
	if health == nil then
		return
	end
	health = health - amount
	if health > 0 then
		dummy:SetAttribute("Health", health)
		return
	end
	if shooter then
		creditKill(shooter)
	end
	local spawnPos = dummy:GetAttribute("SpawnPos")
	dummy:Destroy()
	task.delay(3, function()
		local clone = Template:Clone()
		clone:SetAttribute("Health", 100)
		clone:SetAttribute("SpawnPos", spawnPos)
		clone:SetPrimaryPartCFrame(CFrame.new(spawnPos + Vector3.new(0, 3.5, 0)))
		clone.Parent = Targets
	end)
end

local function hitCharacter(part, amount, shooter)
	local character = part.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(amount)
		if humanoid.Health <= 0 then
			local victim = Players:GetPlayerFromCharacter(character)
			if shooter and victim and shooter ~= victim then
				creditKill(shooter)
			end
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	for index = #active, 1, -1 do
		local arrow = active[index]
		local start = arrow.Part.Position
		local velocity = arrow.Velocity
		local finish = start + velocity * dt
		local result = workspace:Raycast(start, finish - start, rayParams)
		if result then
			local hit = result.Instance
			arrow.Part.CFrame = CFrame.lookAt(result.Position, result.Position + velocity.Unit)
			if hit.Name == "Target" then
				hitTarget(hit, arrow.Damage, arrow.Shooter)
			else
				hitCharacter(hit, arrow.Damage, arrow.Shooter)
			end
			task.delay(8, function()
				arrow.Part:Destroy()
			end)
			table.remove(active, index)
		else
			arrow.Part.Position = finish
			arrow.Velocity = velocity + GRAVITY * dt
		end
	end
end)

local function solveVelocity(origin, target, speed)
	local delta = target - origin
	local dxz = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local dy = delta.Y
	local g = -GRAVITY.Y
	local a = 0.25 * g * g
	local b = dy * g - speed * speed
	local c = dxz * dxz + dy * dy
	local disc = b * b - 4 * a * c
	if disc < 0 then
		return (target - origin).Unit * speed
	end
	local t2 = (-b - math.sqrt(disc)) / (2 * a)
	if t2 <= 0 then
		t2 = (-b + math.sqrt(disc)) / (2 * a)
	end
	if t2 <= 0 then
		return (target - origin).Unit * speed
	end
	local t = math.sqrt(t2)
	return Vector3.new(delta.X / t, delta.Y / t + 0.5 * g * t, delta.Z / t)
end

ArrowFire.OnServerEvent:Connect(function(player, data)
	local character = player.Character
	if not character then
		return
	end
	if (player:GetAttribute("Ammo") or 0) <= 0 then
		return
	end
	local target = Vector3.new(data.Target.X, data.Target.Y, data.Target.Z)
	local charge = math.clamp(data.Charge or 0, 0, 1)
	local speed = BASE_SPEED + (MAX_SPEED - BASE_SPEED) * charge
	local tool = character:FindFirstChildOfClass("Tool")
	local origin = nil
	if tool then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			origin = handle.Position + handle.CFrame.UpVector * 1.9
		end
	end
	if not origin then
		origin = character.Head.Position
	end
	local velocity = solveVelocity(origin, target, speed)
	player:SetAttribute("Ammo", (player:GetAttribute("Ammo") or 0) - 1)
	local part = Instance.new("Part")
	part.Name = "Arrow"
	part.Size = Vector3.new(0.16, 0.16, 2.4)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Wood
	part.Color = Color3.fromRGB(226, 207, 170)
	part.CFrame = CFrame.lookAt(origin, origin + velocity.Unit)
	part.Parent = Arrows
	rayParams.FilterDescendantsInstances = { character, Arrows }
	table.insert(active, {
		Part = part,
		Velocity = velocity,
		Damage = 20 + 60 * charge,
		Shooter = player,
	})
end)
