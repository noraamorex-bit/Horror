--[[
	Actions (v147, the owner: "make animations for everything like brushing and peeking out and all
	things"): every player's body moves with what they're doing, on every screen. The server says
	what (player attributes "Act"/"ActAt"/"ActHold" from the prompt they're using, "Calling",
	"PhoneOut", "Captured"); the shared ActPose turns it into R15 joint transforms, laid over the
	walk/idle animation each frame (blended in and out). A toothbrush, the phone or a page shows in
	the hand.

	Your own first-person view: your arms appear while you do it (the camera hides your body
	otherwise), posed further out so they're on screen, and the camera dips or rocks a little
	(Actions.cameraOffset, added by Movement).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Actions = {}
local ctx
local AP
local player = Players.LocalPlayer

local ARM_PARTS = {
	R = { "RightUpperArm", "RightLowerArm", "RightHand" },
	L = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
}
local JOINTS = {
	Waist = { "UpperTorso", "Waist" },
	Neck = { "Head", "Neck" },
	RS = { "RightUpperArm", "RightShoulder" },
	RE = { "RightLowerArm", "RightElbow" },
	RW = { "RightHand", "RightWrist" },
	LS = { "LeftUpperArm", "LeftShoulder" },
	LE = { "LeftLowerArm", "LeftElbow" },
	LW = { "LeftHand", "LeftWrist" },
}
local NAME = { Waist = "Waist", Neck = "Neck", RS = "RightShoulder", RE = "RightElbow", RW = "RightWrist", LS = "LeftShoulder", LE = "LeftElbow", LW = "LeftWrist" }

local states = {} -- character -> { Rig, Motors, Kind, Weight, Prop, Started, ShownArms }
local camOffset = Vector3.zero
local warned = false

-- the rig's joints and their offsets (any R15 avatar; nil for R6)
local function rigOf(char: Model)
	local motors, rig = {}, {}
	for key, path in JOINTS do
		local part = char:FindFirstChild(path[1])
		local m = part and part:FindFirstChild(path[2])
		if not (m and m:IsA("Motor6D")) then
			if key ~= "Waist" and key ~= "Neck" then
				return nil
			end
		else
			motors[NAME[key]] = m
			rig[key] = { C0 = m.C0, C1 = m.C1 }
		end
	end
	local L1 = (rig.RE.C0.Position - rig.RS.C1.Position).Magnitude
	local L2 = (rig.RW.C0.Position - rig.RE.C1.Position).Magnitude
	rig.Scale = (L1 + L2) / 1.643
	return rig, motors
end

-- what this player is doing now (kind, seconds into it, hold) or nil
local function current(p: Player): (string?, number)
	if not p:GetAttribute("InGame") or p:GetAttribute("Hiding") or p:GetAttribute("Dead") or p:GetAttribute("Escaped") or p:GetAttribute("Monster") then
		return nil, 0
	end
	if p:GetAttribute("Captured") then
		return "Tied", os.clock()
	end
	if p:GetAttribute("Calling") then
		return "Call", os.clock()
	end
	local kind = p:GetAttribute("Act")
	local at = p:GetAttribute("ActAt")
	if type(kind) == "string" and AP.Kinds[kind] and type(at) == "number" then
		local t = workspace:GetServerTimeNow() - at
		local def = AP.Kinds[kind]
		if p:GetAttribute("ActHold") or t < def.Time + (def.Hold and 0 or 0.05) then
			-- (hold kinds loop on the clock; one-shots run on their own time)
			return kind, def.Hold and os.clock() or math.max(0, t)
		end
	end
	if p:GetAttribute("PhoneOut") then
		return "PhoneOut", os.clock()
	end
	return nil, 0
end

-- a little prop in the hand (local, anchored, placed every frame)
local PROPS = {
	Toothbrush = function()
		local m = Instance.new("Model")
		local h = Instance.new("Part")
		h.Name = "Handle"
		h.Size = Vector3.new(0.09, 0.09, 0.75)
		h.Color = Color3.fromRGB(70, 150, 220)
		h.Parent = m
		local b = Instance.new("Part")
		b.Name = "Bristles"
		b.Size = Vector3.new(0.08, 0.14, 0.2)
		b.Color = Color3.new(1, 1, 1)
		b.Parent = m
		return m, { [h] = CFrame.new(0, 0, -0.2), [b] = CFrame.new(0, 0.1, -0.5) }
	end,
	Phone = function()
		local m = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(0.27, 0.05, 0.5)
		body.Color = Color3.fromRGB(22, 22, 26)
		body.Parent = m
		local screen = Instance.new("Part")
		screen.Name = "Screen"
		screen.Size = Vector3.new(0.23, 0.01, 0.44)
		screen.Color = Color3.fromRGB(150, 190, 230)
		screen.Material = Enum.Material.Neon
		screen.Transparency = 0.25
		screen.Parent = m
		return m, { [body] = CFrame.new(0, 0, -0.12), [screen] = CFrame.new(0, 0.03, -0.12) }
	end,
	Paper = function()
		local m = Instance.new("Model")
		local sheet = Instance.new("Part")
		sheet.Name = "Sheet"
		sheet.Size = Vector3.new(0.75, 0.02, 0.95)
		sheet.Color = Color3.fromRGB(236, 230, 214)
		sheet.Material = Enum.Material.SmoothPlastic
		sheet.Parent = m
		return m, { [sheet] = CFrame.new(0.3, -0.05, -0.2) * CFrame.Angles(0, 0, 0) }
	end,
}

local function dropProp(st)
	if st.Prop then
		st.Prop:Destroy()
		st.Prop, st.PropParts, st.PropKind = nil, nil, nil
	end
end

local function makeProp(st, kind: string)
	local def = AP.Kinds[kind]
	local want = def and def.Prop
	if st.PropKind == want then
		return
	end
	dropProp(st)
	if not want or not PROPS[want] then
		return
	end
	local m, parts = PROPS[want]()
	for part in parts do
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
	end
	m.Name = "ActProp"
	m.Parent = workspace.CurrentCamera
	st.Prop, st.PropParts, st.PropKind = m, parts, want
end

local function isFirstPerson(char: Model): boolean
	local head = char:FindFirstChild("Head") :: BasePart?
	local cam = workspace.CurrentCamera
	return head ~= nil and cam ~= nil and cam.CameraType ~= Enum.CameraType.Scriptable and (cam.CFrame.Position - head.Position).Magnitude < 1.6
end

local function showArms(char: Model, st, sides: { [string]: boolean }?)
	-- (Roblox's first-person camera hides the whole body and only re-applies when its own value
	-- changes: we show the arms while acting and put back what we found when done)
	st.ShownArms = st.ShownArms or {}
	for side, names in ARM_PARTS do
		local on = sides and sides[side]
		for _, n in names do
			local part = char:FindFirstChild(n)
			if part and part:IsA("BasePart") then
				if on then
					if st.ShownArms[part] == nil then
						st.ShownArms[part] = part.LocalTransparencyModifier
					end
					part.LocalTransparencyModifier = 0
				elseif st.ShownArms[part] ~= nil then
					part.LocalTransparencyModifier = st.ShownArms[part]
					st.ShownArms[part] = nil
				end
			end
		end
	end
end

local function stateFor(char: Model)
	local st = states[char]
	if st and st.Rig and st.Rig.RS then
		-- (a new avatar loaded into the same character: re-read the joints)
		local m = st.Motors.RightShoulder
		if not m or not m.Parent or not m:IsDescendantOf(char) then
			st = nil
		end
	end
	if not st then
		local rig, motors = rigOf(char)
		st = { Rig = rig, Motors = motors, Weight = 0, Kind = nil }
		states[char] = st
	end
	return st
end

local function step(dt: number)
	local localCam = Vector3.zero
	for _, p in Players:GetPlayers() do
		local char = p.Character
		if char and char.Parent then
			local st = stateFor(char)
			if st.Rig then
				local kind, t = current(p)
				if kind and kind ~= st.Kind then
					if st.Weight > 0.05 and st.Kind then
						-- (switching straight from one to another: blend through)
						st.Weight *= 0.5
					end
					st.Kind = kind
					st.Started = os.clock()
				end
				local want = kind and 1 or 0
				st.Weight = math.clamp(st.Weight + (want > st.Weight and 7 or -4.5) * dt, 0, 1)
				if not kind and st.Weight <= 0 then
					st.Kind = nil
				end
				local fp = p == player and isFirstPerson(char)
				if st.Kind and st.Weight > 0 then
					local def = AP.Kinds[st.Kind]
					-- loops (holds, the phone, the call, the ties) run on our clock from when they began;
					-- one-shots on the server's (so everyone sees the same moment); fading out, time goes on
					local loop = def.Hold or st.Kind == "PhoneOut"
					if kind then
						st.T = loop and (os.clock() - (st.Started or os.clock())) or t
					else
						st.T = (st.T or 0) + dt
					end
					local tt = st.T
					-- (struggling: the zip ties shake with every press)
					if st.Kind == "Tied" then
						local prog = p:GetAttribute("StruggleProgress") or 0
						if prog ~= st.LastProg then
							st.LastProg = prog
							st.Jolt = os.clock()
						end
						tt = (st.Jolt and os.clock() - st.Jolt < 0.35) and os.clock() or 0
					end
					local tg = AP.targets(st.Kind, tt, fp)
					if tg then
						local w = st.Weight * (tg.Weight or 1)
						local pose = AP.solve(st.Rig, tg)
						for name, cf in pose do
							local m = st.Motors[name]
							if m and m.Parent then
								m.Transform = m.Transform:Lerp(cf, w)
							end
						end
						if p == player then
							if fp then
								showArms(char, st, { R = tg.R ~= nil and w > 0.05, L = tg.L ~= nil and w > 0.05 })
							else
								showArms(char, st, nil)
							end
							-- the camera follows the body a little
							if fp then
								local dip = 0
								if st.Kind == "Search" then
									dip = -0.45
								elseif st.Kind == "Work" then
									dip = -0.25
								elseif st.Kind == "Take" then
									dip = (tg.Waist or 0) * 3 -- (the reach's bow: Waist is already scaled for fp)
								elseif st.Kind == "Read" or st.Kind == "Phone" or st.Kind == "PhoneOut" then
									dip = -0.08
								end
								local rock = st.Kind == "Brush" and math.sin(os.clock() * 15) * 0.015 or 0
								localCam = Vector3.new(rock, dip, 0) * w
							end
						end
						makeProp(st, st.Kind)
						-- (the prop rides in the hand: placed after the pose, in PreRender)
						st.PropHand = char:FindFirstChild("RightHand")
						st.PropW = w
					end
				else
					if p == player and st.ShownArms and next(st.ShownArms) then
						showArms(char, st, nil)
					end
					dropProp(st)
				end
			end
		end
	end
	for char, st in states do
		if not char.Parent then
			dropProp(st)
			states[char] = nil
		end
	end
	camOffset = camOffset:Lerp(localCam, math.min(1, dt * 10))
end

local function placeProps()
	for char, st in states do
		if st.Prop and st.PropHand and st.PropHand.Parent then
			local hand = st.PropHand :: BasePart
			-- (the hand's CFrame from its joints right now: the pose was written this frame)
			local cf = hand.CFrame * CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(-90), 0, 0)
			local hide = (st.PropW or 0) < 0.35
			for part, off in st.PropParts do
				part.CFrame = cf * off
				part.LocalTransparencyModifier = hide and 1 or 0
			end
		end
	end
end

function Actions.cameraOffset(): Vector3
	return camOffset
end

function Actions.init(c)
	ctx = c
	ctx.Actions = Actions
	AP = ctx.ActPose
end

function Actions.start()
	-- (after the Animator has written this frame's animation: our pose goes on top of it)
	RunService.Stepped:Connect(function(_, dt)
		local ok, err = pcall(step, math.min(dt, 0.1))
		if not ok and not warned then
			warned = true
			warn("[Actions] " .. tostring(err))
		end
	end)
	RunService.RenderStepped:Connect(placeProps)
	-- (your arms stay shown in first person after Roblox's camera hides the body each frame)
	RunService:BindToRenderStep("HomeAloneActArms", Enum.RenderPriority.Camera.Value + 2, function()
		local char = player.Character
		local st = char and states[char]
		if st and st.ShownArms then
			for part in st.ShownArms do
				if part.Parent then
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end)
end

return Actions
