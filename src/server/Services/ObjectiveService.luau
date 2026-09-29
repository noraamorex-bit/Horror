--[[
	ObjectiveService — the group's shared to-do list (shown in the journal / HUD).
]]

local Players = game:GetService("Players")

local Objectives = {}
local ctx
local list = {} -- ordered { {Id, Text, Done, Optional} }

function Objectives.init(c)
	ctx = c
end

local function broadcast()
	local payload = {}
	for _, o in list do
		table.insert(payload, { Id = o.Id, Text = o.Text, Done = o.Done, Optional = o.Optional })
	end
	ctx.Remotes.Objectives:FireAllClients(payload)
end

function Objectives.set(ids: { string }, optional: { [string]: boolean }?)
	list = {}
	for _, id in ids do
		table.insert(list, { Id = id, Text = ctx.Story.Objectives[id] or id, Done = false, Optional = optional and optional[id] or false })
	end
	broadcast()
end

function Objectives.add(id: string, optional: boolean?)
	for _, o in list do
		if o.Id == id then
			return
		end
	end
	table.insert(list, { Id = id, Text = ctx.Story.Objectives[id] or id, Done = false, Optional = optional or false })
	broadcast()
	ctx.Remotes.Notify:FireAllClients("New objective: " .. (ctx.Story.Objectives[id] or id), "objective")
end

function Objectives.complete(id: string): boolean
	for _, o in list do
		if o.Id == id and not o.Done then
			o.Done = true
			broadcast()
			ctx.Remotes.Notify:FireAllClients("Done: " .. o.Text, "done")
			return true
		end
	end
	return false
end

function Objectives.isDone(id: string): boolean
	for _, o in list do
		if o.Id == id then
			return o.Done
		end
	end
	return false
end

function Objectives.has(id: string): boolean
	for _, o in list do
		if o.Id == id then
			return true
		end
	end
	return false
end

function Objectives.allRequiredDone(): boolean
	for _, o in list do
		if not o.Optional and not o.Done then
			return false
		end
	end
	return #list > 0
end

function Objectives.reset()
	list = {}
	broadcast()
end

function Objectives.start()
	Players.PlayerAdded:Connect(function(p)
		task.wait(2)
		local payload = {}
		for _, o in list do
			table.insert(payload, { Id = o.Id, Text = o.Text, Done = o.Done, Optional = o.Optional })
		end
		ctx.Remotes.Objectives:FireClient(p, payload)
	end)
end

return Objectives
