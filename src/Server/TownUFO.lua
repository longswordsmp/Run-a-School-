-- ServerScriptService.Server.TownUFO
-- The mothership (the Close Encounters story, quests X01-X06): a saucer parked high over the sea,
-- north of Maple Heights. You only get here by being beamed up (quest X05). Inside, one round deck:
--   the command ring in the middle (Captain Zorp), the specimen tubes on the west side (Blip: a cow,
--   a traffic cone, a garden gnome, a rubber duck, a lunchbox, a VexCorp goon's hat), the VexCorp
--   TV wall on the east side (Glorb), windows all round onto the sky and the sea, and the beam pad
--   (south) that sends you home.
local UFO = {}

UFO.CENTER = Vector3.new(0, 380, 760)
UFO.R = 58 -- the deck's radius

function UFO.build(town, Kit)
	local rgb = Kit.rgb
	local part = Kit.part
	local C = UFO.CENTER
	local m = Kit.folder(town, "Mothership")
	local HULL = rgb(150, 156, 172)
	local DECK = rgb(70, 74, 92)
	local GLOW = rgb(110, 255, 90)
	local function at(x, y, z) return CFrame.new(C + Vector3.new(x, y, z)) end

	-- the outside: a huge saucer seen from the ground (and from the windows)
	Kit.cylY(m, "Hull", UFO.R * 2 + 30, 8, C + Vector3.new(0, -5, 0), HULL, Enum.Material.Metal, { Reflectance = 0.15 })
	Kit.cylY(m, "HullRim", UFO.R * 2 + 36, 2, C + Vector3.new(0, -2, 0), rgb(110, 116, 130), Enum.Material.Metal)
	Kit.cylY(m, "Belly", UFO.R * 1.3, 6, C + Vector3.new(0, -11, 0), rgb(96, 100, 116), Enum.Material.Metal)
	for k = 0, 23 do
		local a = math.rad(k * 15)
		local lamp = Kit.ball(m, "RimLight", 3, C + Vector3.new(math.cos(a) * (UFO.R + 17), -2, math.sin(a) * (UFO.R + 17)), k % 2 == 0 and GLOW or rgb(255, 240, 120), Enum.Material.Neon)
		lamp.CanCollide = false
	end
	-- the deck
	Kit.cylY(m, "Deck", UFO.R * 2, 1, C + Vector3.new(0, -0.5, 0), DECK, Enum.Material.DiamondPlate)
	for _, r in { 18, 34, 50 } do
		Kit.cylY(m, "DeckRing", r * 2 + 1, 0.06, C + Vector3.new(0, 0.03, 0), GLOW, Enum.Material.Neon)
		Kit.cylY(m, "DeckRingInner", r * 2 - 1, 0.08, C + Vector3.new(0, 0.04, 0), DECK, Enum.Material.DiamondPlate)
	end
	-- the wall all round: 24 segments, a window in each (the sky and the sea outside)
	local H = 26
	for k = 0, 23 do
		local a = k * math.pi / 12
		local cf = CFrame.new(C + Vector3.new(math.cos(a) * UFO.R, H / 2, math.sin(a) * UFO.R)) * CFrame.Angles(0, -a + math.pi / 2, 0)
		local segW = 2 * math.pi * UFO.R / 24 + 0.4
		part(m, "Wall", Vector3.new(segW, 5, 1.2), cf * CFrame.new(0, -H / 2 + 2.5, 0), HULL, Enum.Material.Metal)
		part(m, "Wall", Vector3.new(segW, H - 17, 1.2), cf * CFrame.new(0, H / 2 - (H - 17) / 2, 0), HULL, Enum.Material.Metal)
		part(m, "Window", Vector3.new(segW - 1.6, 12, 0.3), cf * CFrame.new(0, -H / 2 + 11, 0), rgb(170, 220, 255), Enum.Material.Glass, { Transparency = 0.6, CastShadow = false })
		part(m, "WindowFrame", Vector3.new(1.2, 12, 1.4), cf * CFrame.new(segW / 2, -H / 2 + 11, 0), rgb(90, 96, 110), Enum.Material.Metal)
		part(m, "WallGlow", Vector3.new(segW, 0.4, 0.4), cf * CFrame.new(0, -H / 2 + 5.2, -0.8), GLOW, Enum.Material.Neon, { CanCollide = false })
	end
	-- the ceiling: a dome of panels with lights
	Kit.cylY(m, "Ceiling", UFO.R * 2 + 2, 1, C + Vector3.new(0, H + 0.5, 0), rgb(40, 44, 58), Enum.Material.Metal)
	for k = 0, 11 do
		local a = math.rad(k * 30)
		for _, r in { 20, 40 } do
			local lp = part(m, "CeilingLight", Vector3.new(6, 0.3, 2), CFrame.new(C + Vector3.new(math.cos(a) * r, H - 0.2, math.sin(a) * r)) * CFrame.Angles(0, -a, 0), rgb(200, 255, 200), Enum.Material.Neon, { CanCollide = false })
			if k % 2 == 0 then
				local l = Instance.new("SurfaceLight")
				l.Face = Enum.NormalId.Bottom
				l.Range = 34
				l.Brightness = 1.4
				l.Angle = 120
				l.Color = rgb(210, 255, 210)
				l.Parent = lp
			end
		end
	end
	-- the command ring in the middle: a round console, seats, a hologram of Earth
	local cmd = Kit.folder(m, "Command")
	Kit.cylY(cmd, "ConsoleBase", 20, 3.4, C + Vector3.new(0, 1.7, 0), rgb(50, 54, 70), Enum.Material.Metal)
	Kit.cylY(cmd, "ConsoleHole", 12, 3.6, C + Vector3.new(0, 1.7, 0), DECK, Enum.Material.DiamondPlate)
	Kit.cylY(cmd, "ConsoleTop", 20.4, 0.3, C + Vector3.new(0, 3.5, 0), rgb(30, 34, 46), Enum.Material.Glass)
	for k = 0, 15 do
		local a = math.rad(k * 22.5)
		part(cmd, "ConsoleButton", Vector3.new(0.8, 0.2, 0.8), CFrame.new(C + Vector3.new(math.cos(a) * 8, 3.7, math.sin(a) * 8)), ({ GLOW, rgb(255, 80, 80), rgb(80, 180, 255), rgb(255, 230, 80) })[k % 4 + 1], Enum.Material.Neon, { CanCollide = false })
	end
	local earth = Kit.ball(cmd, "Hologram", 6, C + Vector3.new(0, 9, 0), rgb(90, 170, 255), Enum.Material.ForceField)
	earth.CanCollide = false
	earth:SetAttribute("SpinSpeed", 0.3)
	local ring = Kit.cylY(cmd, "HoloRing", 9, 0.2, C + Vector3.new(0, 9, 0), GLOW, Enum.Material.Neon)
	ring.CanCollide = false
	Kit.cylY(cmd, "HoloBeam", 4, 5, C + Vector3.new(0, 5.8, 0), GLOW, Enum.Material.Neon, { Transparency = 0.7, CanCollide = false })
	Kit.light(earth, 30, 1.5, rgb(120, 200, 255))
	-- the specimen tubes on the west side
	local lab = Kit.folder(m, "Specimens")
	local SPEC = { "Cow", "TrafficCone", "Gnome", "Duck", "Lunchbox", "GoonHat" }
	for i, name in SPEC do
		local a = math.rad(150 + (i - 1) * 12)
		local p = C + Vector3.new(math.cos(a) * 44, 0, math.sin(a) * 44)
		Kit.cylY(lab, "TubeBase", 6, 1, p + Vector3.new(0, 0.5, 0), rgb(50, 54, 70), Enum.Material.Metal)
		Kit.cylY(lab, "TubeGlass", 5.4, 10, p + Vector3.new(0, 6, 0), rgb(190, 255, 200), Enum.Material.Glass, { Transparency = 0.6 })
		Kit.cylY(lab, "TubeCap", 6, 1, p + Vector3.new(0, 11.5, 0), rgb(50, 54, 70), Enum.Material.Metal)
		Kit.cylY(lab, "TubeGlow", 5, 0.2, p + Vector3.new(0, 1.1, 0), GLOW, Enum.Material.Neon)
		local y = p + Vector3.new(0, 5, 0)
		if name == "Cow" then
			-- a blocky cow, floating
			part(lab, "CowBody", Vector3.new(3.4, 2, 1.8), CFrame.new(y), rgb(250, 250, 250))
			part(lab, "CowSpot", Vector3.new(1.2, 1, 1.85), CFrame.new(y + Vector3.new(0.6, 0.3, 0)), rgb(30, 30, 30))
			part(lab, "CowHead", Vector3.new(1.2, 1.2, 1.2), CFrame.new(y + Vector3.new(2, 0.6, 0)), rgb(250, 250, 250))
			part(lab, "CowNose", Vector3.new(0.4, 0.6, 1), CFrame.new(y + Vector3.new(2.7, 0.4, 0)), rgb(255, 180, 190))
			for _, lx in { -1.2, 1.2 } do
				for _, lz in { -0.6, 0.6 } do part(lab, "CowLeg", Vector3.new(0.4, 1.2, 0.4), CFrame.new(y + Vector3.new(lx, -1.4, lz)), rgb(250, 250, 250)) end
			end
		elseif name == "TrafficCone" then
			Kit.cylY(lab, "Cone", 1.8, 3.2, y, rgb(255, 120, 30))
			Kit.cylY(lab, "ConeStripe", 1.4, 0.4, y + Vector3.new(0, 0.4, 0), rgb(250, 250, 250))
		elseif name == "Gnome" then
			part(lab, "GnomeBody", Vector3.new(1.4, 1.8, 1.4), CFrame.new(y), rgb(60, 110, 220))
			Kit.ball(lab, "GnomeHead", 1.2, y + Vector3.new(0, 1.4, 0), rgb(255, 214, 180))
			Kit.ball(lab, "GnomeBeard", 1, y + Vector3.new(0, 1, -0.4), rgb(250, 250, 250))
			Kit.wedge(lab, "GnomeHat", Vector3.new(1.3, 1.6, 0.7), y + Vector3.new(0, 2.6, 0.35), "+z", rgb(220, 40, 50))
			Kit.wedge(lab, "GnomeHat", Vector3.new(1.3, 1.6, 0.7), y + Vector3.new(0, 2.6, -0.35), "-z", rgb(220, 40, 50))
		elseif name == "Duck" then
			Kit.ball(lab, "DuckBody", 2, y, rgb(255, 220, 60))
			Kit.ball(lab, "DuckHead", 1.3, y + Vector3.new(0.6, 1.1, 0), rgb(255, 220, 60))
			part(lab, "DuckBill", Vector3.new(0.6, 0.25, 0.5), CFrame.new(y + Vector3.new(1.3, 1, 0)), rgb(255, 140, 40))
		elseif name == "Lunchbox" then
			part(lab, "Lunchbox", Vector3.new(2.4, 1.8, 1.2), CFrame.new(y), rgb(220, 60, 60))
			part(lab, "LunchHandle", Vector3.new(1.2, 0.3, 0.3), CFrame.new(y + Vector3.new(0, 1.1, 0)), rgb(60, 60, 70))
		elseif name == "GoonHat" then
			Kit.cylY(lab, "HatBrim", 2.4, 0.2, y, rgb(40, 30, 50))
			Kit.cylY(lab, "HatTop", 1.6, 1.4, y + Vector3.new(0, 0.8, 0), rgb(110, 50, 165))
		end
		local label = part(lab, "TubeLabel", Vector3.new(4, 0.9, 0.2), CFrame.lookAt(p + Vector3.new(0, 13, 0), C + Vector3.new(0, 13, 0)), rgb(20, 30, 20))
		Kit.sign(label, Enum.NormalId.Front, ({ "EARTH BEAST", "EARTH HAT?", "TINY EARTHLING", "SQUEAKY ONE", "EARTH FOOD BOX", "VEXCORP HELMET" })[i], GLOW, rgb(20, 30, 20), Enum.Font.Arcade)
	end
	-- the VexCorp TV wall on the east side
	local tv = part(m, "TVWall", Vector3.new(1, 12, 24), CFrame.lookAt(C + Vector3.new(50, 8, 0), C + Vector3.new(0, 8, 0)), rgb(20, 16, 30), Enum.Material.Neon)
	local tvGui = Kit.sign(tv, Enum.NormalId.Front, "\u{1F4FA} INTERCEPTED: VEXCORP TV\n\n\"HOMEWORK IS THE FUTURE.\nRECESS IS CANCELLED.\"\n- DR. V. VEX", rgb(205, 150, 255), rgb(20, 16, 30), Enum.Font.GothamBlack)
	_ = tvGui
	-- the beam pad (south): home
	local pad = Kit.cylY(m, "BeamPad", 12, 0.6, C + Vector3.new(0, 0.3, 46), GLOW, Enum.Material.Neon)
	pad:SetAttribute("BeamHome", true)
	Kit.cylY(m, "BeamPadRim", 13, 0.4, C + Vector3.new(0, 0.2, 46), rgb(90, 96, 110), Enum.Material.Metal)
	local beamSign = part(m, "BeamSign", Vector3.new(10, 1.6, 0.3), CFrame.lookAt(C + Vector3.new(0, 7, 52), C + Vector3.new(0, 7, 0)), rgb(20, 30, 20))
	Kit.sign(beamSign, Enum.NormalId.Front, "\u{2B07} BEAM DOWN TO EARTH", GLOW, rgb(20, 30, 20), Enum.Font.GothamBlack)
	return m
end

return UFO
