--[[
	Voices — people say their lines out loud (Roblox text-to-speech; v106, the owner: "add text
	to speech to almost everything like when friends talking").

	Voiced: the dialogue box (the delivery man, friends' chatter, the line you or a friend picked),
	your own thoughts (quieter: your inner voice), and him (Remotes.HisVoice: a slowed, deep,
	pitched-down voice with a long reverb, only heard near him). Each speaker has a voice profile
	(Story.Voices: a voice id, pitch and speed); a friend's voice comes from their role.

	Every line is generated once and kept (a few dozen per night). One line at a time per channel
	(a new dialogue line cuts the last one off). The Voices setting scales them all. If speech isn't
	available, everything is simply silent, as before.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Voices = {}
local ctx
local player = Players.LocalPlayer

local MAX_CACHE = 80
local output: Instance? = nil
local cache: { [string]: any } = {} -- profile|text -> loaded AudioTextToSpeech
local order: { string } = {}
local failed: { [string]: boolean } = {}
local playing: { [string]: any } = {} -- channel -> the line playing on it
local available = true

local function profile(key: string?): any
	local V = ctx.Story.Voices
	return (key and V.Profiles[key]) or V.Profiles.Default
end

-- the chain a profile plays through: straight to the speakers, or his effects first
local function chain(tts: Instance, p: any, effects: string?)
	local target: Instance = output :: Instance
	local nodes = {}
	effects = effects or p.Effects
	if effects == "Far" then
		-- (somewhere else in the house: a long room's echo, a little thin)
		pcall(function()
			local reverb = Instance.new("AudioReverb")
			pcall(function()
				reverb.DecayTime = 1.8
				reverb.WetLevel = -2
				reverb.DryLevel = -6
			end)
			local eq = Instance.new("AudioEqualizer")
			pcall(function()
				eq.HighGain = -14
				eq.LowGain = -6
			end)
			nodes = { eq, reverb }
			for _, n in nodes do
				n.Parent = tts
			end
		end)
	elseif effects == "Him" then
		local ok = pcall(function()
			local shift = Instance.new("AudioPitchShifter")
			shift.Pitch = p.Shift or 0.72
			local reverb = Instance.new("AudioReverb")
			pcall(function()
				reverb.DecayTime = 2.6
				reverb.WetLevel = -4
				reverb.DryLevel = -2
			end)
			local dist = Instance.new("AudioDistortion")
			pcall(function()
				dist.Level = 0.18
			end)
			nodes = { shift, dist, reverb }
			for _, n in nodes do
				n.Parent = tts
			end
		end)
		if not ok then
			nodes = {}
		end
	end
	local prev: Instance = tts
	for _, n in nodes do
		local w = Instance.new("Wire")
		w.SourceInstance = prev
		w.TargetInstance = n
		w.Parent = tts
		prev = n
	end
	local w = Instance.new("Wire")
	w.SourceInstance = prev
	w.TargetInstance = target
	w.Parent = tts
end

-- the speech for a line in a voice, generated once (yields while it loads)
local function load(text: string, key: string?, effects: string?): any
	local p = profile(key)
	local id = (key or "Default") .. "|" .. (effects or "") .. "|" .. text
	if cache[id] then
		return cache[id]
	end
	if failed[id] or not output or not available then
		return nil
	end
	local ok, tts = pcall(function()
		local t = Instance.new("AudioTextToSpeech")
		t.Name = "Voice"
		t.Text = string.sub(text, 1, 300)
		t.VoiceId = p.Voice
		pcall(function()
			t.Pitch = p.Pitch or 1
		end)
		pcall(function()
			t.Speed = p.Speed or 1
		end)
		t.Volume = 0
		t.Parent = SoundService
		chain(t, p, effects)
		t:LoadAsync()
		return t
	end)
	if not ok or not tts then
		failed[id] = true
		return nil
	end
	cache[id] = tts
	table.insert(order, id)
	-- (the oldest lines go once there are plenty)
	while #order > MAX_CACHE do
		local old = table.remove(order, 1) :: string
		local t = cache[old]
		cache[old] = nil
		local busy = false
		for _, cur in playing do
			if cur == t then
				busy = true
			end
		end
		if t and not busy then
			t:Destroy()
		end
	end
	return tts
end

function Voices.stop(channel: string)
	local cur = playing[channel]
	playing[channel] = nil
	if cur then
		pcall(function()
			cur:Pause()
		end)
	end
end

local function setting(): number
	return ctx.Settings and ctx.Settings.voice and ctx.Settings.voice() or 1
end

--[[
	Say a line. opts: Channel ("Dialogue" by default: a new line cuts the last one off), Volume
	(0..), VolumeFn (() -> number, re-read while it plays: his voice by distance), Effects ("Far",
	"Him": overrides the profile's).
	Returns at once; the line plays when it's loaded (if the channel hasn't moved on).
]]
function Voices.say(text: string?, key: string?, opts: any?)
	if type(text) ~= "string" or text == "" or not output then
		return
	end
	opts = opts or {}
	local channel = opts.Channel or "Dialogue"
	-- (stage directions and quotes aren't read out)
	local clean = text:gsub("<[^>]+>", ""):gsub("%b[]", ""):gsub("[\"“”]", "")
	clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
	if clean == "" then
		return
	end
	-- (the next line cuts the last one off at once, even before it has loaded)
	Voices.stop(channel)
	local mine = {}
	playing[channel] = mine
	task.spawn(function()
		local tts = load(clean, key, opts.Effects)
		if not tts or playing[channel] ~= mine then
			return
		end
		playing[channel] = tts
		local base = (opts.Volume or 1) * profile(key).Volume
		local function level(): number
			return base * setting() * (opts.VolumeFn and opts.VolumeFn() or 1)
		end
		pcall(function()
			tts.TimePosition = 0
			tts.Volume = level()
			tts:Play()
		end)
		if opts.VolumeFn then
			-- (follows the distance while it plays)
			local t0 = os.clock()
			local limit = math.max(3, (tonumber(tts.TimeLength) or 8) + 1)
			while playing[channel] == tts and os.clock() - t0 < limit do
				pcall(function()
					tts.Volume = level()
				end)
				RunService.Heartbeat:Wait()
			end
		end
	end)
end

-- warm a line up so it plays the moment it's needed (the answers you might give)
function Voices.prefetch(text: string?, key: string?)
	if type(text) == "string" and text ~= "" and output then
		task.spawn(load, (text:gsub("[\"“”]", "")), key)
	end
end

-- the voice of a player (their role tonight)
function Voices.forPlayer(p: Player?): string
	local role = p and p:GetAttribute("Role")
	return type(role) == "string" and ctx.Story.Voices.Profiles[role] and role or "Default"
end

-- the voice of a speaker in the dialogue box
function Voices.forSpeaker(name: string?): string
	return (name and ctx.Story.Voices.Speakers[name]) or "Default"
end

function Voices.init(c)
	ctx = c
	ctx.Voices = Voices
end

function Voices.start()
	if not ctx.Story.Voices then
		return
	end
	local ok = pcall(function()
		local out = Instance.new("AudioDeviceOutput")
		out.Name = "VoicesOutput"
		out.Parent = SoundService
		output = out
	end)
	if not ok then
		available = false
		return -- (no new audio API here)
	end
	-- his voice: only near him, quieter through walls
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- a voice from somewhere in the house: him (kind = which of his lines), or (the mimic) a
	-- voice you know from a place: opts = { Voice, From, Range, Caption }
	ctx.Remotes.HisVoice.OnClientEvent:Connect(function(text: string, opts: any?)
		local mimic = type(opts) == "table"
		local where: () -> Vector3?
		local exclude: { Instance } = {}
		local V = ctx.Story.Voices.Him
		local full, max = V.Full, V.Max
		if mimic then
			local from = opts.From
			if typeof(from) ~= "Vector3" then
				return
			end
			where = function()
				return from
			end
			full, max = 8, tonumber(opts.Range) or 60
		else
			local curtis = workspace:FindFirstChild("Curtis", true)
			local root = curtis and (curtis:FindFirstChild("Eyes", true) or curtis:FindFirstChild("HumanoidRootPart", true) or (curtis :: any).PrimaryPart)
			if not root or not root:IsA("BasePart") then
				return
			end
			exclude = { curtis :: Instance }
			where = function()
				return root.Parent and root.Position or nil
			end
		end
		local function near(): number
			local cam = workspace.CurrentCamera
			local at = where()
			if not cam or not at then
				return 0
			end
			local from = cam.CFrame.Position
			local d = (at - from).Magnitude
			local k = math.clamp(1 - (d - full) / (max - full), 0, 1)
			if k <= 0 then
				return 0
			end
			local ignore = table.clone(exclude)
			if player.Character then
				table.insert(ignore, player.Character)
			end
			rayParams.FilterDescendantsInstances = ignore
			if not mimic and workspace:Raycast(from, at - from, rayParams) then
				k *= V.Wall
			end
			return mimic and k or k * k
		end
		local first = near()
		if first <= 0.02 then
			return
		end
		if mimic then
			Voices.say(text, tostring(opts.Voice or "Default"), { Channel = "Mimic", VolumeFn = near, Effects = "Far" })
			if ctx.HUD and type(opts.Caption) == "string" then
				ctx.HUD.caption(opts.Caption)
			end
			return
		end
		Voices.say(text, "Him", { Channel = "Him", VolumeFn = near })
		-- (the moment he sees or grabs you has its own captions)
		if ctx.HUD and first > 0.15 and opts ~= "Found" and opts ~= "Grab" then
			ctx.HUD.caption("[A voice, close] " .. text)
		end
	end)
end

return Voices
