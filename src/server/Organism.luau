-- Simplified port of Z-City's organism (lua/homigrad/organism).
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
