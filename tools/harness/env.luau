-- A tiny Roblox runtime shim on top of @lune/roblox, for smoke-testing module code.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local REPO = "/home/user/Horror/"
local M = {}
M.errors = {}
M.renderSteps = {}

-- Lune's CFrame.lookAt flips a model 180 degrees when looking straight down -Z; Roblox doesn't.
M.CFrame = setmetatable({
	lookAt = function(at, target, up)
		up = up or roblox.Vector3.new(0, 1, 0)
		local look = (target - at).Unit
		local right = look:Cross(up)
		if right.Magnitude < 1e-5 then
			right = roblox.Vector3.new(1, 0, 0)
		end
		right = right.Unit
		local up2 = right:Cross(look)
		return roblox.CFrame.fromMatrix(at, right, up2, -look)
	end,
}, { __index = roblox.CFrame })

-- a seeded Random so builds are reproducible
M.Random = { new = function(seed)
	local state = math.floor(math.abs(seed or os.clock() * 1e6)) % 2147483646 + 1
	local function nextf()
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
	return {
		NextNumber = function(_, a, b) a = a or 0; b = b or 1; return a + nextf() * (b - a) end,
		NextInteger = function(_, a, b) return a + math.floor(nextf() * (b - a + 1)) end,
	}
end }

local realOf = setmetatable({}, { __mode = "k" })
local proxyOf = {}

local function signal()
	local s = { fns = {} }
	function s:Connect(fn)
		table.insert(s.fns, fn)
		return { Disconnect = function() end, Connected = true }
	end
	function s:Fire(...)
		for _, fn in s.fns do fn(...) end
	end
	s.Once = s.Connect
	function s:Wait() return nil end
	return s
end

local SIGNALS = {
	Triggered = true, PromptButtonHoldBegan = true, PromptButtonHoldEnded = true, PromptShown = true, PromptHidden = true,
	Changed = true, Completed = true, Activated = true, InputBegan = true, InputEnded = true, InputChanged = true,
	AncestryChanged = true, MouseButton1Click = true, Touched = true, OnServerEvent = true, OnClientEvent = true,
	LastInputTypeChanged = true, AttributeChanged = true, CharacterAdded = true, DescendantAdded = true, PromptShown = true, PromptHidden = true,
}

local wrap, unwrap

local function unwrapAll(...)
	local t = table.pack(...)
	for i = 1, t.n do t[i] = unwrap(t[i]) end
	return table.unpack(t, 1, t.n)
end
local function wrapAll(...)
	local t = table.pack(...)
	for i = 1, t.n do t[i] = wrap(t[i]) end
	return table.unpack(t, 1, t.n)
end

local EXTRA = {}
function EXTRA.PivotTo(self, cf) if M.onPivotTo then M.onPivotTo(self, cf) end end
function EXTRA.GetPivot(self) return roblox.CFrame.new() end
function EXTRA.SetNetworkOwner() end
function EXTRA.GetPropertyChangedSignal() return signal() end
function EXTRA.GetAttributeChangedSignal() return signal() end
function EXTRA.Play() end
function EXTRA.Stop() end
function EXTRA.InputHoldBegin() end
function EXTRA.InputHoldEnd() end
function EXTRA.LoadCharacter() end
function EXTRA.WaitForChild(self, name) return self:FindFirstChild(name) end
function EXTRA.Destroy() end
function EXTRA.SetStateEnabled() end
function EXTRA.SetTeleportData() end
function EXTRA.MoveTo(self, pos) if M.onMoveTo then M.onMoveTo(self, pos) end end
function EXTRA.LoadAnimation() return { Play = function() end, Stop = function() end, AdjustSpeed = function() end, Looped = true } end

local meta = {}
meta.__index = function(p, k)
	local real = realOf[p]
	if k == "AssemblyLinearVelocity" and M.velocityOf then
		local v = M.velocityOf(p)
		if v then return v end
	end
	local ok, v = pcall(function() return real[k] end)
	if ok then
		if type(v) == "function" then
			return function(_, ...) return wrapAll(v(real, unwrapAll(...))) end
		end
		return wrap(v)
	end
	if SIGNALS[k] then
		local sigs = rawget(p, "__signals") or {}
		rawset(p, "__signals", sigs)
		sigs[k] = sigs[k] or signal()
		return sigs[k]
	end
	if EXTRA[k] then return EXTRA[k] end
	if k == "Position" and real:IsA("BasePart") then return real.CFrame.Position end
	if k == "UserId" then return 1 end
	if k == "IsPlaying" then return false end
	if k == "DisplayName" then return real.Name end
	if k == "Orientation" or k == "AssemblyLinearVelocity" or k == "MoveDirection" then return roblox.Vector3.new() end
	if k == "AbsoluteSize" or k == "AbsolutePosition" then return roblox.Vector2.new(100, 100) end
	error(tostring(v), 2)
