--[[
	World — builds (and rebuilds) the whole level into workspace.World.
	World.build() -> refs, World.destroy(), World.folder(), World.refs(), World.signs()
]]

local House = require(script.Parent.House)
local Interior = require(script.Parent.Interior)
local Dress = require(script.Parent.Dress)
local Finish = require(script.Parent.Finish)
local Exterior = require(script.Parent.Exterior)
local Neighborhood = require(script.Parent.Neighborhood)
local Burrow = require(script.Parent.Burrow)
local Depth = require(script.Parent.Depth)
local Props = require(script.Parent.Props)
local Signs = require(script.Parent.Signs)

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
	Finish.build(ctx, f)
	Interior.build(ctx, f, refs)
	-- the lived-in layer: laundry, posters, toasters, toys
	refs.Dressing = Dress.build(ctx, f)
	Exterior.build(ctx, f, refs)
	Neighborhood.build(ctx, f)
	-- under it all: what he dug (the secret ending, FinaleService)
	refs.Burrow = Burrow.build(ctx, f)
	-- Halloween: tonight's candies (only during the event)
	if ctx.Halloween then
		ctx.Halloween.place(f)
	end
	-- last: pull apart any surfaces that would flicker against each other
	Depth.resolve(f)
	-- nicer Creator Store models for the small props, loaded in the background
	Props.watch(f)
	-- objective markers for doors
	for _, door in ctx.Doors.all() do
		ctx.Objectives.setTarget("Door_" .. door.Id, door.Position)
	end
	return refs
end

function World.destroy()
	if folder then
		folder:Destroy()
		folder = nil
	end
	refs = {}
end

-- the blackout: his wet footprints from the attic hatch along the upstairs hall (Signs)
function World.signs()
	if folder and not folder:FindFirstChild("Footprints") then
		Signs.footprints(folder)
	end
end

function World.folder(): Folder
	return folder :: Folder
end

function World.refs()
	return refs
end

return World
