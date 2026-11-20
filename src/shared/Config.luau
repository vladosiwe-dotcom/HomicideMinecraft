-- Shared tuning values. Numbers for blood and consciousness follow Z-City's
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
