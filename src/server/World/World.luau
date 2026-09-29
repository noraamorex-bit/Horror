--[[
	World — builds (and rebuilds) the whole level into workspace.World.
	World.build() -> refs, World.destroy(), World.folder(), World.refs()
]]

local House = require(script.Parent.House)
local Interior = require(script.Parent.Interior)
local Exterior = require(script.Parent.Exterior)

local World = {}
local ctx
local folder: Folder? = nil
local refs = {}

function World.init(c)
	ctx = c
end

function World.build()
	World.destroy()
	local f = Instance.new("Folder")
	f.Name = "World"
	f.Parent = workspace
	folder = f
	refs = House.build(ctx, f)
	Interior.build(ctx, f, refs)
	Exterior.build(ctx, f, refs)
	return refs
end

function World.destroy()
	if folder then
		folder:Destroy()
		folder = nil
	end
	refs = {}
end

function World.folder(): Folder
	return folder :: Folder
end

function World.refs()
	return refs
end

return World
