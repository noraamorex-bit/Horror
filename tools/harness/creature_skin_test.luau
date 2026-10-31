-- creature_skin_test (v135, the owner's screenshot: him upright in his rest pose with no mask, again): the client
-- keeps a skeleton only while it's still his own (the body, its bones and the mask's neck all still in the model;
-- after streaming out and back in the old one drives nothing); when the skinned body can't be driven, the
-- part-built figure (each hidden part's own transparency, kept by the server as T0) shows instead, the body
-- hidden locally; and back again.
local H = require("./env")
local R = H.roblox
local ok, err = pcall(function()
	local C = H.load("Client/Controllers/Creature")
	local function new(class, name, parent)
		local i = R.Instance.new(class)
		i.Name = name
		if parent then
			i.Parent = parent
		end
		return i
	end
	local m = new("Model", "Curtis")
	local body = new("MeshPart", "Body", m)
	local hips = new("Bone", "spine_66", body)
	local headBone = new("Bone", "spine_006_0", hips)
	local torso = new("Part", "UpperTorso", m)
	torso.Transparency = 1
	torso:SetAttribute("T0", 0)
	local head = new("Part", "Head", m)
	local neck = new("Motor6D", "Neck", head)
	neck.Part0 = torso
	neck.Part1 = head
	local root = new("Part", "HumanoidRootPart", m)
	root.Transparency = 1
	root:SetAttribute("T0", 1)
	local W = function(x)
		return H.wrap(x)
	end
	local rig = { Body = W(body), Joints = { Hips = { Bone = W(hips) } }, Mask = { Neck = W(neck), Bone = W(headBone) } }
	assert(C._skinValid(rig, W(m)) == true, "his own skeleton: valid")
	-- streamed out and back in: a new body (and bones) in the model, the kept rig points at the old one
	body.Parent = nil
	local body2 = new("MeshPart", "Body", m)
	new("Bone", "spine_66", body2)
	assert(C._skinValid(rig, W(m)) == false, "a skeleton from before the body was replaced: not valid")
	body.Parent = m
	body2.Parent = nil
	assert(C._skinValid(rig, W(m)) == true, "back: valid")
	-- the mask's neck replaced
	neck.Parent = nil
	assert(C._skinValid(rig, W(m)) == false, "the mask's neck gone: not valid")
	neck.Parent = head
	-- the fallback: the part-built figure shows (its own transparencies), the body hidden on this device
	C._setFallback(W(m), true)
	assert(torso.Transparency == 0, "the frame's parts show: " .. torso.Transparency)
	assert(root.Transparency == 1, "an invisible part stays invisible")
	local okL, lt = pcall(function()
		return body.LocalTransparencyModifier
	end)
	if okL then
		assert(lt == 1, "the static body hidden: " .. tostring(lt))
	end
	C._setFallback(W(m), false)
	assert(torso.Transparency == 1, "and hidden again when the body can be driven")
	if okL then
		assert(body.LocalTransparencyModifier == 0, "the body back")
	end
	assert(C.status() == nil, "nothing to report before he's been seen")
	print("creature skin: stale skeletons dropped, fallback figure ok")
end)
print(ok and "CREATURESKIN OK" or ("CREATURESKIN FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
