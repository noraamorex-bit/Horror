--[[
	TesterService (v163, the owner: "I wanna give my friends all gamepasses and the same admin panel I have so they can test for
	issues"). Testers get the owner's full admin panel (every tab, the lobby's too) and every game pass switched on for them (attributes
	only: nothing is bought or saved as owned). Only the owner adds or removes testers, from the admin panel's TESTERS tab, by username;
	the list is saved (DataStore Testers_v1) so it works in every server, and `Config.Testers` can hold fixed UserIds too.

	What stays the owner's alone: managing testers, being off-limits to trolls and the glove's slap. Testers are kept off the public
	boards (their nights use god mode and free coins).

		Testers.isOwner(player)       -- Config.Admins, the experience's creator, or Studio
		Testers.is(player) / isId(id) -- on the list
		Testers.add(name) -> ok, text  /  Testers.remove(idOrName) -> ok, text  /  Testers.list() -> { {Id, Name} }
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local Testers = {}
local ctx

local KEY = "list"
local store = nil
local list: { [string]: string } = {} -- [tostring(userId)] = name
local loadedAt = -1e9
local listeners: { (Player, boolean) -> () } = {}

function Testers.isOwner(player: Player): boolean
	if not player then
		return false
	end
	if table.find(ctx.Config.Admins or {}, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 and player.UserId == game.CreatorId then
		return true
	end
	return RunService:IsStudio()
end

function Testers.isId(userId: number): boolean
	return list[tostring(userId)] ~= nil or table.find(ctx.Config.Testers or {}, userId) ~= nil
end

function Testers.is(player: Player): boolean
	return player ~= nil and Testers.isId(player.UserId)
end

-- someone becomes / stops being a tester in this server: fn(player, on)
function Testers.onChanged(fn: (Player, boolean) -> ())
	table.insert(listeners, fn)
end

local function apply(p: Player)
	local on = Testers.is(p) and not Testers.isOwner(p)
	if (p:GetAttribute("IsTester") == true) == on then
		return
	end
	p:SetAttribute("IsTester", on or nil)
	for _, fn in listeners do
		task.spawn(fn, p, on)
	end
end
Testers._apply = apply

local function load(force: boolean?)
	if not store or (not force and os.clock() - loadedAt < 20) then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync(KEY)
	end)
	if ok then
		loadedAt = os.clock()
		list = type(data) == "table" and data or {}
	end
end

local function applyAll()
	for _, p in Players:GetPlayers() do
		apply(p)
	end
end

function Testers.list(): { { Id: number, Name: string } }
	local out = {}
	for id, name in list do
		table.insert(out, { Id = tonumber(id) :: number, Name = name })
	end
	for _, id in ctx.Config.Testers or {} do
		if not list[tostring(id)] then
			table.insert(out, { Id = id, Name = "(Config) " .. id })
		end
	end
	table.sort(out, function(a, b)
		return string.lower(a.Name) < string.lower(b.Name)
	end)
	return out
end

local function save(change: (any) -> any): boolean
	if not store then
		-- (Studio without API access / the tests: this server only)
		list = change(list) or list
		return true
	end
	local ok = pcall(function()
		store:UpdateAsync(KEY, function(old)
			return change(type(old) == "table" and old or {})
		end)
	end)
	if ok then
		load(true)
	end
	return ok
end

-- a username (or a UserId) -> id, name
local function resolve(text: string): (number?, string?)
	text = string.gsub(text or "", "^%s*@?(.-)%s*$", "%1")
	if text == "" then
		return nil, nil
	end
	local id = tonumber(text)
	if id then
		local here = Players:GetPlayerByUserId(id)
		if here then
			return id, here.Name
		end
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(id)
		end)
		return id, ok and name or tostring(id)
	end
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == string.lower(text) or string.lower(p.DisplayName) == string.lower(text) then
			return p.UserId, p.Name
		end
	end
	local ok, uid = pcall(function()
		return Players:GetUserIdFromNameAsync(text)
	end)
	if ok and uid then
		return uid, text
	end
	return nil, nil
end
Testers._resolve = resolve

function Testers.add(text: string): (boolean, string)
	local id, name = resolve(text)
	if not id then
		return false, "No Roblox user called \"" .. tostring(text) .. "\"."
	end
	if table.find(ctx.Config.Admins or {}, id) then
		return false, "That's you."
	end
	local ok = save(function(t)
		t[tostring(id)] = name
		return t
	end)
	if not ok then
		return false, "Couldn't save (try again)."
	end
	applyAll()
	return true, "✅ " .. tostring(name) .. " is a tester: full admin panel + every pass, in any server they join."
end

function Testers.remove(text: string): (boolean, string)
	local id = tonumber(text)
	local name = id and list[tostring(id)]
	if not id then
		local rid, rname = resolve(text)
		id, name = rid, rname
	end
	if not id or not list[tostring(id)] then
		if id and table.find(ctx.Config.Testers or {}, id) then
			return false, "That one is in Config.Testers (remove it there)."
		end
		return false, "Not a tester."
	end
	name = list[tostring(id)]
	local ok = save(function(t)
		t[tostring(id)] = nil
		return t
	end)
	if not ok then
		return false, "Couldn't save (try again)."
	end
	applyAll()
	return true, "Removed " .. tostring(name) .. " (their passes go back to what they own)."
end

function Testers.init(c)
	ctx = c
	ctx.Testers = Testers
end

function Testers.start()
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("Testers_v1")
	end)
	store = ok and ds or nil
	load(true)
	local function added(p: Player)
		task.spawn(function()
			load()
			apply(p)
		end)
	end
	for _, p in Players:GetPlayers() do
		added(p)
	end
	Players.PlayerAdded:Connect(added)
end

return Testers
