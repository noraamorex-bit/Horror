-- actpose_test (v147): the player action poses. Every prompt in the house maps to a pose (or is
-- meant to have none: Hide, Sit); the arm IK puts the wrist where it's asked (or as near as the arm
-- reaches); every kind gives finite joint transforms at any time, first person too; first-person
-- hands are in front of the eye (on screen), third-person brushing is at the mouth.
local H = require("./env")
local R = H.roblox
local V = R.Vector3.new
local AP = H.load("RS/Shared/ActPose")
local ok, err = pcall(function()
	-- 1) the house's prompts
	local actions = { "Look", "Open", "Search", "Inspect", "Cut free", "Turn on", "Take", "Take firewood", "Splice the wires", "Smash window", "Search the cushions", "Read", "Put down popcorn", "Push the hatch", "Pull", "Pull release & heave", "Press", "Pick up", "Make popcorn", "Light the fire", "Light switch", "Knock", "Flip MAIN breaker", "Enter code", "Drive", "Close window", "Call 911", "Brush your teeth", "Bar the door", "Answer the door", "Order pizza", "Unlock", "Lock", "Close", "Climb through" }
	local missing = {}
	for _, a in actions do
		if not AP.kindFor(a) and a ~= "Climb through" then table.insert(missing, a) end
	end
	assert(#missing == 0, "no pose for: " .. table.concat(missing, ", "))
	assert(AP.kindFor("Hide") == nil and AP.kindFor("Sit") == nil, "hiding and sitting have their own")
	assert(AP.kindFor("Brush your teeth") == "Brush" and AP.kindFor("Call 911") == "Call" and AP.kindFor("Unlock") == "Press", "mapping")
	-- 2) IK reaches
	local rig = AP.StandardRig
	for _, tgt in { V(0.3, 1.0, -0.6), V(0.4, -0.5, -1.4), V(1.4, -0.7, -0.5), V(0.2, 0.2, -0.9), V(0.3, -0.45, 0.6) } do
		local tr = AP.solve(rig, { R = tgt })
		local got = AP.wristOf(rig, "R", tr)
		local s = rig.RS.C0.Position
		local reach = (rig.RE.C0.Position - rig.RS.C1.Position).Magnitude + (rig.RW.C0.Position - rig.RE.C1.Position).Magnitude
		if (tgt - s).Magnitude <= reach - 0.05 then
			assert((got - tgt).Magnitude < 0.05, ("IK to %s: got %s"):format(tostring(tgt), tostring(got)))
		else
			-- out of reach: the arm points at it
			local ang = math.deg(math.acos(math.clamp((got - s).Unit:Dot((tgt - s).Unit), -1, 1)))
			assert(ang < 8, ("IK out of reach to %s: points %.1f deg off"):format(tostring(tgt), ang))
		end
		local want = got
		-- left mirrored
		local trL = AP.solve(rig, { L = V(-tgt.X, tgt.Y, tgt.Z) })
		local gotL = AP.wristOf(rig, "L", trL)
		assert((gotL - V(-want.X, want.Y, want.Z)).Magnitude < 0.05, "left arm IK mirrors the right: " .. tostring(gotL))
	end
	-- the elbow goes out and down, not up through the chest
	do
		local tr = AP.solve(rig, { R = V(0.25, 1.0, -0.6) })
		local upper = rig.RS.C0 * tr.RightShoulder * rig.RS.C1:Inverse()
		local elbow = (upper * rig.RE.C0).Position
		local wrist = AP.wristOf(rig, "R", tr)
		assert(elbow.Y < wrist.Y - 0.2 and (elbow.Z < -0.4 or elbow.X > 1.0), "brushing: the elbow below the hand, in front or out to the side (not through the chest): " .. tostring(elbow))
	end
	-- 3) every kind, every moment
	local eye = V(0, 1.3, 0)
	local offscreen = {}
	for kind, def in AP.Kinds do
		for _, fp in { false, true } do
			for _, t in { 0, 0.13, 0.5, 1, 1.7, 3 } do
				local tg = AP.targets(kind, t, fp)
				assert(tg, kind .. ": targets")
				local tr = AP.solve(rig, tg)
				for j, cf in tr do
					local p = cf.Position
					local _, _, _, r00 = cf:GetComponents()
					assert(p.X == p.X and r00 == r00, kind .. " " .. j .. ": NaN")
				end
			end
		end
		-- first person: the hand(s) in front of the eye at the peak of the move
		local tg = AP.targets(kind, def.Hold and 0.5 or def.Time * 0.5, true)
		if kind ~= "Tied" and kind ~= "Call" then
			local tr = AP.solve(rig, tg)
			local side = tg.R and "R" or "L"
			local w = AP.wristOf(rig, side, tr)
			local rel = w - eye
			local fwd = -rel.Z
			assert(fwd > 0.55, ("%s first person: the hand is in front of the eye (%.2f)"):format(kind, fwd))
			local vang = math.deg(math.atan2(math.abs(rel.Y), fwd))
			local hang = math.deg(math.atan2(math.abs(rel.X), fwd))
			print(("%-8s fp hand fwd %.2f  down %.2f  side %.2f  (%.0f deg vertical, %.0f horizontal)"):format(kind, fwd, -rel.Y, rel.X, vang, hang))
			if not (vang < 30 and hang < 45) then
				table.insert(offscreen, kind)
			end
		end
	end
	assert(#offscreen == 0, "first-person hands off screen: " .. table.concat(offscreen, ", "))
	-- brushing (third person): the brush hand by the mouth
	local tr = AP.solve(rig, AP.targets("Brush", 0.5, false))
	local w = AP.wristOf(rig, "R", tr)
	local mouth = V(0, 1.15, -0.55)
	assert((w - mouth).Magnitude < 0.6, "the brush hand at the mouth: " .. tostring(w))
end)
print(ok and "OK actpose_test" or ("FAIL " .. tostring(err)))
