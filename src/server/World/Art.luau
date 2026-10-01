--[[
	Art — the paintings on the walls: free Creator Store decals, loaded onto the canvases at
	runtime (World/Props reads a canvas's ArtDecal / ArtFace attributes).
]]

local Art = {}

-- Real paintings: free Creator Store decals, loaded onto the canvases at runtime (World/Props).
-- Kind: L = landscape canvas, P = portrait, S = square. The canvas colour is the fallback.
Art.List = {
	{ Id = 14015311827, Kind = "L" }, -- moody oil landscape
	{ Id = 15167687020, Kind = "L" }, -- "Paysage"
	{ Id = 111110087457443, Kind = "L" }, -- classical landscape with ruins
	{ Id = 132864119146505, Kind = "L" }, -- hazy valley
	{ Id = 14497681290, Kind = "L" }, -- lake villa
	{ Id = 16487859642, Kind = "L" }, -- coast road under trees
	{ Id = 2891344535, Kind = "L" }, -- The Straits of Gibraltar (Varley, 1825)
	{ Id = 14790405196, Kind = "L" }, -- ruined temple by a river
	{ Id = 16306710583, Kind = "L" }, -- wildflowers by the sea
	{ Id = 12371508711, Kind = "L" }, -- dark mountain river
	{ Id = 126961034851150, Kind = "L" }, -- bear in a misty forest
	{ Id = 137749288809923, Kind = "L" }, -- autumn marsh
	{ Id = 137758171111785, Kind = "L" }, -- dark autumn wood
	{ Id = 18114786454, Kind = "L" }, -- Irish countryside
	{ Id = 111630057375904, Kind = "L" }, -- red barn in autumn
	{ Id = 92663566233830, Kind = "L" }, -- farm valley
	{ Id = 17814093663, Kind = "L" }, -- farm under a big sky
	{ Id = 7649523068, Kind = "L" }, -- misty pine forest
	{ Id = 87291376245098, Kind = "P" }, -- Winterhalter portrait
	{ Id = 429353016, Kind = "P" }, -- old lady in blue
	{ Id = 429353090, Kind = "P" }, -- woman in a fur stole
	{ Id = 16143978673, Kind = "P" }, -- Matejko: head of an old man
	{ Id = 16143709923, Kind = "P" }, -- Matejko: portrait of a woman
	{ Id = 81812781988226, Kind = "P" }, -- old woman in a bonnet
	{ Id = 429352232, Kind = "P" }, -- woman in a shawl
	{ Id = 139801544877010, Kind = "P" }, -- Ajdukiewicz portrait
	{ Id = 6202751422, Kind = "P" }, -- woman in red
	{ Id = 86501764154075, Kind = "P" }, -- a stern family portrait
	{ Id = 14183423574, Kind = "P" }, -- a pale girl in a dark dress
	{ Id = 2676993598, Kind = "S" }, -- flowers in the dark
	{ Id = 13727715414, Kind = "S" }, -- roses in a glass vase
	{ Id = 12874025680, Kind = "S" }, -- bowl of fruit
}

-- a painting for a frame of this shape (the same seed always gets the same one)
function Art.pick(w: number, h: number, seed: number)
	local kind = w > h * 1.15 and "L" or (h > w * 1.15 and "P" or "S")
	local fits = {}
	for _, a in Art.List do
		if a.Kind == kind then
			table.insert(fits, a)
		end
	end
	if #fits == 0 then
		fits = Art.List
	end
	-- from the far end of the list: the walls (Finish) take theirs from the front
	return fits[#fits - (seed % #fits)]
end

return Art
