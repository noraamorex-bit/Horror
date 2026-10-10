--[[
	ObjectiveService — the group's shared tasks, each made of steps (Story.Tasks).

	Objectives.set(ids, optional?)       replace the list (acts)
	Objectives.add(id, optional?)
	Objectives.step(id, key)             tick one step off (any order); the task completes when all are done
	Objectives.complete(id)              finish a task outright
	Objectives.setTarget(name, position) where a step's "!" marker goes (registered by the world build)

	Clients get, per task: title, steps, the current step and its marker positions.
]]

local Players = game:GetService("Players")

local Objectives = {}
local ctx
local list = {} -- ordered { {Id, Text, Done, Optional, Steps = { {Key, Text, Target, Done} }} }
local targets: { [string]: Vector3 } = {}

function Objectives.init(c)
	ctx = c
end

function Objectives.setTarget(name: string, position: Vector3)
	targets[name] = position
end

local function resolveTargets(target): { Vector3 }
	local out = {}
	if type(target) == "string" then
		target = { target }
	end
	for _, name in target or {} do
		if targets[name] then
			table.insert(out, targets[name])
		end
	end
	return out
end

local function currentStep(o)
	for i, s in o.Steps do
		if not s.Done then
			return s, i
		end
	end
	return nil, #o.Steps
end

local function payload()
	local out = {}
	for _, o in list do
		local steps = {}
		local doneCount = 0
		for _, s in o.Steps do
			table.insert(steps, { Text = s.Text, Done = s.Done })
			if s.Done then
				doneCount += 1
			end
		end
		local cur = currentStep(o)
		table.insert(out, {
			Id = o.Id,
			Text = o.Text,
			Done = o.Done,
			Optional = o.Optional,
			Steps = steps,
			StepsDone = doneCount,
			Current = (not o.Done and cur) and cur.Text or nil,
			Targets = (not o.Done and cur) and resolveTargets(cur.Target) or (not o.Done and resolveTargets(o.Target) or {}),
		})
	end
	return out
end

local function broadcast()
	ctx.Remotes.Objectives:FireAllClients(payload())
end

local function make(id: string, optional: boolean?)
	local def = ctx.Story.Tasks[id] or {}
	local steps = {}
	for _, s in def.Steps or {} do
		table.insert(steps, { Key = s.Key, Text = s.Text, Target = s.Target, Done = false })
	end
	return {
		Id = id,
		Text = def.Title or ctx.Story.Objectives[id] or id,
		Done = false,
		Optional = optional or false,
		Steps = steps,
		Target = def.Target,
	}
end

-- a marker that's no longer needed (a note already read): gone from everyone's screen
function Objectives.clearTarget(name: string)
	if targets[name] then
		targets[name] = nil
		broadcast()
	end
end

function Objectives.set(ids: { string }, optional: { [string]: boolean }?)
	list = {}
	for _, id in ids do
		table.insert(list, make(id, optional and optional[id] or false))
	end
	broadcast()
end

function Objectives.add(id: string, optional: boolean?)
	for _, o in list do
		if o.Id == id then
			return
		end
	end
	local o = make(id, optional)
	table.insert(list, o)
	broadcast()
	ctx.Remotes.Notify:FireAllClients("New objective: " .. o.Text, "objective")
end

local function find(id: string)
	for _, o in list do
		if o.Id == id then
			return o
		end
	end
	return nil
end

function Objectives.complete(id: string): boolean
	local o = find(id)
	if not o or o.Done then
		return false
	end
	o.Done = true
	for _, s in o.Steps do
		s.Done = true
	end
	broadcast()
	ctx.Remotes.Notify:FireAllClients("Done: " .. o.Text, "done")
	if ctx.Director and ctx.Director.onObjectiveDone then
		ctx.Director.onObjectiveDone()
	end
	return true
end

function Objectives.step(id: string, key: string): boolean
	local o = find(id)
	if not o or o.Done then
		return false
	end
	for _, s in o.Steps do
		if s.Key == key and not s.Done then
			s.Done = true
			local all = true
			for _, t in o.Steps do
				if not t.Done then
					all = false
				end
			end
			if all then
				Objectives.complete(id)
			else
				broadcast()
				if ctx.Director and ctx.Director.onObjectiveDone then
					ctx.Director.onObjectiveDone()
				end
			end
			return true
		end
	end
	return false
end

-- drop a task quietly (it no longer applies)
function Objectives.dismiss(id: string)
	for i, o in list do
		if o.Id == id and not o.Done then
			table.remove(list, i)
			broadcast()
			return
		end
	end
end

function Objectives.isStepDone(id: string, key: string): boolean
	local o = find(id)
	if not o then
		return false
	end
	if o.Done then
		return true
	end
	for _, s in o.Steps do
		if s.Key == key then
			return s.Done
		end
	end
	return false
end

-- ids still to do: required ones first, then optional
function Objectives.pending(): { string }
	local out = {}
	for _, o in list do
		if not o.Done and not o.Optional then
			table.insert(out, o.Id)
		end
	end
	for _, o in list do
		if not o.Done and o.Optional then
			table.insert(out, o.Id)
		end
	end
	return out
end

-- the current step's text for an objective (for thoughts)
function Objectives.currentText(id: string): string?
	local o = find(id)
	if not o or o.Done then
		return nil
	end
	local s = currentStep(o)
	return s and s.Text or nil
end

function Objectives.isDone(id: string): boolean
	local o = find(id)
	return o ~= nil and o.Done
end

function Objectives.has(id: string): boolean
	return find(id) ~= nil
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
	targets = {}
	broadcast()
end

function Objectives.start()
	Players.PlayerAdded:Connect(function(p)
		task.wait(2)
		ctx.Remotes.Objectives:FireClient(p, payload())
	end)
end

return Objectives
