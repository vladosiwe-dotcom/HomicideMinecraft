-- Sandbox server: builds the test map, attaches an organism to every
-- character (players and dummies), runs the simulation and handles the
-- sandbox menu actions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local BodyMap = require(ReplicatedStorage.Shared.BodyMap)
local Organism = require(script.Parent.Organism)
local Ragdoll = require(script.Parent.Ragdoll)
local Weapons = require(script.Parent.Weapons)

--------------------------------------------------------------------------
-- Remotes
--------------------------------------------------------------------------

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function makeRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local fireRemote = makeRemote("Fire")
local reloadRemote = makeRemote("Reload")
local useRemote = makeRemote("UseItem")
local sandboxRemote = makeRemote("Sandbox")
local effectsRemote = makeRemote("Effects")
remotes.Parent = ReplicatedStorage

--------------------------------------------------------------------------
-- Test map
--------------------------------------------------------------------------

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function buildMap()
	if Workspace:FindFirstChild("SandboxMap") then
		return
	end
	local map = Instance.new("Folder")
	map.Name = "SandboxMap"

	if not Workspace:FindFirstChild("Baseplate") then
		makePart({
			Name = "Floor",
			Size = Vector3.new(400, 2, 400),
			Position = Vector3.new(0, -1, 0),
			Color = Color3.fromRGB(95, 100, 95),
			Material = Enum.Material.Concrete,
			Parent = map,
		})
	end

	if not Workspace:FindFirstChildOfClass("SpawnLocation") then
		local spawn = Instance.new("SpawnLocation")
		spawn.Anchored = true
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = Vector3.new(0, 0.5, 0)
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Parent = map
	end

	-- Towers with ladders to test fall damage: 12, 20, 35 and 60 studs.
	for index, height in { 12, 20, 35, 60 } do
		local x = -40 + index * 16
		makePart({
			Name = "Tower" .. height,
			Size = Vector3.new(8, height, 8),
			Position = Vector3.new(x, height / 2, 40),
			Color = Color3.fromRGB(120, 110, 100),
			Material = Enum.Material.Brick,
			Parent = map,
		})
		local truss = Instance.new("TrussPart")
		truss.Anchored = true
		truss.Size = Vector3.new(2, height, 2)
		truss.Position = Vector3.new(x, height / 2, 35)
		truss.Parent = map
	end

	-- Cover walls for gunfights.
	for index = 1, 6 do
		makePart({
			Name = "Cover",
			Size = Vector3.new(10, 6, 1.5),
			Position = Vector3.new(-50 + index * 15, 3, -30),
			Color = Color3.fromRGB(140, 140, 145),
			Material = Enum.Material.Concrete,
			Parent = map,
		})
	end

	map.Parent = Workspace
end

buildMap()

local dummiesFolder = Instance.new("Folder")
dummiesFolder.Name = "Dummies"
dummiesFolder.Parent = Workspace

--------------------------------------------------------------------------
-- Organisms
--------------------------------------------------------------------------

local organisms: { [Model]: any } = {}
local lastVerticalSpeed: { [Model]: number } = {}

local function setupHumanoid(humanoid: Humanoid)
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.UseJumpPower = true
	humanoid.MaxHealth = 100
	humanoid.Health = 100
end

local function register(model: Model)
	local humanoid = model:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	setupHumanoid(humanoid)
	organisms[model] = Organism.new()
	model:SetAttribute("Ragdolled", false)
	model:SetAttribute("WantsRagdoll", false)
end

