-- Maps character part names (R15 and R6) to body regions used by the organism.

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
