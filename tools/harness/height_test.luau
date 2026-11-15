-- height_test (v169, the owner: "Why is player so tall now"): characters are scaled to a grown-up's height from the parts they have
-- now (not a head found at spawn that may be stale), never past x1.2, never from a measurement outside a person's range.
local H = require("./env")
local R = H.roblox
local V = R.Vector3.new
H.realModels = true
local ctx: any = { Config = H.load("RS/Shared/Config") }
local PS = H.load("Server/Services/PlayerStateService")
PS.init(ctx)

local function rig(height: number)
	local char = H.Instance.new("Model", H.workspaceRoot)
	local root = H.Instance.new("Part", char); root.Name = "HumanoidRootPart"; root.Size = V(2, 2, 1)
	local hum = H.Instance.new("Humanoid", char)
	local legs = height * 0.45
	root.CFrame = R.CFrame.new(0, legs + 1, 0)
	hum.HipHeight = legs
	local head = H.Instance.new("Part", char); head.Name = "Head"; head.Size = V(1.2, 1.2, 1.2)
	head.CFrame = R.CFrame.new(0, height - 0.6, 0)
	for _, n in { "LeftFoot", "RightFoot" } do
		local f = H.Instance.new("Part", char); f.Name = n; f.Size = V(0.8, 0.4, 1)
		f.CFrame = R.CFrame.new(n == "LeftFoot" and -0.5 or 0.5, 0.2, 0)
	end
	rawset(hum, "RootPart", root)
	char.PrimaryPart = root
	return char, hum, head
end

local ok, err = pcall(function()
	local char, hum = rig(5)
	local h = PS._measure(char, hum)
	assert(math.abs(h - 5) < 0.05, "measured from the head and feet: " .. tostring(h))
	-- a stale head found at spawn no longer matters: the one there now is measured
	local char2, hum2, head2 = rig(5)
	local stale = head2
	stale.Name = "OldHead"
	local fresh = H.Instance.new("Part", char2); fresh.Name = "Head"; fresh.Size = V(1.2, 1.2, 1.2); fresh.CFrame = R.CFrame.new(0, 4.4, 0)
	stale.CFrame = R.CFrame.new(0, 1, 0)
	assert(math.abs(PS._measure(char2, hum2) - 5) < 0.05, "the current head, not the stale one")
	-- the scale: up to 5.6, never more than x1.2, and a nonsense height does nothing
	local function scaled(height)
		local c, hm = rig(height)
		local player = { HasAppearanceLoaded = function() return true end, Character = c }
		PS._normalizeHeight(player, c, hm)
		return c:GetScale()
	end
	local s5 = scaled(5)
	assert(math.abs(s5 - 1.12) < 0.02, "a 5-stud avatar to 5.6: x" .. s5)
	assert(math.abs(scaled(3.9) - 1.2) < 0.01, "short avatars: x1.2 at most")
	assert(scaled(6.5) == 1, "tall avatars stay as they are")
	assert(scaled(1.5) == 1, "a nonsense measurement scales nobody")
	print(("heights: 5 -> x%.2f, 3.9 -> x%.2f"):format(s5, scaled(3.9)))
end)
print(ok and "HEIGHT OK" or ("HEIGHT FAIL: " .. tostring(err)))