local function onHit(model: Model, part: BasePart, damage: number, damageType: string, _position: Vector3)
	local org = organisms[model]
	if not org then
		return
	end
	local region = BodyMap.RegionForPart(part.Name)
	if not region then
		return
	end
	local injuries = org:ApplyHit(region, damage, damageType)
	model:SetAttribute("LastHit", BodyMap.RegionNames[region] .. (#injuries > 0 and (": " .. table.concat(injuries, ", ")) or ""))
end

local function onDeath(model: Model, org)
	Ragdoll.Enable(model)
	model:SetAttribute("Dead", true)
	model:SetAttribute("DeathCause", org.deathCause)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
	if model.Parent == dummiesFolder then
		Debris:AddItem(model, Config.Sandbox.DummyCorpseLifetime)
	end
	organisms[model] = nil
	lastVerticalSpeed[model] = nil
end

local function publish(model: Model, org)
	model:SetAttribute("Blood", math.floor(org.blood))
	model:SetAttribute("Bleed", math.floor(org.bleedRate * 10) / 10)
	model:SetAttribute("Pulse", math.floor(org.pulse))
	model:SetAttribute("O2", math.floor(org.o2))
	model:SetAttribute("Pain", math.floor(org.effectivePain))
	model:SetAttribute("Consciousness", math.floor(org.consciousness * 100) / 100)
	model:SetAttribute("Brain", math.floor(org.brain * 100) / 100)
	model:SetAttribute("Unconscious", org.unconscious)
	model:SetAttribute("HeartStopped", org.heartStopped)
	model:SetAttribute("Arterial", org:HasArterialWound())
	model:SetAttribute("Fractures", org:FractureList())
end

local function detectFall(model: Model, org)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local vy = root.AssemblyLinearVelocity.Y
	local previous = lastVerticalSpeed[model] or 0
	-- A fast fall that suddenly stops is a landing.
	if previous < -Config.Movement.FallDamageSpeed and vy > previous * 0.3 then
		local injuries = org:ApplyFall(-previous)
		if #injuries > 0 then
			model:SetAttribute("LastHit", "падение: " .. table.concat(injuries, ", "))
		end
	end
	lastVerticalSpeed[model] = vy
end

local function step(dt: number)
	for model, org in organisms do
		if model.Parent == nil then
			organisms[model] = nil
			lastVerticalSpeed[model] = nil
			continue
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end

		detectFall(model, org)
		org:Tick(dt)
		publish(model, org)

		if not org.alive then
			onDeath(model, org)
			continue
		end

		local wantsRagdoll = model:GetAttribute("WantsRagdoll") == true
		if (org.mustRagdoll or wantsRagdoll) and not Ragdoll.IsRagdolled(model) then
			Ragdoll.Enable(model)
		elseif not org.mustRagdoll and not wantsRagdoll and Ragdoll.IsRagdolled(model) then
			Ragdoll.Disable(model)
		end

		humanoid.WalkSpeed = Config.Movement.WalkSpeed * org:SpeedMultiplier()
		humanoid.JumpPower = org:CanJump() and Config.Movement.JumpPower or 0
	end
end

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	local tick = Config.Organism.TickRate
	while accumulator >= tick do
		accumulator -= tick
		step(tick)
	end
end)

--------------------------------------------------------------------------
-- Players
--------------------------------------------------------------------------

local function giveTool(player: Player, weaponId: string)
	local tool = Weapons.CreateTool(weaponId)
	if tool then
		tool.Parent = player:WaitForChild("Backpack")
	end
end

local function onCharacterAdded(player: Player, character: Model)
	register(character)
	for _, weaponId in Config.StarterLoadout do
		giveTool(player, weaponId)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

Players.PlayerRemoving:Connect(function(player)
	Weapons.Forget(player)
end)

--------------------------------------------------------------------------
-- Dummies
--------------------------------------------------------------------------

local function spawnDummy(player: Player)
	if #dummiesFolder:GetChildren() >= Config.Sandbox.MaxDummies then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local description = Instance.new("HumanoidDescription")
	local skin = Color3.fromRGB(205, 170, 140)
	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	description.TorsoColor = Color3.fromRGB(70, 90, 120)
	description.LeftLegColor = Color3.fromRGB(50, 50, 60)
	description.RightLegColor = Color3.fromRGB(50, 50, 60)

	local ok, dummy = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not dummy then
		warn("Could not create dummy:", dummy)
		return
	end

	dummy.Name = "Dummy"
	local position = root.Position + root.CFrame.LookVector * 8
	dummy:PivotTo(CFrame.lookAt(position, root.Position))
	dummy.Parent = dummiesFolder

	local dummyRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart?
	if dummyRoot then
		dummyRoot:SetNetworkOwner(nil)
	end
	register(dummy)
end

--------------------------------------------------------------------------
-- Remote handlers
--------------------------------------------------------------------------

fireRemote.OnServerEvent:Connect(function(player, weaponId, direction)
	if typeof(weaponId) ~= "string" or typeof(direction) ~= "Vector3" then
		return
	end
	local character = player.Character
	local org = character and organisms[character]
	if not org then
		return
	end
	Weapons.Fire(player, weaponId, direction, org:AimPenalty(), onHit, effectsRemote)
end)

reloadRemote.OnServerEvent:Connect(function(player)
	Weapons.Reload(player)
end)

useRemote.OnServerEvent:Connect(function(player, weaponId)
	if typeof(weaponId) ~= "string" then
		return
	end
	local character = player.Character
	local org = character and organisms[character]
	if not org then
		return
	end
	Weapons.UseMedical(player, weaponId, function(effect)
		return org:Treat(effect)
	end)
end)

sandboxRemote.OnServerEvent:Connect(function(player, action, argument)
	if typeof(action) ~= "string" then
		return
	end
	local character = player.Character

	if action == "Give" then
		if typeof(argument) == "string" and Config.Weapons[argument] then
			giveTool(player, argument)
		end
	elseif action == "SpawnDummy" then
		spawnDummy(player)
	elseif action == "ClearDummies" then
		dummiesFolder:ClearAllChildren()
	elseif action == "Heal" then
		local org = character and organisms[character]
		if org then
			org:Reset()
			character:SetAttribute("WantsRagdoll", false)
			Ragdoll.Disable(character)
		end
	elseif action == "ToggleRagdoll" then
		if character and organisms[character] then
			character:SetAttribute("WantsRagdoll", not character:GetAttribute("WantsRagdoll"))
		end
	end
end)
