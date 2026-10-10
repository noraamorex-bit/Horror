--[[
	Documents — the paper reader for notes, invoices, drawings and the notebook.
	Closes with the X button, Q / Backspace, or by walking away.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Documents = {}
local ctx
local player = Players.LocalPlayer

local panel: Frame
local title: TextLabel
local body: TextLabel
local extra: TextLabel
local openedAt: Vector3? = nil

function Documents.close()
	panel.Visible = false
	openedAt = nil
end

-- (doc: a document made on the server, e.g. his notes with tonight's lock code)
function Documents.open(docId: string, override: any?)
	local doc = (type(override) == "table" and type(override.Body) == "string") and override or ctx.Story.Documents[docId]
	if not doc then
		return
	end
	title.Text = doc.Title
	body.Text = doc.Body
	if doc.ObserverExtra and player:GetAttribute("Role") == "Observer" then
		extra.Text = "<i>You notice: " .. doc.ObserverExtra .. "</i>"
		extra.Visible = true
	else
		extra.Visible = false
	end
	panel.Visible = true
	if ctx.Effects then
		ctx.Effects.playSound("Paper", nil, { Caption = false })
	end
	local root = ctx.Util.getRoot(player)
	openedAt = root and root.Position or nil
end

function Documents.init(c)
	ctx = c
	ctx.Documents = Documents
end

function Documents.start()
	local UI = ctx.UI
	panel = UI.new("Frame", {
		Name = "Document",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 540),
		BackgroundColor3 = UI.Color.Paper,
		Visible = false,
		Parent = UI.Root,
	})
	UI.corner(panel, 4)
	UI.modal(panel)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(520, 540), Parent = panel })
	local scroll = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(28, 24),
		Size = UDim2.new(1, -56, 1, -48),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = UI.Color.Ink,
		Parent = panel,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	title = UI.label({ Size = UDim2.new(1, -40, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = UI.Font.Title, TextSize = 26, TextColor3 = UI.Color.Ink, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = scroll })
	body = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = UI.Font.Title, TextSize = 19, TextColor3 = UI.Color.Ink, TextXAlignment = Enum.TextXAlignment.Left, RichText = false, LayoutOrder = 2, Parent = scroll })
	extra = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 16, TextColor3 = Color3.fromRGB(120, 40, 30), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = scroll })
	local close = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(44, 44),
		Text = "✕",
		Font = UI.Font.Bold,
		TextSize = 24,
		TextColor3 = UI.Color.Ink,
		BackgroundTransparency = 1,
		Parent = panel,
	})
	close.Activated:Connect(Documents.close)

	ctx.Remotes.Document.OnClientEvent:Connect(Documents.open)
	ctx.Input.on("Close", function(began)
		if began and panel.Visible then
			Documents.close()
		end
	end)
	RunService.Heartbeat:Connect(function()
		if openedAt then
			local root = ctx.Util.getRoot(player)
			if not root or (root.Position - openedAt).Magnitude > 7 then
				Documents.close()
			end
		end
	end)
end

return Documents