end
meta.__newindex = function(p, k, v)
	local real = realOf[p]
	if k == "Position" and real:IsA("BasePart") then
		real.CFrame = roblox.CFrame.new(v)
		return
	end
	if k == "UserId" then return 1 end
	if k == "IsPlaying" then return false end
	if k == "DisplayName" then return real.Name end
	if k == "Orientation" or k == "Modal" and false then return end
	local ok, err = pcall(function() real[k] = unwrap(v) end)
	if not ok then
		local msg = tostring(err)
		-- engine-computed props we can't set in lune but are fine in Roblox
		if msg:find("missing default value") then return end
		error(real.ClassName .. "." .. tostring(k) .. ": " .. msg, 2)
	end
end
meta.__tostring = function(p) return "Proxy<" .. realOf[p].ClassName .. ">" end
meta.__eq = function(a, b) return realOf[a] == realOf[b] end

local nextPid = 0
local byPid = {}
function wrap(v)
	if typeof(v) == "Instance" then
		-- lune returns a fresh userdata per access, so identify instances by a tag attribute
		local ok, pid = pcall(function() return v:GetAttribute("__pid") end)
		pid = ok and pid or nil
		if pid and byPid[pid] then
			return byPid[pid]
		end
		nextPid += 1
		pcall(function() v:SetAttribute("__pid", nextPid) end)
		local p = setmetatable({}, meta)
		realOf[p] = v
		byPid[nextPid] = p
		return p
	elseif type(v) == "table" and getmetatable(v) == nil then
		local out = {}
		for i, x in v do out[i] = wrap(x) end
		return out
	end
	return v
end

local wsRef
function unwrap(v)
	if type(v) == "table" and realOf[v] then return realOf[v] end
	if v ~= nil and v == wsRef then return realOf[M.workspaceRoot] end
	return v
end

M.wrap, M.unwrap = wrap, unwrap

local Instance = {
	new = function(className, parent)
		local ok, inst = pcall(roblox.Instance.new, className)
		if not ok then error("Instance.new(" .. className .. "): " .. tostring(inst), 2) end
		if parent then inst.Parent = unwrap(parent) end
		return wrap(inst)
	end,
}

