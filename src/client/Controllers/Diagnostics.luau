--[[
	Diagnostics — tells the server what this device is and how well the game runs on it, every 15 s
	(Remotes.ClientInfo → server JourneyService, which saves it with the night / lobby log).
	Phone, Tablet, PC or Console; memory in MB; average frames per second; graphics quality.
	A player who leaves with low frames and high memory probably crashed or gave up on the lag.
	Script errors on this device go along too (up to 5 different ones, with counts): bugs players
	hit that never show up in a test.
]]

local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local Diagnostics = {}
local ctx

local function device(): string
	local ok, ten = pcall(function()
		return GuiService:IsTenFootInterface()
	end)
	if ok and ten then
		return "Console"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		local cam = workspace.CurrentCamera
		local size = cam and cam.ViewportSize or Vector2.new(0, 0)
		return math.min(size.X, size.Y) >= 600 and "Tablet" or "Phone"
	end
	return "PC"
end

local function quality(): number?
	local ok, q = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	return ok and q or nil
end

function Diagnostics.init(c)
	ctx = c
end

-- script errors seen on this device: { { M = message (+ where), N = count } }, 5 different at most
local errors = {}
local function onError(message: string, trace: string, _script: Instance?)
	local where = type(trace) == "string" and string.match(trace, "([%w_]+):(%d+)") or nil
	local line = type(trace) == "string" and string.match(trace, "[%w_]+:(%d+)") or nil
	local key = string.sub(tostring(message), 1, 140) .. (where and (" @" .. where .. ":" .. tostring(line)) or "")
	for _, e in errors do
		if e.M == key then
			e.N += 1
			return
		end
	end
	if #errors < 5 then
		table.insert(errors, { M = key, N = 1 })
	end
end
Diagnostics._onError = onError -- (tests)
Diagnostics._errors = function()
	return errors
end

function Diagnostics.start()
	pcall(function()
		ScriptContext.Error:Connect(onError)
	end)
	local frames = 0
	RunService.RenderStepped:Connect(function()
		frames += 1
	end)
	task.spawn(function()
		local last = os.clock()
		-- (v110: the first report comes at once: the server waits for it before starting a night)
		task.wait(1)
		while true do
			local now = os.clock()
			local fps = frames / math.max(now - last, 0.001)
			frames = 0
			last = now
			local okM, mem = pcall(function()
				return Stats:GetTotalMemoryUsageMb()
			end)
			pcall(function()
				ctx.Remotes.ClientInfo:FireServer({
					Dev = device(),
					Mem = okM and mem or nil,
					Fps = math.floor(fps * 10 + 0.5) / 10,
					Q = quality(),
					Low = game:GetService("Players").LocalPlayer:GetAttribute("LowPerf") == true or nil,
					Err = #errors > 0 and errors or nil,
					Skin = ctx.Creature and ctx.Creature.status and ctx.Creature.status() or nil,
				})
			end)
			task.wait(15)
		end
	end)
end

return Diagnostics
