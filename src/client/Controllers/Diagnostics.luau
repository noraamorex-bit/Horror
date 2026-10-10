--[[
	Diagnostics — tells the server what this device is and how well the game runs on it, every 15 s
	(Remotes.ClientInfo → server JourneyService, which saves it with the night / lobby log).
	Phone, Tablet, PC or Console; memory in MB; average frames per second; graphics quality.
	A player who leaves with low frames and high memory probably crashed or gave up on the lag.
]]

local RunService = game:GetService("RunService")
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

function Diagnostics.start()
	local frames = 0
	RunService.RenderStepped:Connect(function()
		frames += 1
	end)
	task.spawn(function()
		local last = os.clock()
		task.wait(5)
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
				})
			end)
			task.wait(15)
		end
	end)
end

return Diagnostics
