-- Paste into Roblox Studio: View > Command Bar, then press Enter.
local function folder(parent, name) local f = parent:FindFirstChild(name) or Instance.new("Folder") f.Name = name f.Parent = parent return f end
local function put(parent, class, name, source) local old = parent:FindFirstChild(name) if old then old:Destroy() end local s = Instance.new(class) s.Name = name s.Source = source s.Parent = parent end
local SP = game:GetService("StarterPlayer")
put(folder(game:GetService("ReplicatedStorage"), "Shared"), "ModuleScript", "Config", [==[-- Shared tuning values. Numbers for blood and consciousness follow Z-City's
-- organism system (lua/homigrad/organism), simplified for Roblox.

local Config = {}

Config.Blood = {
	Max = 5000, -- ml, same as Z-City
	RagdollAt = 2700, -- below this the body can no longer stand
	FaintAt = 2400, -- below this you pass out (raised by adrenaline)
	CriticalAt = 1500, -- below this the heart starts failing
}

Config.Organism = {
	TickRate = 0.1, -- seconds between simulation steps
	BasePulse = 70,
	WakeDelay = 6, -- seconds conditions must stay clear before waking up
	O2DropPerSecond = 8,
	O2RegenPerSecond = 12,
	BrainDamagePerSecond = 0.035, -- while oxygen is below 10
	PainDecayPerSecond = 1.2,
	PainkillerDecayPerSecond = 0.5,
	AdrenalineDecayPerSecond = 0.05,
	WoundClotPerSecond = 0.015, -- share of a normal wound's bleeding that stops each second
	ArterialBleed = 22, -- ml/s, arteries never clot on their own
	InternalBleedDivisor = 14, -- internal bleed pool / 14 = ml per second, as in Z-City
	InternalBleedHealPerSecond = 0.2,
	BloodRegenPerSecond = 0.5, -- only when not bleeding
}

Config.Movement = {
	WalkSpeed = 16,
	JumpPower = 50,
	FallDamageSpeed = 80, -- studs/s of downward speed before landing hurts (about a 16 stud drop)
}

-- Kind: "gun", "melee" or "medical".
-- DamageType: "bullet", "slash" or "blunt".
-- Spread is in degrees.
Config.Weapons = {
	Pistol = {
		Kind = "gun",
		DisplayName = "Пистолет",
		DamageType = "bullet",
		Damage = 32,
		FireRate = 0.18,
		Auto = false,
		MagSize = 15,
		Pellets = 1,
		Spread = 0.6,
		Range = 500,
		ReloadTime = 1.6,
		Size = Vector3.new(0.3, 0.9, 1.4),
		Color = Color3.fromRGB(35, 35, 35),
	},
	Rifle = {
		Kind = "gun",
		DisplayName = "Автомат",
		DamageType = "bullet",
		Damage = 38,
		FireRate = 0.1,
		Auto = true,
		MagSize = 30,
		Pellets = 1,
		Spread = 1.2,
		Range = 800,
		ReloadTime = 2.4,
		Size = Vector3.new(0.3, 0.7, 3.2),
		Color = Color3.fromRGB(60, 55, 45),
	},
	Shotgun = {
		Kind = "gun",
		DisplayName = "Дробовик",
		DamageType = "bullet",
		Damage = 14,
		FireRate = 0.85,
		Auto = false,
		MagSize = 6,
		Pellets = 8,
		Spread = 5,
		Range = 150,
		ReloadTime = 3,
		Size = Vector3.new(0.35, 0.6, 3.6),
		Color = Color3.fromRGB(90, 60, 35),
	},
	Knife = {
		Kind = "melee",
		DisplayName = "Нож",
		DamageType = "slash",
		Damage = 28,
		FireRate = 0.45,
		Range = 6,
		Size = Vector3.new(0.15, 0.3, 1.6),
		Color = Color3.fromRGB(170, 170, 175),
	},
	Bat = {
		Kind = "melee",
		DisplayName = "Бита",
		DamageType = "blunt",
		Damage = 22,
		FireRate = 0.8,
		Range = 7,
		Size = Vector3.new(0.35, 0.35, 3.4),
		Color = Color3.fromRGB(150, 110, 70),
	},
	Bandage = {
		Kind = "medical",
		DisplayName = "Бинт",
		Effect = "bandage",
		Uses = 3,
		UseTime = 2,
		Size = Vector3.new(0.6, 0.6, 0.6),
		Color = Color3.fromRGB(235, 235, 225),
	},
	Tourniquet = {
		Kind = "medical",
		DisplayName = "Жгут",
		Effect = "tourniquet",
		Uses = 1,
		UseTime = 1.5,
		Size = Vector3.new(0.3, 0.3, 1.2),
		Color = Color3.fromRGB(30, 30, 30),
	},
	Painkillers = {
		Kind = "medical",
		DisplayName = "Обезболивающее",
		Effect = "painkillers",
		Uses = 4,
		UseTime = 1,
		Size = Vector3.new(0.4, 0.7, 0.4),
		Color = Color3.fromRGB(230, 120, 40),
	},
	Adrenaline = {
		Kind = "medical",
		DisplayName = "Адреналин",
		Effect = "adrenaline",
		Uses = 1,
		UseTime = 0.8,
		Size = Vector3.new(0.2, 0.2, 1),
		Color = Color3.fromRGB(220, 40, 40),
	},
}

Config.WeaponOrder = {
	"Pistol",
	"Rifle",
	"Shotgun",
	"Knife",
	"Bat",
	"Bandage",
	"Tourniquet",
	"Painkillers",
	"Adrenaline",
}

Config.StarterLoadout = { "Pistol", "Knife", "Bandage", "Tourniquet" }

Config.Sandbox = {
	MaxDummies = 10,
	DummyCorpseLifetime = 30,
}

return Config
]==])
put(folder(game:GetService("ReplicatedStorage"), "Shared"), "ModuleScript", "BodyMap", [==[-- Maps character part names (R15 and R6) to body regions used by the organism.

local BodyMap = {}

local REGION_BY_PART = {
	Head = "head",

	UpperTorso = "chest",
	Torso = "chest",

	LowerTorso = "abdomen",
	HumanoidRootPart = "abdomen",

	LeftUpperArm = "larm",
	LeftLowerArm = "larm",
	LeftHand = "larm",
	["Left Arm"] = "larm",

	RightUpperArm = "rarm",
	RightLowerArm = "rarm",
	RightHand = "rarm",
	["Right Arm"] = "rarm",

	LeftUpperLeg = "lleg",
	LeftLowerLeg = "lleg",
	LeftFoot = "lleg",
	["Left Leg"] = "lleg",

	RightUpperLeg = "rleg",
	RightLowerLeg = "rleg",
	RightFoot = "rleg",
	["Right Leg"] = "rleg",
}

BodyMap.RegionNames = {
	head = "голова",
	chest = "грудь",
	abdomen = "живот",
	larm = "левая рука",
	rarm = "правая рука",
	lleg = "левая нога",
	rleg = "правая нога",
}

BodyMap.Limbs = { "larm", "rarm", "lleg", "rleg" }

function BodyMap.RegionForPart(partName: string): string?
	return REGION_BY_PART[partName]
end

function BodyMap.IsLimb(region: string): boolean
	return region == "larm" or region == "rarm" or region == "lleg" or region == "rleg"
end

return BodyMap
]==])
put(folder(game:GetService("ServerScriptService"), "Server"), "Script", "Main", [==[-- Sandbox server: builds the test map, attaches an organism to every
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
]==])
put(folder(game:GetService("ServerScriptService"), "Server"), "ModuleScript", "Organism", [==[-- Simplified port of Z-City's organism (lua/homigrad/organism).
-- Death works the same way as there: blood loss or heart failure starves the
-- body of oxygen, low oxygen damages the brain, and a fully damaged brain
-- kills. Health points are not used.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BodyMap = require(ReplicatedStorage.Shared.BodyMap)

local BLOOD = Config.Blood
local ORG = Config.Organism

export type Wound = {
	region: string,
	rate: number, -- ml/s at a normal pulse
	arterial: boolean,
}

local Organism = {}
Organism.__index = Organism

function Organism.new()
	local self = setmetatable({}, Organism)
	self:Reset()
	return self
end

function Organism:Reset()
	self.alive = true
	self.deathCause = nil

	self.blood = BLOOD.Max
	self.wounds = {} :: { Wound }
	self.internalBleed = 0
	self.bleedRate = 0

	self.pulse = ORG.BasePulse
	self.heartStopped = false
	self.o2 = 100
	self.brain = 0
	self.lungs = 0
	self.spine = 0

	self.pain = 0
	self.effectivePain = 0
	self.painkiller = 0
	self.adrenaline = 0

	self.consciousness = 1
	self.unconscious = false
	self.unconTimer = 0
	self.knockoutTime = 0

	self.fractures = { larm = false, rarm = false, lleg = false, rleg = false }
	self.mustRagdoll = false
end

local function chance(p: number): boolean
	return math.random() < p
end

function Organism:AddWound(region: string, rate: number, arterial: boolean)
	if rate <= 0.02 then
		return
	end
	table.insert(self.wounds, { region = region, rate = rate, arterial = arterial })
end

function Organism:HasArterialWound(): boolean
	for _, wound in self.wounds do
		if wound.arterial then
			return true
		end
	end
	return false
end

-- Applies one hit. Returns a list of injury tags for feedback ("brain", "heart", ...).
function Organism:ApplyHit(region: string, damage: number, damageType: string): { string }
	local injuries = {}
	if not self.alive then
		return injuries
	end

	local isBullet = damageType == "bullet"
	local isSlash = damageType == "slash"
	local isBlunt = damageType == "blunt"
	local penetrating = isBullet or isSlash

	self.adrenaline = math.min(self.adrenaline + 0.25, 3)
	self.pain += damage * (isBlunt and 1.4 or 1)

	local bleedMul = (isSlash and 0.25) or (isBullet and 0.15) or 0.03

	if region == "head" then
		local brainChance = (isBullet and 0.65) or (isBlunt and 0.25) or 0.15
		if chance(brainChance) then
			-- A pistol round to the brain is fatal, a pellet knocks you out.
			self.brain += damage / (isBullet and 30 or 120)
			table.insert(injuries, "brain")
		end
		if isBlunt and damage >= 18 and chance(0.5) then
			self.knockoutTime = math.max(self.knockoutTime, 4 + damage / 5)
			table.insert(injuries, "knockout")
		end
		self:AddWound(region, damage * bleedMul, false)
	elseif region == "chest" then
		if penetrating then
			local roll = math.random()
			if roll < 0.10 then
				self.heartStopped = true
				self.internalBleed += 60
				table.insert(injuries, "heart")
			elseif roll < 0.45 then
				self.lungs = math.min(1, self.lungs + damage / 60)
				self.internalBleed += damage * 0.25
				table.insert(injuries, "lungs")
			elseif roll < 0.53 then
				self.spine = 1
				table.insert(injuries, "spine")
			end
		elseif isBlunt and chance(0.3) then
			self.pain += 15
			table.insert(injuries, "ribs")
		end
		self:AddWound(region, damage * bleedMul, false)
	elseif region == "abdomen" then
		if penetrating then
			local roll = math.random()
			if roll < 0.25 then
				self.internalBleed += damage * 0.4
				table.insert(injuries, "liver")
			elseif roll < 0.33 then
				self.spine = 1
				table.insert(injuries, "spine")
			else
				self.pain += 10
				table.insert(injuries, "intestines")
			end
		end
		self:AddWound(region, damage * bleedMul, false)
	elseif BodyMap.IsLimb(region) then
		if penetrating and chance(0.15) then
			self:AddWound(region, ORG.ArterialBleed, true)
			table.insert(injuries, "artery")
		else
			self:AddWound(region, damage * bleedMul, false)
		end
		local fractureChance = (isBullet and 0.25) or (isBlunt and damage / 60) or 0.02
		if not self.fractures[region] and chance(fractureChance) then
			self.fractures[region] = true
			self.pain += 20
			table.insert(injuries, "fracture")
		end
	end

	return injuries
end

-- Landing too fast hurts the legs and, from very high, the spine.
function Organism:ApplyFall(speed: number): { string }
	local injuries = {}
	local excess = speed - Config.Movement.FallDamageSpeed
	if excess <= 0 or not self.alive then
		return injuries
	end

	self.pain += excess
	self.adrenaline = math.min(self.adrenaline + 0.2, 3)
	for _, leg in { "lleg", "rleg" } do
		if not self.fractures[leg] and chance(excess / 60) then
			self.fractures[leg] = true
			table.insert(injuries, "fracture")
		end
	end
	if excess > 60 and chance(0.3) then
		self.spine = 1
		table.insert(injuries, "spine")
	end
	if excess > 40 then
		self.knockoutTime = math.max(self.knockoutTime, 3)
	end
	return injuries
end

-- Medical items. Returns true when the item did something.
function Organism:Treat(effect: string): boolean
	if not self.alive then
		return false
	end

	if effect == "bandage" then
		local best, bestIndex = nil, nil
		for index, wound in self.wounds do
			if not wound.arterial and (best == nil or wound.rate > best.rate) then
				best, bestIndex = wound, index
			end
		end
		if bestIndex then
			table.remove(self.wounds, bestIndex)
			return true
		end
		return false
	elseif effect == "tourniquet" then
		for index, wound in self.wounds do
			if wound.arterial and BodyMap.IsLimb(wound.region) then
				table.remove(self.wounds, index)
				self.pain += 10
				return true
			end
		end
		return false
	elseif effect == "painkillers" then
		self.painkiller = math.min(self.painkiller + 40, 80)
		return true
	elseif effect == "adrenaline" then
		self.adrenaline = math.min(self.adrenaline + 2, 4)
		self.knockoutTime = 0
		return true
	end
	return false
end

function Organism:Die(cause: string)
	if not self.alive then
		return
	end
	self.alive = false
	self.deathCause = cause
	self.unconscious = true
	self.mustRagdoll = true
end

local function approach(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

function Organism:Tick(dt: number)
	if not self.alive then
		return
	end

	-- Bleeding. Normal wounds clot over time, arteries do not.
	local external = 0
	for index = #self.wounds, 1, -1 do
		local wound = self.wounds[index]
		if not wound.arterial then
			wound.rate -= wound.rate * ORG.WoundClotPerSecond * dt
			if wound.rate < 0.05 then
				table.remove(self.wounds, index)
				continue
			end
		end
		external += wound.rate
	end

	self.internalBleed = math.max(0, self.internalBleed - ORG.InternalBleedHealPerSecond * dt)
	local internal = self.internalBleed / ORG.InternalBleedDivisor

	local pulseFactor = self.heartStopped and 0.2 or math.max(self.pulse, 20) / ORG.BasePulse
	local adrenalineFactor = 1 - math.min(self.adrenaline / 6, 0.5)
	self.bleedRate = (external + internal) * pulseFactor * adrenalineFactor
	self.blood = math.max(0, self.blood - self.bleedRate * dt)
	if self.bleedRate < 0.01 then
		self.blood = math.min(BLOOD.Max, self.blood + ORG.BloodRegenPerSecond * dt)
	end

	-- Pain, painkillers, adrenaline.
	self.pain = math.max(0, self.pain - ORG.PainDecayPerSecond * dt)
	self.painkiller = math.max(0, self.painkiller - ORG.PainkillerDecayPerSecond * dt)
	self.adrenaline = math.max(0, self.adrenaline - ORG.AdrenalineDecayPerSecond * dt)
	self.effectivePain = math.max(0, self.pain - self.painkiller) * (1 - math.min(self.adrenaline / 3, 0.6))

	-- Pulse.
	if self.heartStopped then
		self.pulse = approach(self.pulse, 0, 40 * dt)
	else
		local target = ORG.BasePulse
			+ (self.effectivePain > 30 and 25 or 0)
			+ self.adrenaline * 15
			+ math.max(0, 4000 - self.blood) / 25
		if self.blood < BLOOD.CriticalAt then
			target = 40 * (self.blood / BLOOD.CriticalAt)
		end
		self.pulse = approach(self.pulse, target, 10 * dt)
		if self.pulse < 10 or self.brain >= 0.6 then
			self.heartStopped = true
		end
	end

	-- Oxygen: needs both a beating heart and enough blood.
	local perfusion = 0
	if not self.heartStopped then
		perfusion = math.clamp(self.blood / BLOOD.Max, 0, 1) * (1 - self.lungs * 0.7)
	end
	if perfusion < 0.35 then
		self.o2 -= ORG.O2DropPerSecond * (1 - perfusion / 0.35) * dt
	else
		self.o2 += ORG.O2RegenPerSecond * perfusion * dt
	end
	self.o2 = math.clamp(self.o2, 0, 100)

	-- Brain.
	if self.o2 < 10 then
		self.brain += ORG.BrainDamagePerSecond * dt
	end
	if self.brain >= 1 then
		self:Die(self.heartStopped and "cardiac" or "brain")
		return
	end

	-- Consciousness.
	local consciousness = math.min(1, self.blood / 3000)
		* (1 - math.clamp((self.effectivePain - 60) / 120, 0, 0.6))
		* (1 - self.brain)
	if self.o2 < 30 then
		consciousness *= self.o2 / 30
	end
	self.consciousness = consciousness

	self.knockoutTime = math.max(0, self.knockoutTime - dt)
	local faintAt = BLOOD.FaintAt / (self.adrenaline / 3 + 1)
	local mustFaint = self.heartStopped
		or self.blood < faintAt
		or consciousness <= 0.4
		or self.effectivePain > 140
		or self.knockoutTime > 0

	if mustFaint then
		self.unconscious = true
		self.unconTimer = 0
	elseif self.unconscious then
		self.unconTimer += dt
		if self.unconTimer >= ORG.WakeDelay then
			self.unconscious = false
		end
	end

	self.mustRagdoll = self.unconscious
		or self.spine >= 1
		or (self.fractures.lleg and self.fractures.rleg)
		or self.blood < BLOOD.RagdollAt
end

function Organism:SpeedMultiplier(): number
	local mult = 1
	if self.fractures.lleg then
		mult *= 0.55
	end
	if self.fractures.rleg then
		mult *= 0.55
	end
	if self.effectivePain > 50 then
		mult *= 0.8
	end
	if self.blood < 3500 then
		mult *= 0.8
	end
	if self.lungs > 0.5 then
		mult *= 0.85
	end
	return mult
end

function Organism:CanJump(): boolean
	return not (self.fractures.lleg or self.fractures.rleg)
end

-- Extra aim spread in degrees from broken arms and pain.
function Organism:AimPenalty(): number
	local penalty = 0
	if self.fractures.larm then
		penalty += 2
	end
	if self.fractures.rarm then
		penalty += 3
	end
	penalty += math.clamp(self.effectivePain / 40, 0, 3)
	return penalty
end

function Organism:FractureList(): string
	local names = {}
	for _, limb in BodyMap.Limbs do
		if self.fractures[limb] then
			table.insert(names, BodyMap.RegionNames[limb])
		end
	end
	if self.spine >= 1 then
		table.insert(names, "позвоночник")
	end
	return table.concat(names, ", ")
end

return Organism
]==])
put(folder(game:GetService("ServerScriptService"), "Server"), "ModuleScript", "Ragdoll", [==[-- Ragdoll for R15/R6 characters, the Roblox counterpart of Z-City's "fake"
-- (lua/homigrad/fake). Each Motor6D joint is swapped for a BallSocketConstraint.
-- The Root joint stays, so HumanoidRootPart follows the torso and the
-- character can stand back up where the body lies.
--
-- Player characters are physically owned by their client, so the client
-- also switches its Humanoid into the Physics state when the "Ragdolled"
-- attribute turns on (see src/client/Main.client.luau).

local Ragdoll = {}

-- Joint limits in degrees: {UpperAngle, TwistLower, TwistUpper}.
local LIMITS = {
	Neck = { 35, -40, 40 },
	Waist = { 25, -30, 30 },
	LeftShoulder = { 90, -60, 60 },
	RightShoulder = { 90, -60, 60 },
	LeftElbow = { 70, -10, 10 },
	RightElbow = { 70, -10, 10 },
	LeftWrist = { 30, -20, 20 },
	RightWrist = { 30, -20, 20 },
	LeftHip = { 60, -30, 30 },
	RightHip = { 60, -30, 30 },
	LeftKnee = { 70, -5, 5 },
	RightKnee = { 70, -5, 5 },
	LeftAnkle = { 25, -10, 10 },
	RightAnkle = { 25, -10, 10 },
}
local DEFAULT_LIMIT = { 45, -30, 30 }

local function getHumanoid(character: Model): Humanoid?
	return character:FindFirstChildOfClass("Humanoid")
end

function Ragdoll.IsRagdolled(character: Model): boolean
	return character:GetAttribute("Ragdolled") == true
end

function Ragdoll.Enable(character: Model)
	if Ragdoll.IsRagdolled(character) then
		return
	end
	local humanoid = getHumanoid(character)
	if not humanoid then
		return
	end

	character:SetAttribute("Ragdolled", true)

	for _, motor in character:GetDescendants() do
		if not motor:IsA("Motor6D") or motor.Name == "Root" or motor.Name == "RootJoint" then
			continue
		end
		if not motor.Part0 or not motor.Part1 then
			continue
		end

		local a0 = Instance.new("Attachment")
		a0.Name = "RagdollAttachment0"
		a0.CFrame = motor.C0
		a0.Parent = motor.Part0

		local a1 = Instance.new("Attachment")
		a1.Name = "RagdollAttachment1"
		a1.CFrame = motor.C1
		a1.Parent = motor.Part1

		local limits = LIMITS[motor.Name] or DEFAULT_LIMIT
		local socket = Instance.new("BallSocketConstraint")
		socket.Name = "RagdollSocket"
		socket.Attachment0 = a0
		socket.Attachment1 = a1
		socket.LimitsEnabled = true
		socket.UpperAngle = limits[1]
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = limits[2]
		socket.TwistUpperAngle = limits[3]
		socket.Parent = motor.Parent

		motor.Enabled = false
	end

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Parent == character then
			part.CanCollide = part.Name ~= "HumanoidRootPart"
		end
	end

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

function Ragdoll.Disable(character: Model)
	if not Ragdoll.IsRagdolled(character) then
		return
	end
	local humanoid = getHumanoid(character)

	for _, item in character:GetDescendants() do
		if item.Name == "RagdollSocket" or item.Name == "RagdollAttachment0" or item.Name == "RagdollAttachment1" then
			item:Destroy()
		end
	end

	-- Stand the root part upright where the body is, keeping the facing direction.
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local look = root.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 0.1 then
			flatLook = Vector3.new(0, 0, -1)
		end
		local position = root.Position + Vector3.new(0, 2, 0)
		root.CFrame = CFrame.lookAt(position, position + flatLook.Unit)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") then
			motor.Enabled = true
		end
	end

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Parent == character and part.Name ~= "HumanoidRootPart" then
			-- The Humanoid manages collisions for standing characters.
			part.CanCollide = part.Name == "Head" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Torso"
		end
	end

	character:SetAttribute("Ragdolled", false)

	if humanoid and humanoid.Health > 0 then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

return Ragdoll
]==])
put(folder(game:GetService("ServerScriptService"), "Server"), "ModuleScript", "Weapons", [==[-- Server side of weapons and medical items. The client only sends where it
-- aims; the server checks the equipped tool, fire rate and ammo, and does
-- the raycast itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

export type HitCallback = (model: Model, part: BasePart, damage: number, damageType: string, position: Vector3) -> ()

local Weapons = {}

local lastUse: { [Player]: number } = {}

function Weapons.CreateTool(weaponId: string): Tool?
	local def = Config.Weapons[weaponId]
	if not def then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = def.DisplayName
	tool.ToolTip = def.DisplayName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("WeaponId", weaponId)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = def.Size
	handle.Color = def.Color
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	if def.Kind == "gun" then
		tool:SetAttribute("Ammo", def.MagSize)
		tool:SetAttribute("MaxAmmo", def.MagSize)
		local muzzle = Instance.new("Attachment")
		muzzle.Name = "Muzzle"
		muzzle.Position = Vector3.new(0, 0, -def.Size.Z / 2)
		muzzle.Parent = handle
	elseif def.Kind == "medical" then
		tool:SetAttribute("Uses", def.Uses)
	end

	return tool
end

local function equippedTool(player: Player, weaponId: string): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("WeaponId") == weaponId then
		return tool
	end
	return nil
end

local function spreadDirection(direction: Vector3, degrees: number): Vector3
	if degrees <= 0 then
		return direction
	end
	local spread = math.rad(degrees)
	local rotation = CFrame.lookAt(Vector3.zero, direction)
		* CFrame.Angles(0, 0, math.random() * math.pi * 2)
		* CFrame.Angles(math.random() * spread, 0, 0)
	return rotation.LookVector
end

local function findCharacterModel(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function Weapons.CanAct(player: Player): boolean
	local character = player.Character
	if not character or character:GetAttribute("Ragdolled") or character:GetAttribute("Unconscious") then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- direction: unit vector from the client's camera aim.
-- aimPenalty: extra spread in degrees from the shooter's organism.
function Weapons.Fire(
	player: Player,
	weaponId: string,
	direction: Vector3,
	aimPenalty: number,
	onHit: HitCallback,
	effects: RemoteEvent
)
	local def = Config.Weapons[weaponId]
	if not def or (def.Kind ~= "gun" and def.Kind ~= "melee") then
		return
	end
	if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 or direction.Magnitude > 1.5 then
		return
	end
	direction = direction.Unit
	if not Weapons.CanAct(player) then
		return
	end
	local tool = equippedTool(player, weaponId)
	if not tool or tool:GetAttribute("Reloading") then
		return
	end

	local now = os.clock()
	if now - (lastUse[player] or 0) < def.FireRate * 0.9 then
		return
	end

	local character = player.Character :: Model
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	if def.Kind == "gun" then
		local ammo = tool:GetAttribute("Ammo") or 0
		if ammo <= 0 then
			return
		end
		tool:SetAttribute("Ammo", ammo - 1)
		lastUse[player] = now

		local handle = tool:FindFirstChild("Handle")
		local muzzle = handle and handle:FindFirstChild("Muzzle") :: Attachment?
		local muzzlePosition = muzzle and muzzle.WorldPosition or head.Position

		for _ = 1, def.Pellets do
			local shotDirection = spreadDirection(direction, def.Spread + aimPenalty)
			local result = Workspace:Raycast(head.Position, shotDirection * def.Range, params)
			local hitPosition = result and result.Position or (head.Position + shotDirection * def.Range)
			effects:FireAllClients("tracer", muzzlePosition, hitPosition)

			if result then
				local model = findCharacterModel(result.Instance)
				if model then
					effects:FireAllClients("blood", result.Position, result.Normal)
					onHit(model, result.Instance, def.Damage, def.DamageType, result.Position)
				else
					effects:FireAllClients("impact", result.Position, result.Normal)
				end
			end
		end
	else
		lastUse[player] = now
		local result = Workspace:Spherecast(head.Position, 1.2, direction * def.Range, params)
		effects:FireAllClients("swing", head.Position, head.Position + direction * def.Range)
		if result then
			local model = findCharacterModel(result.Instance)
			if model then
				effects:FireAllClients("blood", result.Position, result.Normal)
				onHit(model, result.Instance, def.Damage, def.DamageType, result.Position)
			end
		end
	end
end

function Weapons.Reload(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local def = Config.Weapons[tool:GetAttribute("WeaponId") or ""]
	if not def or def.Kind ~= "gun" or tool:GetAttribute("Reloading") then
		return
	end
	if (tool:GetAttribute("Ammo") or 0) >= def.MagSize then
		return
	end

	tool:SetAttribute("Reloading", true)
	task.delay(def.ReloadTime, function()
		if tool.Parent then
			tool:SetAttribute("Ammo", def.MagSize)
			tool:SetAttribute("Reloading", false)
		end
	end)
end

-- treat: applies the effect to the user's organism, returns true on success.
function Weapons.UseMedical(player: Player, weaponId: string, treat: (effect: string) -> boolean)
	local def = Config.Weapons[weaponId]
	if not def or def.Kind ~= "medical" then
		return
	end
	if not Weapons.CanAct(player) then
		return
	end
	local tool = equippedTool(player, weaponId)
	if not tool or tool:GetAttribute("InUse") then
		return
	end

	tool:SetAttribute("InUse", true)
	task.delay(def.UseTime, function()
		if not tool.Parent then
			return
		end
		tool:SetAttribute("InUse", false)
		if equippedTool(player, weaponId) ~= tool or not Weapons.CanAct(player) then
			return
		end
		if treat(def.Effect) then
			local uses = (tool:GetAttribute("Uses") or 1) - 1
			if uses <= 0 then
				tool:Destroy()
			else
				tool:SetAttribute("Uses", uses)
			end
		end
	end)
end

function Weapons.Forget(player: Player)
	lastUse[player] = nil
end

return Weapons
]==])
put(SP:FindFirstChildOfClass("StarterPlayerScripts"), "LocalScript", "Main", [==[-- Sandbox client: weapon input, ragdoll state on the owning client, organism
-- HUD, blackout, sandbox menu and hit effects.
--
-- Controls:
--   Left mouse  attack / use item
--   R           reload
--   G           fall down / try to get up
--   Q           sandbox menu

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireRemote = remotes:WaitForChild("Fire") :: RemoteEvent
local reloadRemote = remotes:WaitForChild("Reload") :: RemoteEvent
local useRemote = remotes:WaitForChild("UseItem") :: RemoteEvent
local sandboxRemote = remotes:WaitForChild("Sandbox") :: RemoteEvent
local effectsRemote = remotes:WaitForChild("Effects") :: RemoteEvent

--------------------------------------------------------------------------
-- UI helpers
--------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "ZCitySandbox"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 16
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextStrokeTransparency = 0.6
	for key, value in props do
		(text :: any)[key] = value
	end
	text.Parent = parent
	return text
end

-- Blackout sits under everything else.
local blackout = Instance.new("Frame")
blackout.Name = "Blackout"
blackout.Size = UDim2.fromScale(1, 1)
blackout.BackgroundColor3 = Color3.new(0, 0, 0)
blackout.BackgroundTransparency = 1
blackout.ZIndex = 1
blackout.Parent = gui

local blackoutText = label(blackout, {
	Size = UDim2.fromScale(1, 1),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 24,
	Text = "",
	ZIndex = 2,
})

-- Organism status, bottom left.
local status = label(gui, {
	Name = "Status",
	Position = UDim2.new(0, 16, 1, -220),
	Size = UDim2.new(0, 360, 0, 200),
	TextYAlignment = Enum.TextYAlignment.Bottom,
	RichText = true,
	ZIndex = 5,
})

-- Ammo, bottom right.
local ammoLabel = label(gui, {
	Name = "Ammo",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextSize = 22,
	ZIndex = 5,
})

-- Info about the character under the cursor.
local targetInfo = label(gui, {
	Name = "TargetInfo",
	Size = UDim2.new(0, 260, 0, 120),
	TextSize = 14,
	TextYAlignment = Enum.TextYAlignment.Top,
	RichText = true,
	Visible = false,
	ZIndex = 6,
})

label(gui, {
	Name = "Help",
	Position = UDim2.new(0, 16, 0, 50),
	Size = UDim2.new(0, 420, 0, 20),
	TextSize = 14,
	TextTransparency = 0.3,
	Text = "Q — меню   ЛКМ — атака/использовать   R — перезарядка   G — упасть/встать",
	ZIndex = 5,
})

--------------------------------------------------------------------------
-- Sandbox menu
--------------------------------------------------------------------------

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.new(0, 460, 0, 380)
menu.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
menu.BackgroundTransparency = 0.1
menu.Visible = false
menu.ZIndex = 10
menu.Parent = gui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menu

local menuPadding = Instance.new("UIPadding")
menuPadding.PaddingTop = UDim.new(0, 12)
menuPadding.PaddingBottom = UDim.new(0, 12)
menuPadding.PaddingLeft = UDim.new(0, 12)
menuPadding.PaddingRight = UDim.new(0, 12)
menuPadding.Parent = menu

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 138, 0, 40)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = menu

local function menuButton(text: string, order: number, color: Color3, onClick: () -> ())
	local button = Instance.new("TextButton")
	button.Text = text
	button.LayoutOrder = order
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 15
	button.AutoButtonColor = true
	button.ZIndex = 11
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	button.Parent = menu
	button.Activated:Connect(onClick)
end

for index, weaponId in Config.WeaponOrder do
	local def = Config.Weapons[weaponId]
	local color = def.Kind == "medical" and Color3.fromRGB(45, 95, 70) or Color3.fromRGB(70, 70, 80)
	menuButton(def.DisplayName, index, color, function()
		sandboxRemote:FireServer("Give", weaponId)
	end)
end

local actionColor = Color3.fromRGB(110, 70, 40)
menuButton("Манекен", 100, actionColor, function()
	sandboxRemote:FireServer("SpawnDummy")
end)
menuButton("Убрать манекены", 101, actionColor, function()
	sandboxRemote:FireServer("ClearDummies")
end)
menuButton("Вылечить себя", 102, Color3.fromRGB(40, 110, 60), function()
	sandboxRemote:FireServer("Heal")
end)
menuButton("Упасть / встать", 103, actionColor, function()
	sandboxRemote:FireServer("ToggleRagdoll")
end)

--------------------------------------------------------------------------
-- Weapons
--------------------------------------------------------------------------

local equipped: Tool? = nil
local triggerHeld = false
local lastShot = 0

local function aimDirection(): Vector3?
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil
	end
	local target = mouse.Hit.Position
	local offset = target - head.Position
	if offset.Magnitude < 0.1 then
		return Workspace.CurrentCamera.CFrame.LookVector
	end
	return offset.Unit
end

local function tryAttack()
	local tool = equipped
	if not tool then
		return
	end
	local weaponId = tool:GetAttribute("WeaponId")
	local def = weaponId and Config.Weapons[weaponId]
	if not def then
		return
	end

	if def.Kind == "medical" then
		useRemote:FireServer(weaponId)
		return
	end

	local now = os.clock()
	if now - lastShot < def.FireRate then
		return
	end
	local direction = aimDirection()
	if not direction then
		return
	end
	lastShot = now
	fireRemote:FireServer(weaponId, direction)
end

local boundTools: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function bindTool(tool: Tool)
	if boundTools[tool] or not tool:GetAttribute("WeaponId") then
		return
	end
	boundTools[tool] = true
	tool.Equipped:Connect(function()
		equipped = tool
	end)
	tool.Unequipped:Connect(function()
		if equipped == tool then
			equipped = nil
		end
		triggerHeld = false
	end)
	tool.Activated:Connect(function()
		triggerHeld = true
		tryAttack()
	end)
	tool.Deactivated:Connect(function()
		triggerHeld = false
	end)
end

-- Automatic fire while the trigger is held.
RunService.RenderStepped:Connect(function()
	if not triggerHeld or not equipped then
		return
	end
	local def = Config.Weapons[equipped:GetAttribute("WeaponId") or ""]
	if def and def.Auto then
		tryAttack()
	end
end)

--------------------------------------------------------------------------
-- Character: ragdoll state and camera
--------------------------------------------------------------------------

local function onCharacter(character: Model)
	equipped = nil
	triggerHeld = false

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local head = character:WaitForChild("Head") :: BasePart

	local function applyRagdoll()
		local camera = Workspace.CurrentCamera
		if character:GetAttribute("Ragdolled") then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			camera.CameraSubject = head
		else
			if humanoid.Health > 0 then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			camera.CameraSubject = humanoid
		end
	end
	character:GetAttributeChangedSignal("Ragdolled"):Connect(applyRagdoll)
	applyRagdoll()

	-- Roblox creates a new Backpack on every respawn, so bind to this one.
	local backpack = player:WaitForChild("Backpack")
	for _, item in backpack:GetChildren() do
		if item:IsA("Tool") then
			bindTool(item)
		end
	end
	backpack.ChildAdded:Connect(function(item)
		if item:IsA("Tool") then
			bindTool(item)
		end
	end)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

--------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		menu.Visible = not menu.Visible
	elseif input.KeyCode == Enum.KeyCode.R then
		reloadRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.G then
		sandboxRemote:FireServer("ToggleRagdoll")
	end
end)

--------------------------------------------------------------------------
-- HUD
--------------------------------------------------------------------------

local function colorFor(value: number, bad: number, good: number): string
	local t = math.clamp((value - bad) / (good - bad), 0, 1)
	local r = math.floor(255 * (1 - t) + 120 * t)
	local g = math.floor(80 * (1 - t) + 230 * t)
	return string.format("rgb(%d,%d,90)", r, g)
end

local function describe(model: Model, short: boolean): string
	local blood = model:GetAttribute("Blood") or 0
	local pulse = model:GetAttribute("Pulse") or 0
	local o2 = model:GetAttribute("O2") or 0
	local pain = model:GetAttribute("Pain") or 0
	local bleed = model:GetAttribute("Bleed") or 0
	local fractures = model:GetAttribute("Fractures") or ""
	local lines = {
		string.format('Кровь: <font color="%s">%d мл</font>', colorFor(blood, 2400, 5000), blood),
		string.format('Пульс: <font color="%s">%d</font>', colorFor(pulse, 10, 70), pulse),
		string.format('Кислород: <font color="%s">%d%%</font>', colorFor(o2, 10, 100), o2),
	}
	if not short then
		table.insert(lines, string.format('Боль: <font color="%s">%d</font>', colorFor(-pain, -140, 0), pain))
		table.insert(lines, string.format("Сознание: %d%%", math.floor((model:GetAttribute("Consciousness") or 0) * 100)))
	end
	if bleed > 0 then
		local arterial = model:GetAttribute("Arterial") and " (артерия!)" or ""
		table.insert(lines, string.format('<font color="rgb(230,60,60)">Кровотечение: %.1f мл/с%s</font>', bleed, arterial))
	end
	if fractures ~= "" then
		table.insert(lines, '<font color="rgb(240,170,60)">Переломы: ' .. fractures .. "</font>")
	end
	if model:GetAttribute("HeartStopped") then
		table.insert(lines, '<font color="rgb(255,40,40)">Остановка сердца</font>')
	end
	local lastHit = model:GetAttribute("LastHit")
	if lastHit and not short then
		table.insert(lines, '<font color="rgb(180,180,180)">Последнее ранение: ' .. lastHit .. "</font>")
	end
	return table.concat(lines, "\n")
end

local function findCharacter(part: Instance?): Model?
	while part and part ~= Workspace do
		if part:IsA("Model") and part:GetAttribute("Blood") ~= nil then
			return part
		end
		part = part.Parent
	end
	return nil
end

RunService.RenderStepped:Connect(function()
	local character = player.Character

	-- Own status and blackout.
	if character and character:GetAttribute("Blood") ~= nil then
		status.Text = describe(character, false)
		local consciousness = character:GetAttribute("Consciousness") or 1
		if character:GetAttribute("Dead") then
			blackout.BackgroundTransparency = 0
			blackoutText.Text = "Вы погибли"
		elseif character:GetAttribute("Unconscious") then
			blackout.BackgroundTransparency = 0.02
			blackoutText.Text = "Без сознания"
		else
			-- Vision fades as consciousness drops toward fainting.
			blackout.BackgroundTransparency = math.clamp((consciousness - 0.4) / 0.6, 0, 1) * 0.7 + 0.3
			if consciousness > 0.95 then
				blackout.BackgroundTransparency = 1
			end
			blackoutText.Text = ""
		end
	else
		status.Text = ""
		blackout.BackgroundTransparency = 1
		blackoutText.Text = ""
	end

	-- Ammo.
	local tool = equipped
	if tool and tool:GetAttribute("MaxAmmo") then
		if tool:GetAttribute("Reloading") then
			ammoLabel.Text = "Перезарядка..."
		else
			ammoLabel.Text = string.format("%d / %d", tool:GetAttribute("Ammo") or 0, tool:GetAttribute("MaxAmmo"))
		end
	elseif tool and tool:GetAttribute("Uses") then
		ammoLabel.Text = tool:GetAttribute("InUse") and "Применение..." or string.format("Осталось: %d", tool:GetAttribute("Uses"))
	else
		ammoLabel.Text = ""
	end

	-- Character under the cursor.
	local target = findCharacter(mouse.Target)
	if target and target ~= character then
		targetInfo.Visible = true
		targetInfo.Position = UDim2.fromOffset(mouse.X + 18, mouse.Y + 18)
		local title = target:GetAttribute("Dead") and "<b>Мёртв</b>"
			or (target:GetAttribute("Unconscious") and "<b>Без сознания</b>" or "<b>" .. target.Name .. "</b>")
		targetInfo.Text = title .. "\n" .. describe(target, true)
	else
		targetInfo.Visible = false
	end
end)

--------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------

local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "ClientEffects"
effectsFolder.Parent = Workspace

local function effectPart(size: Vector3, color: Color3, cframe: CFrame, lifetime: number, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CFrame = cframe
	part.Parent = effectsFolder
	Debris:AddItem(part, lifetime)
	return part
end

effectsRemote.OnClientEvent:Connect(function(kind, a, b)
	if kind == "tracer" then
		local length = (b - a).Magnitude
		effectPart(
			Vector3.new(0.08, 0.08, length),
			Color3.fromRGB(255, 220, 120),
			CFrame.lookAt(a, b) * CFrame.new(0, 0, -length / 2),
			0.05,
			Enum.Material.Neon
		)
	elseif kind == "blood" then
		for _ = 1, 4 do
			local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.8
			effectPart(Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(120, 0, 0), CFrame.new(a + offset), 0.6)
		end
	elseif kind == "impact" then
		effectPart(Vector3.new(0.3, 0.3, 0.05), Color3.fromRGB(40, 40, 40), CFrame.lookAt(a, a + b), 6)
	elseif kind == "swing" then
		local length = (b - a).Magnitude
		local swing = effectPart(
			Vector3.new(0.05, 0.6, length),
			Color3.fromRGB(230, 230, 230),
			CFrame.lookAt(a, b) * CFrame.new(0, 0, -length / 2),
			0.08
		)
		swing.Transparency = 0.6
	end
end)

-- Blood drips from bleeding characters, and pools under them on the ground.
local dripParams = RaycastParams.new()
dripParams.FilterType = Enum.RaycastFilterType.Exclude

task.spawn(function()
	while true do
		task.wait(0.35)
		local bleeding = {}
		for _, other in Players:GetPlayers() do
			if other.Character then
				table.insert(bleeding, other.Character)
			end
		end
		local dummies = Workspace:FindFirstChild("Dummies")
		if dummies then
			for _, dummy in dummies:GetChildren() do
				table.insert(bleeding, dummy)
			end
		end

		for _, model in bleeding do
			local rate = model:GetAttribute("Bleed") or 0
			local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
			if rate > 0.5 and torso and math.random() < math.min(rate / 6, 1) then
				dripParams.FilterDescendantsInstances = { model, effectsFolder }
				local result = Workspace:Raycast(torso.Position, Vector3.new(0, -12, 0), dripParams)
				if result then
					local size = math.clamp(rate / 8, 0.4, 2)
					effectPart(
						Vector3.new(size, 0.05, size),
						Color3.fromRGB(100, 0, 0),
						CFrame.new(result.Position + Vector3.new(0, 0.03, 0)),
						20
					)
				end
			end
		end
	end
end)
]==])
put(SP:FindFirstChildOfClass("StarterCharacterScripts"), "Script", "Health", [==[-- Replaces Roblox's default "Health" script so characters do not regenerate
-- health on their own. Damage and recovery are driven by the organism system.
]==])
print("Z-City sandbox installed. Press Play.")
