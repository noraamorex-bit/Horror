--[[
	Input — one action layer for keyboard, gamepad and touch.

	Input.on(action, fn(began: boolean))   subscribe
	Input.fire(action, began)               used by on-screen (touch) buttons
	Input.keyFor(action) -> "Shift"          label for hints

	Actions: Sprint (hold), Crouch, Flashlight, Spray, Journal, Phone, Breath (hold),
	         Struggle, ExitHide, Close
]]

local UserInputService = game:GetService("UserInputService")

local Input = {}

local K = Enum.KeyCode
Input.Bindings = {
	Sprint = { Keys = { K.LeftShift, K.RightShift }, Pad = { K.ButtonL3 }, Label = "Shift" },
	Crouch = { Keys = { K.C, K.LeftControl }, Pad = { K.ButtonB }, Label = "C" },
	Flashlight = { Keys = { K.F }, Pad = { K.DPadUp }, Label = "F" },
	Spray = { Keys = { K.G }, Pad = { K.DPadRight }, Label = "G" },
	Journal = { Keys = { K.Tab, K.J }, Pad = { K.DPadLeft }, Label = "Tab" },
	Phone = { Keys = { K.P }, Pad = { K.DPadDown }, Label = "P" },
	Breath = { Keys = { K.Space }, Pad = { K.ButtonA }, Label = "Space" },
	Struggle = { Keys = { K.Space }, Pad = { K.ButtonA, K.ButtonX }, Label = "Space" },
	ExitHide = { Keys = { K.E }, Pad = { K.ButtonB }, Label = "E" },
	Close = { Keys = { K.Q, K.Backspace, K.Return }, Pad = { K.ButtonB }, Label = "Q" },
}

local listeners: { [string]: { (boolean) -> () } } = {}

function Input.on(action: string, fn: (boolean) -> ())
	listeners[action] = listeners[action] or {}
	table.insert(listeners[action], fn)
end

function Input.fire(action: string, began: boolean)
	for _, fn in listeners[action] or {} do
		task.spawn(fn, began)
	end
end

function Input.keyFor(action: string): string
	local b = Input.Bindings[action]
	return b and b.Label or "?"
end

local function actionsFor(key: Enum.KeyCode): { string }
	local out = {}
	for action, b in Input.Bindings do
		if table.find(b.Keys, key) or table.find(b.Pad, key) then
			table.insert(out, action)
		end
	end
	return out
end

function Input.init(ctx)
	ctx.Input = Input
end

function Input.start()
	UserInputService.InputBegan:Connect(function(io, processed)
		if processed and io.KeyCode ~= K.Tab then
			return
		end
		for _, action in actionsFor(io.KeyCode) do
			Input.fire(action, true)
		end
	end)
	UserInputService.InputEnded:Connect(function(io)
		for _, action in actionsFor(io.KeyCode) do
			Input.fire(action, false)
		end
	end)
end

return Input
