--[[
	AudioService — 3D sounds + captions.

	Audio.playAt(name, position, opts)   replicated 3D one-shot, captions to players in range
	Audio.loopOn(name, part, opts)       looped sound parented to a part (returns Sound)
	Audio.playFor(player, name, pos)     a sound ONLY one player hears (client-side)
	Audio.caption(text, pos, range, onlyPlayers)
]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Audio = {}
local ctx

function Audio.init(c)
	ctx = c
end

local function build(name: string, opts)
	local def = ctx.Sounds.get(name)
	if not def then
		warn("[Audio] unknown sound " .. name)
		return nil, nil
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = ctx.Sounds.resolve(name) or ""
	s.Volume = opts.Volume or def.Volume or 0.6
	s.PlaybackSpeed = opts.Pitch or def.Pitch or 1
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = opts.Min or def.Min or 6
	s.RollOffMaxDistance = opts.Range or def.Range or 80
	s.Looped = if opts.Looped ~= nil then opts.Looped else (def.Looped or false)
	return s, def
end

function Audio.caption(text: string?, position: Vector3?, range: number?, only: { Player }?)
	if not text or text == "" then
		return
	end
	local targets = only or Players:GetPlayers()
	for _, p in targets do
		if not position then
			ctx.Remotes.Caption:FireClient(p, text)
		else
			local root = ctx.Util.getRoot(p)
			local r = range or 60
			if p:GetAttribute("Role") == "Observer" then
				r *= 1.5
			end
			-- through floors sound travels less
			if root then
				local d = (root.Position - position).Magnitude
				local floorA = ctx.Rooms.floorOf(root.Position)
				local floorB = ctx.Rooms.floorOf(position)
				if floorA ~= floorB then
					r *= 0.7
				end
				if d <= r then
					ctx.Remotes.Caption:FireClient(p, text, position)
				end
			end
		end
	end
end

function Audio.playAt(name: string, position: Vector3, opts)
	opts = opts or {}
	local s, def = build(name, opts)
	if not s then
		return nil
	end
	local att = Instance.new("Attachment")
	att.Name = "Sound_" .. name
	att.Parent = workspace.Terrain
	att.Position = position
	s.Parent = att
	if s.SoundId ~= "" then
		s:Play()
	end
	Debris:AddItem(att, opts.Duration or 10)
	if opts.Caption ~= false then
		Audio.caption(opts.CaptionText or def.Caption, position, opts.CaptionRange or s.RollOffMaxDistance * 0.75, opts.Only)
	end
	return s
end

function Audio.loopOn(name: string, part: Instance, opts)
	opts = opts or {}
	opts.Looped = true
	local s, def = build(name, opts)
	if not s then
		return nil
	end
	s.Parent = part
	if s.SoundId ~= "" and opts.Play ~= false then
		s:Play()
	end
	if opts.Caption ~= false and def.Caption and part:IsA("BasePart") then
		Audio.caption(def.Caption, (part :: BasePart).Position, s.RollOffMaxDistance * 0.6)
	end
	return s
end

function Audio.playFor(player: Player, name: string, position: Vector3?, opts)
	ctx.Remotes.PlaySound:FireClient(player, name, position, opts)
end

return Audio
