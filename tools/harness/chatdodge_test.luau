-- chatdodge_test (v164): Roblox's chat window opening at the top left pushes what's under it down to just below it, and closing
-- it brings it back; things not under the window (the right side) stay put.
local H = require("./env")
local R = H.roblox
local ok, err = pcall(function()
	local CD = H.load("Client/Controllers/ChatDodge")
	local ctx: any = { UI = { Scale = 1, tween = function(g, _, props) for k, v in props do g[k] = v end end } }
	CD.init(ctx)
	local function fake(x, y, w)
		return { Parent = true, Position = R.UDim2.fromOffset(x, y), AbsolutePosition = R.Vector2.new(x, y), AbsoluteSize = R.Vector2.new(w, 40) }
	end
	local left, right = fake(18, 37, 120), fake(700, 37, 120)
	CD.register(left :: any)
	CD.register(right :: any)
	CD.refresh(false, nil, true)
	assert(left.Position.Y.Offset == 37 and right.Position.Y.Offset == 37, "closed: nothing moves")
	CD.refresh(true, { 0, 340, 230 }, true)
	assert(left.Position.Y.Offset == 238, "open: the left column slides under the window: " .. left.Position.Y.Offset)
	assert(right.Position.Y.Offset == 37, "the right side stays")
	assert(CD.offsetFor(left :: any, 37) == 201, "offsetFor: the push for things placed every frame")
	CD.refresh(true, { 0, 340, 120 }, true)
	assert(left.Position.Y.Offset == 128, "a shorter window: less push")
	CD.refresh(false, nil, true)
	assert(left.Position.Y.Offset == 37 and CD.offsetFor(left :: any, 37) == 0, "closed again: back up")
	-- (v165) "right": beside the window, not under it (the lobby's PLAY: down would be the thumbstick)
	local menu = fake(16, 35, 136)
	CD.register(menu :: any, "right")
	CD.refresh(true, { 0, 340, 230 }, true)
	assert(menu.Position.X.Offset == 348 and menu.Position.Y.Offset == 35, "beside the chat window: " .. tostring(menu.Position))
	CD.refresh(false, nil, true)
	assert(menu.Position.X.Offset == 16, "back where it was")
end)
print(ok and "CHATDODGE OK" or ("CHATDODGE FAIL: " .. tostring(err)))
