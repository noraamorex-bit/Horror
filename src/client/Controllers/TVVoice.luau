--[[
	TVVoice — the people on the living-room TV actually talk (Roblox text-to-speech).

	The server draws the broadcast (World/TVScreens) and tags the screen "TVScreen" with the
	channel on it ("TVChannel"). Near the TV, this plays the channel's lines (Story.TVVoice):
		News, Weather   the presenter reads the bulletin, line by line, round and round
		Movie           each subtitle is spoken as it comes up on screen ("MovieLine")
	Louder the closer you are, nothing beyond MAX studs, scaled by the Sounds setting. While a
	line plays, the presenter's mouth moves; now and then they blink.

	Each line is generated once and kept (replayed from the start), so the whole night costs a
	dozen speech requests per player. If speech isn't available, the TV is simply silent.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local TVVoice = {}
local ctx
local player = Players.LocalPlayer

local MAX = 46 -- studs: beyond this, nothing
local FULL = 12 -- studs: full volume inside this
local BASE = 1.6

local output: Instance? = nil
local cache: { [string]: any } = {} -- "News:1" -> AudioTextToSpeech (loaded)
local failed: { [string]: boolean } = {}
local current: any = nil -- the AudioTextToSpeech playing now
local speaking = false
local runToken = 0
local volume = 0

local function screenPart(): BasePart?
	local list = CollectionService:GetTagged("TVScreen")
	return list[1] :: BasePart?
end

local function stopLine()
	if current then
		pcall(function()
			current:Pause()
		end)
	end
	current = nil
	speaking = false
end

-- the speech object for a line, generated once (yields while it loads)
local function line(channel: string, i: number): any
	local key = channel .. ":" .. i
	if cache[key] then
		return cache[key]
	end
	if failed[key] then
		return nil
	end
	local def = ctx.Story.TVVoice[channel] and ctx.Story.TVVoice[channel][i]
	if not def or not output then
		return nil
	end
	local ok, tts = pcall(function()
		local t = Instance.new("AudioTextToSpeech")
		t.Name = "TV_" .. key
		t.Text = def.Text
		t.VoiceId = def.Voice
		t.Volume = 0
		t.Parent = SoundService
		local w = Instance.new("Wire")
		w.SourceInstance = t
		w.TargetInstance = output
		w.Parent = t
		t:LoadAsync()
		return t
	end)
	if not ok or not tts then
		failed[key] = true
		return nil
	end
	cache[key] = tts
	return tts
end

-- play one line to the end (or until the channel changes); returns false if it couldn't
local function say(channel: string, i: number, token: number): boolean
	local tts = line(channel, i)
	if not tts or token ~= runToken then
		return false
	end
	stopLine()
	current = tts
	local done = false
	local conn = tts.Ended:Connect(function()
		done = true
	end)
	pcall(function()
		tts.TimePosition = 0
		tts.Volume = volume
		tts:Play()
	end)
	speaking = true
	local t0 = os.clock()
	local limit = math.max(3, (tonumber(tts.TimeLength) or 20) + 1)
	while not done and token == runToken and os.clock() - t0 < limit do
		task.wait(0.1)
	end
	conn:Disconnect()
	if current == tts then
		speaking = false
	end
	return true
end

local function bulletin(channel: string, token: number)
	local lines = ctx.Story.TVVoice[channel] or {}
	while token == runToken do
		local any = false
		for i = 1, #lines do
			if token ~= runToken then
				return
			end
			if say(channel, i, token) then
				any = true
			end
			task.wait(1.1)
		end
		-- (the report is on a loop; a pause before it comes round again)
		local pause = any and 8 or 30
		local t0 = os.clock()
		while token == runToken and os.clock() - t0 < pause do
			task.wait(0.25)
		end
	end
end

local function movie(token: number, screen: BasePart)
	local last = nil
	while token == runToken do
		local gui = screen:FindFirstChildOfClass("SurfaceGui")
		local frame = gui and gui:FindFirstChild("Movie", true)
		local i = frame and frame:GetAttribute("MovieLine")
		if type(i) == "number" and i ~= last then
			last = i
			task.spawn(say, "Movie", i, token)
		end
		task.wait(0.2)
	end
end

local function start(channel: string, screen: BasePart)
	runToken += 1
	local token = runToken
	stopLine()
	if channel == "News" or channel == "Weather" then
		task.spawn(bulletin, channel, token)
	elseif channel == "Movie" then
		task.spawn(movie, token, screen)
	end
end

-- the presenter on the visible channel
local function presenter(screen: BasePart): Model?
	local gui = screen:FindFirstChildOfClass("SurfaceGui")
	if not gui then
		return nil
	end
	for _, vp in gui:GetDescendants() do
		if vp:IsA("ViewportFrame") and vp.Name == "Presenter" then
			local f = vp.Parent :: GuiObject?
			if f and f.Visible then
				return vp:FindFirstChild("Anchor", true) :: Model?
			end
		end
	end
	return nil
end

function TVVoice.init(c)
	ctx = c
end

function TVVoice.start()
	if not ctx.Story.TVVoice then
		return
	end
	local ok = pcall(function()
		local out = Instance.new("AudioDeviceOutput")
		out.Name = "TVVoiceOutput"
		out.Parent = SoundService
		output = out
	end)
	if not ok then
		return -- (no new audio API here)
	end
	local playingChannel: string? = nil
	local blinkAt = os.clock() + 3
	local face: Model? = nil
	local faceFor: string? = nil
	local faceCheck = 0
	RunService.Heartbeat:Connect(function()
		local screen = screenPart()
		local channel = screen and screen:GetAttribute("TVChannel")
		local cam = workspace.CurrentCamera
		local dist = (screen and cam) and (screen.Position - cam.CFrame.Position).Magnitude or math.huge
		local voiced = channel == "News" or channel == "Weather" or channel == "Movie"
		local near = voiced and dist < MAX
		-- start / stop as the channel changes or you come and go
		local want = near and channel or nil
		if want ~= playingChannel then
			playingChannel = want
			if want and screen then
				start(want, screen)
			else
				runToken += 1
				stopLine()
			end
		end
		-- volume by distance and the Sounds setting
		local sfx = tonumber(player:GetAttribute("SetSfx")) or 1
		local k = near and math.clamp(1 - (dist - FULL) / (MAX - FULL), 0, 1) or 0
		volume = BASE * k * k * sfx
		if current then
			pcall(function()
				current.Volume = volume
			end)
		end
		-- the presenter's face
		if screen and near and (channel == "News" or channel == "Weather") then
			if faceFor ~= channel or (not face and os.clock() > faceCheck) then
				face = presenter(screen)
				faceFor = channel
				faceCheck = os.clock() + 1
			end
			local m = face
			if m and m.Parent then
				local mouth = m:FindFirstChild("Mouth") :: BasePart?
				local lids = m:FindFirstChild("Lids") :: BasePart?
				local t = os.clock()
				if mouth then
					local base = tonumber(mouth:GetAttribute("Base")) or mouth.Position.Y
					local open = speaking and (0.06 + 0.15 * math.abs(math.noise(t * 9, 0.3))) or 0.06
					mouth.Size = Vector3.new(0.38, open, 0.05)
					mouth.CFrame = CFrame.new(mouth.Position.X, base - (open - 0.06) / 2, mouth.Position.Z)
				end
				if lids then
					if t > blinkAt then
						lids.Transparency = 0
						if t > blinkAt + 0.13 then
							lids.Transparency = 1
							blinkAt = t + 2.5 + math.random() * 3
						end
					end
				end
			end
		end
	end)
end

return TVVoice
