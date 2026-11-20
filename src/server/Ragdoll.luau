-- Ragdoll for R15/R6 characters, the Roblox counterpart of Z-City's "fake"
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
