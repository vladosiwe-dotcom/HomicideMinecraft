-- Server side of weapons and medical items. The client only sends where it
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
