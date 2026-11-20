-- Sandbox client: weapon input, ragdoll state on the owning client, organism
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