-- task: run spawned functions once, never run delays
local ours = setmetatable({}, { __mode = "k" })
-- Optional real scheduler (M.schedule = true, with M.clock): waits and delays run when
-- M.runDue() is called with the clock advanced.
M.queue = {}
local function now_() return M.clock and M.clock() or os.clock() end
local function resumeCo(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then table.insert(M.errors, "task: " .. tostring(err) .. "\n" .. debug.traceback(co)) end
end
local taskLib = {
	wait = function(s)
		local co = coroutine.running()
		if M.schedule and ours[co] then
			table.insert(M.queue, { At = now_() + (s or 0.03), Co = co })
			coroutine.yield()
			return s or 0.03
		end
		if ours[co] then coroutine.yield() end
		return 0.1
	end,
	spawn = function(fn, ...) local co = coroutine.create(fn); ours[co] = true; resumeCo(co, ...) end,
	defer = function(fn, ...) local co = coroutine.create(fn); ours[co] = true; resumeCo(co, ...) end,
	delay = function(s, fn, ...)
		if M.schedule then
			local args = table.pack(...)
			local co = coroutine.create(function() fn(table.unpack(args, 1, args.n)) end)
			ours[co] = true
			table.insert(M.queue, { At = now_() + (s or 0), Co = co })
		end
	end,
	cancel = function() end,
}
function M.runDue()
	local guard = 0
	while true do
		guard += 1
		if guard > 5000 then break end
		local t = now_()
		local due = nil
		for i, e in M.queue do
			if e.At <= t then due = i break end
		end
		if not due then break end
		local e = table.remove(M.queue, due)
		resumeCo(e.Co)
	end
end

local function stub(name)
	return setmetatable({}, { __index = function(t, k)
		if SIGNALS[k] then return signal() end
		return function() return nil end
	end })
end

local root = wrap(roblox.Instance.new("Folder"))
root.Name = "workspace"
local terrain = Instance.new("Folder", root); terrain.Name = "Terrain"
local ws = setmetatable({ Terrain = terrain }, { __index = function(_, k)
	if k == "SetAttribute" then return function(_, a, b) root:SetAttribute(a, b) end end
	if k == "GetAttribute" then return function(_, a) return root:GetAttribute(a) end end
	if k == "GetServerTimeNow" then return function() return os.clock() end end
	if k == "CurrentCamera" then return M.camera end
	if k == "Raycast" then return function(_, o, d, params) if M.raycast then return M.raycast(o, d, params) end return nil end end
	if k == "GetPartBoundsInBox" then return function(_, cf, size, params) if M.boundsInBox then return M.boundsInBox(cf, size, params) end return {} end end
	if SIGNALS[k] then return signal() end
	return root[k]
end })
M.workspaceRoot = root
wsRef = ws

local services
services = {
	TweenService = { Create = function() return { Play = function() end, Cancel = function() end, Completed = signal() } end },
	Players = { GetPlayers = function() return {} end, PlayerAdded = signal(), PlayerRemoving = signal(), LocalPlayer = nil },
	Debris = { AddItem = function() end },
	RunService = { IsServer = function() return true end, IsClient = function() return false end, Heartbeat = signal(), RenderStepped = signal(), Stepped = signal(), BindToRenderStep = function(_, _, _, fn) table.insert(M.renderSteps, fn) end },
	PathfindingService = stub("PathfindingService"),
	TextChatService = stub("TextChatService"),
	CollectionService = (function()
		local tags = {}
		return {
			AddTag = function(_, inst, tag) tags[tag] = tags[tag] or {}; table.insert(tags[tag], inst) end,
			RemoveTag = function(_, inst, tag) local l = tags[tag]; if l then local i = table.find(l, inst); if i then table.remove(l, i) end end end,
			HasTag = function(_, inst, tag) return tags[tag] ~= nil and table.find(tags[tag], inst) ~= nil end,
			GetTagged = function(_, tag) return table.clone(tags[tag] or {}) end,
			GetInstanceAddedSignal = function() return signal() end,
			GetInstanceRemovedSignal = function() return signal() end,
		}
	end)(),
	Lighting = wrap(roblox.Instance.new("Folder")),
}

local function parentPath(p) return p:match("^(.*)/[^/]+$") end
local function pathNode(path)
	return setmetatable({ __path = path }, { __index = function(t, k)
		if k == "Parent" then return pathNode(parentPath(path)) end
		if k == "WaitForChild" or k == "FindFirstChild" then
			return function(self, name) return pathNode(path .. "/" .. name) end
		end
		return pathNode(path .. "/" .. k)
	end })
end

local fakeGame = { GetService = function(_, name)
	if name == "ReplicatedStorage" then return pathNode("RS") end
	return services[name] or stub(name)
end }

local MAP = {
	["RS/Shared"] = "src/shared",
	["Server"] = "src/server",
	["Client"] = "src/client",
}

local cache = {}
local function fileFor(path)
	for prefix, dir in MAP do
		if path:sub(1, #prefix) == prefix then
			return REPO .. dir .. path:sub(#prefix + 1) .. ".luau"
		end
	end
	error("no file for " .. path)
end

local function parentPath(p) return p:match("^(.*)/[^/]+$") end

function M.load(path)
	if cache[path] then return cache[path] end
	local file = fileFor(path)
	local src = fs.readFile(file)
	local scriptNode = pathNode(path)
	rawset(scriptNode, "Parent", pathNode(parentPath(path)))
	local env = {
		script = scriptNode,
		game = fakeGame,
		workspace = ws,
		Instance = Instance,
		task = taskLib,
		require = function(node) return M.load(node.__path) end,
		warn = function(...) table.insert(M.errors, "warn: " .. table.concat({ ... }, " ")) end,
		RaycastParams = { new = function() return {} end },
		OverlapParams = { new = function() return {} end },
		TweenInfo = { new = function() return {} end },
		Random = M.Random,
		typeof = function(v) if type(v) == "table" and realOf[v] then return "Instance" end return typeof(v) end,
	}
	env.CFrame = M.CFrame
	for _, name in { "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Enum", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint", "NumberRange", "Rect", "BrickColor", "Font", "PhysicalProperties" } do
		env[name] = roblox[name]
	end
	for _, name in { "math", "table", "string", "os", "print", "pairs", "ipairs", "type", "pcall", "xpcall", "error", "setmetatable", "getmetatable", "tostring", "tonumber", "select", "unpack", "rawget", "rawset", "rawequal", "next", "coroutine", "bit32", "utf8", "assert" } do
		env[name] = (_G :: any)[name] or getfenv()[name]
	end
	-- a clock tests can take over (M.clock)
	local realOs = env.os
	env.os = setmetatable({ clock = function() return M.clock and M.clock() or realOs.clock() end }, { __index = realOs })
	local fn = luau.load(src, { debugName = path, environment = env })
	local result = fn()
	cache[path] = result
	return result
end

M.signal = signal
M.ours = ours
M.task = taskLib
M.services = services
M.roblox = roblox
M.Instance = Instance
return M
