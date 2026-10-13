-- props_test: Creator Store furniture goes where our own was (World/Props fit()).
-- A model built facing +Z with "Yaw = 180" ends up facing the way the placeholder faces; it's
-- scaled into the placeholder's box and stands on its base; "Back = true" lines a deeper model's
-- back up with the placeholder's back (it reaches into the room, not into the wall); the
-- placeholder's own parts go invisible (prompts and collisions stay); a "PropKey" picks the model.
local H = require("./env")
local R = H.roblox
local ok, err = pcall(function()
	H.realModels = true
	-- the "store": a chair built facing +Z (its back panel on the -Z side), far from the origin
	local function storeChair()
		local box = R.Instance.new("Model")
		local m = R.Instance.new("Model"); m.Name = "StoreChair"; m.Parent = box
		local seat = R.Instance.new("Part"); seat.Name = "StoreSeat"; seat.Size = R.Vector3.new(2, 0.4, 2); seat.CFrame = R.CFrame.new(100, 1.2, 50); seat.Parent = m
		local back = R.Instance.new("Part"); back.Name = "StoreBack"; back.Size = R.Vector3.new(2, 3, 0.2); back.CFrame = R.CFrame.new(100, 2.9, 49.1); back.Parent = m
		local leg = R.Instance.new("Part"); leg.Name = "StoreLeg"; leg.Size = R.Vector3.new(2, 1, 2); leg.CFrame = R.CFrame.new(100, 0.5, 50); leg.Parent = m
		local junk = R.Instance.new("Script"); junk.Parent = m
		return box
	end
	-- a bookcase twice as deep as ours, built facing -Z
	local function storeShelf()
		local box = R.Instance.new("Model")
		local m = R.Instance.new("Model"); m.Parent = box
		local body = R.Instance.new("Part"); body.Name = "ShelfBody"; body.Size = R.Vector3.new(6, 9, 2.4); body.CFrame = R.CFrame.new(-40, 4.5, 0); body.Parent = m
		return box
	end
	local loads = {}
	H.services.AssetService = { LoadAssetAsync = function(_, id)
		table.insert(loads, id)
		if id == 1 then return H.wrap(storeChair()) end
		if id == 2 then return H.wrap(storeShelf()) end
		error("no such asset")
	end }
	local Props = H.load("Server/World/Props")
	Props.Models = {
		DiningChair = { Id = 1, Yaw = 180 },
		Bookcase = { Id = 2, Yaw = 0, Fit = "width", Back = true },
		Broken = { Id = 99 },
	}
	local Kit = H.load("Server/World/Kit")
	local root = H.Instance.new("Folder", H.workspaceRoot)
	-- a dining chair at (10, 0, 5) facing +X (towards a table on its +X side)
	-- (Angles, not lookAt: lune's lookAt flips frames looking straight along an axis)
	local face = R.CFrame.new(10, 0, 5) * R.CFrame.Angles(0, -math.pi / 2, 0)
	local chair = Kit.chair(root, face, R.Color3.new(0.5, 0.4, 0.3))
	chair:SetAttribute("PropKey", "DiningChair")
	-- a bookcase against a wall at z = -10.6, facing +Z into the room
	local shelfAt = R.CFrame.new(0, 0, -10) * R.CFrame.Angles(0, math.pi, 0)
	local shelf = Kit.bookcase(root, shelfAt, 6, 1.2, 8.5, 4)
	-- one that won't load: stays as it was
	local other = Kit.chair(root, R.CFrame.new(-20, 0, 0))
	other:SetAttribute("PropKey", "Broken")
	-- (our bookcase's own box, in its frame: what the store one must match)
	local shelfFrame = R.CFrame.new(shelfAt.Position) * R.CFrame.Angles(0, math.atan2(-shelfAt.LookVector.X, -shelfAt.LookVector.Z), 0)
	local smn, smx = Props._localBox(H.unwrap(shelf), shelfFrame)
	Props.watch(root)
	H.flush = H.flush or function() end
	(H.task or require("@lune/task")).wait(0.2)

	local function find(model, name)
		for _, d in H.unwrap(model):GetDescendants() do
			if d.Name == name then return d end
		end
		return nil
	end
	-- the chair
	local seat, back, leg = find(chair, "StoreSeat"), find(chair, "StoreBack"), find(chair, "StoreLeg")
	assert(seat and back and leg, "the store chair is in the placeholder")
	assert(H.unwrap(chair):GetAttribute("PropSwapped") == true, "marked swapped")
	assert(back.CFrame.Position.X < seat.CFrame.Position.X - 0.3, ("its back is on the side away from the table (back x %.2f, seat x %.2f)"):format(back.CFrame.Position.X, seat.CFrame.Position.X))
	assert(math.abs(back.CFrame.Position.Z - seat.CFrame.Position.Z) < 0.05, "turned square, not askew")
	assert(math.abs(seat.CFrame.Position.X - 10) < 1.5 and math.abs(seat.CFrame.Position.Z - 5) < 1.5, "where our chair was")
	local bottom = leg.CFrame.Position.Y - leg.Size.Y / 2
	assert(math.abs(bottom - 0) < 0.05, ("standing on the floor (bottom at %.2f)"):format(bottom))
	assert(not H.unwrap(chair):FindFirstChildWhichIsA("Script", true), "scripts stripped")
	for _, d in H.unwrap(chair):GetChildren() do
		if d:IsA("BasePart") then assert(d.Transparency == 1, "our own parts hidden: " .. d.Name) end
	end
	print("chair turned, placed, scaled ok")
	-- the bookcase: as wide as ours, its back on our back
	local body = find(shelf, "ShelfBody")
	assert(body, "the store shelf is in")
	assert(math.abs(body.Size.X - (smx.X - smn.X)) < 0.05, ("as wide as ours (%.2f vs %.2f)"):format(body.Size.X, smx.X - smn.X))
	-- (the frame faces +Z, so its local +Z, the back, is world -Z)
	local ourBack = shelfFrame:PointToWorldSpace(R.Vector3.new(0, 0, smx.Z)).Z
	local backZ = body.CFrame.Position.Z - body.Size.Z / 2
	assert(math.abs(backZ - ourBack) < 0.05, ("its back on our back, not through the wall (%.2f vs %.2f)"):format(backZ, ourBack))
	assert(body.Size.Z > smx.Z - smn.Z + 0.5, "it's deeper than ours: it reaches into the room")
	print("bookcase against the wall ok")
	-- the one that failed to load is untouched
	assert(H.unwrap(other):GetAttribute("PropSwapped") == nil, "a model that won't load leaves ours in place")
	for _, d in H.unwrap(other):GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "Collider" and d.Name ~= "ChairBlock" then assert(d.Transparency < 1, "still visible: " .. d.Name) end
	end
	print("load failure ok")
	H.realModels = false
end)
print(ok and "PROPS OK" or ("PROPS FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
