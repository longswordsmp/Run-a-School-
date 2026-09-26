-- ServerScriptService.Server.TownInteriors
-- Inside the houses of Maple Heights. Every house's front door has an Enter prompt (HouseService);
-- the rooms themselves are built as sets out of sight (below the far north of the map), one per
-- style, and the door takes you in and out. A room is 44 x 32, 14 high:
--   living room (left)   a sofa facing the TV, a rug and coffee table, a fireplace, a bookshelf
--   kitchen (right)      counters along the back with a fridge, a stove and a sink, a dining table
--   the back wall        windows onto a painted garden; stairs up to a landing in the back corner
-- Styles: family (three colourways), rose (Grandma Rose: baking, knitting, a rocking chair),
-- timmy (toys, drawings, Mr. Whiskers' empty bed), grumbles (a grandfather clock, newspapers, dark
-- wood), coach (trophies, pennants, dumbbells), skye (posters, a skateboard rack, beanbags).
local Interiors = {}

Interiors.Y = -100
Interiors.Z = 900
Interiors.W, Interiors.D, Interiors.H = 44, 32, 14
Interiors.STYLES = { "family1", "family2", "family3", "rose", "timmy", "grumbles", "coach", "skye" }

-- a set's centre (the floor, in the middle of the room)
function Interiors.center(style)
	for i, s in Interiors.STYLES do
		if s == style then return Vector3.new(-420 + (i - 1) * 64, Interiors.Y, Interiors.Z) end
	end
	return nil
end

-- where you stand when you come in (just inside the door, facing into the room)
function Interiors.entry(style)
	local c = Interiors.center(style)
	return CFrame.lookAt(c + Vector3.new(0, 3.5, Interiors.D / 2 - 4), c + Vector3.new(0, 3.5, 0))
end

function Interiors.build(town, Kit)
	local rgb = Kit.rgb
	local part = Kit.part
	local root = Kit.folder(town, "Interiors")
	local W, D, H = Interiors.W, Interiors.D, Interiors.H

	local PALETTE = {
		family1 = { wall = rgb(236, 226, 206), floor = rgb(170, 120, 80), sofa = rgb(80, 120, 170), accent = rgb(220, 90, 70), rug = rgb(200, 170, 120) },
		family2 = { wall = rgb(210, 230, 220), floor = rgb(150, 110, 75), sofa = rgb(200, 120, 60), accent = rgb(60, 140, 120), rug = rgb(120, 150, 190) },
		family3 = { wall = rgb(240, 236, 246), floor = rgb(190, 150, 110), sofa = rgb(110, 90, 150), accent = rgb(240, 180, 60), rug = rgb(230, 200, 210) },
		rose = { wall = rgb(250, 220, 228), floor = rgb(180, 130, 90), sofa = rgb(200, 110, 140), accent = rgb(250, 250, 250), rug = rgb(240, 180, 200) },
		timmy = { wall = rgb(210, 232, 250), floor = rgb(175, 130, 90), sofa = rgb(240, 170, 60), accent = rgb(240, 90, 60), rug = rgb(120, 200, 120) },
		grumbles = { wall = rgb(150, 130, 105), floor = rgb(110, 75, 50), sofa = rgb(110, 60, 50), accent = rgb(90, 110, 70), rug = rgb(130, 90, 70) },
		coach = { wall = rgb(236, 236, 240), floor = rgb(160, 115, 75), sofa = rgb(60, 70, 90), accent = rgb(210, 50, 50), rug = rgb(60, 110, 60) },
		skye = { wall = rgb(60, 50, 90), floor = rgb(120, 90, 70), sofa = rgb(120, 80, 220), accent = rgb(255, 80, 190), rug = rgb(40, 200, 200) },
	}

	for _, style in Interiors.STYLES do
		local P = PALETTE[style]
		local c = Interiors.center(style)
		local m = Kit.folder(root, "Interior_" .. style)
		m:SetAttribute("Style", style)
		local function at(x, y, z) return CFrame.new(c + Vector3.new(x, y, z)) end
		local function atR(x, y, z, yaw) return at(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0) end
		local wood = P.floor
		local darkWood = wood:Lerp(Color3.new(0, 0, 0), 0.35)
		local white = rgb(248, 248, 244)

		-- the shell: floor boards, walls with a skirting board and a picture rail, a ceiling with lights
		part(m, "Floor", Vector3.new(W, 1, D), at(0, -0.5, 0), wood, Enum.Material.WoodPlanks)
		part(m, "Ceiling", Vector3.new(W + 2, 1, D + 2), at(0, H + 0.5, 0), rgb(250, 248, 242))
		for _, s in { -1, 1 } do
			part(m, "Wall", Vector3.new(W + 2, H, 1), at(0, H / 2, s * (D / 2 + 0.5)), P.wall)
			part(m, "Wall", Vector3.new(1, H, D + 2), at(s * (W / 2 + 0.5), H / 2, 0), P.wall)
			part(m, "Skirting", Vector3.new(W, 0.8, 0.3), at(0, 0.4, s * (D / 2 - 0.1)), white)
			part(m, "Skirting", Vector3.new(0.3, 0.8, D), at(s * (W / 2 - 0.1), 0.4, 0), white)
			part(m, "PictureRail", Vector3.new(W, 0.3, 0.3), at(0, H - 2.4, s * (D / 2 - 0.1)), white)
			part(m, "PictureRail", Vector3.new(0.3, 0.3, D), at(s * (W / 2 - 0.1), H - 2.4, 0), white)
		end
		for _, lp in { { -11, 0 }, { 11, 0 } } do
			local shade = Kit.cylY(m, "LampShade", 3, 1.2, (at(lp[1], H - 1.4, lp[2])).Position, rgb(255, 240, 210), Enum.Material.SmoothPlastic)
			part(m, "LampCord", Vector3.new(0.15, 1.4, 0.15), at(lp[1], H - 0.4, lp[2]), rgb(40, 40, 40))
			local bulb = Kit.ball(m, "Bulb", 1, (at(lp[1], H - 2.1, lp[2])).Position, rgb(255, 238, 200), Enum.Material.Neon)
			bulb.CanCollide = false
			Kit.light(bulb, 30, 1.3, rgb(255, 232, 196))
			_ = shade
		end

		-- the front wall: the door out (HouseService puts the Leave prompt on it)
		local door = part(m, "Door", Vector3.new(4.4, 7.6, 0.4), at(0, 3.8, D / 2 - 0.3), P.accent)
		door:SetAttribute("InteriorExit", style)
		part(m, "DoorFrame", Vector3.new(5.4, 0.6, 0.6), at(0, 7.9, D / 2 - 0.3), white)
		for _, s in { -1, 1 } do part(m, "DoorFrame", Vector3.new(0.5, 7.9, 0.6), at(s * 2.45, 3.95, D / 2 - 0.3), white) end
		Kit.ball(m, "Knob", 0.4, (at(1.6, 3.7, D / 2 - 0.6)).Position, rgb(220, 190, 90), Enum.Material.Metal)
		part(m, "DoorMat", Vector3.new(5, 0.1, 2.6), at(0, 0.05, D / 2 - 2), P.accent:Lerp(rgb(120, 80, 50), 0.5), Enum.Material.Fabric)
		-- coat hooks by the door
		part(m, "CoatRack", Vector3.new(4, 0.4, 0.3), at(-5, 6.4, D / 2 - 0.3), darkWood, Enum.Material.Wood)
		for k = 0, 2 do part(m, "Coat", Vector3.new(1.2, 2.6, 0.6), at(-6.2 + k * 1.2, 5, D / 2 - 0.7), ({ rgb(200, 60, 60), rgb(60, 90, 160), rgb(230, 190, 60) })[k + 1], Enum.Material.Fabric) end

		-- the back wall: two windows onto a painted garden, with curtains
		for _, wx in { -12, 12 } do
			local pane = part(m, "WindowView", Vector3.new(8, 6, 0.2), at(wx, 7, -D / 2 + 0.05), rgb(150, 200, 240), Enum.Material.Neon, { CanCollide = false })
			local g = Instance.new("SurfaceGui")
			g.Face = Enum.NormalId.Back
			g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			g.PixelsPerStud = 30
			g.LightInfluence = 0
			g.Parent = pane
			local sky = Instance.new("Frame")
			sky.Size = UDim2.fromScale(1, 1)
			sky.BorderSizePixel = 0
			sky.BackgroundColor3 = Color3.new(1, 1, 1)
			sky.Parent = g
			local grad = Instance.new("UIGradient")
			grad.Rotation = 90
			grad.Color = ColorSequence.new(rgb(120, 190, 250), rgb(210, 235, 255))
			grad.Parent = sky
			local grass = Instance.new("Frame")
			grass.AnchorPoint = Vector2.new(0, 1)
			grass.Position = UDim2.fromScale(0, 1)
			grass.Size = UDim2.fromScale(1, 0.32)
			grass.BorderSizePixel = 0
			grass.BackgroundColor3 = rgb(100, 180, 80)
			grass.Parent = sky
			for k = 0, 2 do
				local bush = Instance.new("Frame")
				bush.AnchorPoint = Vector2.new(0.5, 1)
				bush.Position = UDim2.fromScale(0.2 + k * 0.3, 0.74)
				bush.Size = UDim2.fromScale(0.24, 0.3)
				bush.BorderSizePixel = 0
				bush.BackgroundColor3 = rgb(60, 140, 70)
				bush.Parent = sky
				Instance.new("UICorner", bush).CornerRadius = UDim.new(0.5, 0)
			end
			part(m, "WindowFrame", Vector3.new(8.8, 0.5, 0.5), at(wx, 10.2, -D / 2 + 0.2), white)
			part(m, "WindowFrame", Vector3.new(9.4, 0.5, 1.2), at(wx, 3.8, -D / 2 + 0.5), white)
			part(m, "WindowMullion", Vector3.new(0.3, 6, 0.4), at(wx, 7, -D / 2 + 0.2), white)
			part(m, "CurtainRod", Vector3.new(12, 0.25, 0.25), at(wx, 11.2, -D / 2 + 0.8), rgb(120, 100, 80), Enum.Material.Metal)
			for _, s in { -1, 1 } do
				part(m, "Curtain", Vector3.new(2, 8, 0.3), at(wx + s * 5, 7.2, -D / 2 + 0.8), P.accent, Enum.Material.Fabric)
			end
		end

		-- LIVING ROOM (left): a rug, a sofa facing the TV on the left wall, a coffee table, an armchair
		part(m, "Rug", Vector3.new(14, 0.1, 10), at(-12, 0.05, 2), P.rug, Enum.Material.Fabric)
		-- the sofa, facing -x (towards the TV on the left wall)
		local sx = -4
		part(m, "SofaBase", Vector3.new(3.4, 1.6, 9), at(sx, 0.8, 2), P.sofa, Enum.Material.Fabric)
		part(m, "SofaBack", Vector3.new(1.2, 2.6, 9), at(sx + 1.6, 2.4, 2), P.sofa, Enum.Material.Fabric)
		for _, s in { -1, 1 } do part(m, "SofaArm", Vector3.new(3.4, 2.2, 1), at(sx, 1.6, 2 + s * 4.6), P.sofa:Lerp(Color3.new(0, 0, 0), 0.1), Enum.Material.Fabric) end
		for k = -1, 1 do part(m, "Cushion", Vector3.new(2.8, 0.6, 2.8), at(sx - 0.2, 1.9, 2 + k * 2.9), P.sofa:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Fabric) end
		part(m, "Pillow", Vector3.new(0.6, 1.6, 1.6), at(sx + 0.8, 2.6, 5), P.accent, Enum.Material.Fabric)
		-- the coffee table and what's on it
		part(m, "CoffeeTable", Vector3.new(3, 0.4, 5), at(-11, 1.8, 2), darkWood, Enum.Material.Wood)
		for _, dz in { -2, 2 } do part(m, "TableLeg", Vector3.new(2.6, 1.6, 0.4), at(-11, 0.8, 2 + dz), darkWood, Enum.Material.Wood) end
		Kit.cylY(m, "Mug", 0.6, 0.7, (at(-11, 2.35, 3)).Position, P.accent)
		part(m, "Magazine", Vector3.new(1.6, 0.1, 2.2), at(-10.6, 2.05, 0.6) * CFrame.Angles(0, 0.3, 0), rgb(240, 240, 240))
		-- the TV on a stand against the left wall
		part(m, "TVStand", Vector3.new(2.4, 2.4, 9), at(-W / 2 + 1.3, 1.2, 2), darkWood, Enum.Material.Wood)
		part(m, "TV", Vector3.new(0.4, 4, 7), at(-W / 2 + 1.4, 4.6, 2), rgb(20, 20, 24))
		local screen = part(m, "TVScreen", Vector3.new(0.05, 3.5, 6.4), at(-W / 2 + 1.63, 4.6, 2), rgb(60, 100, 160), Enum.Material.Neon)
		Kit.sign(screen, Enum.NormalId.Right, style == "coach" and "\u{1F3C8} TOUCHDOWN!" or style == "grumbles" and "THE WEATHER:\nGRUMPY" or "VEXCORP TV\n\"HOMEWORK IS THE FUTURE\"", rgb(255, 255, 255), nil, Enum.Font.GothamBlack)
		-- the fireplace on the back wall, left of the window, and the bookshelf by the stairs
		part(m, "Fireplace", Vector3.new(7, 6, 1.6), at(-17, 3, -D / 2 + 0.9), rgb(170, 90, 70), Enum.Material.Brick)
		part(m, "Mantel", Vector3.new(8, 0.5, 2.2), at(-17, 6.2, -D / 2 + 1.1), darkWood, Enum.Material.Wood)
		part(m, "Hearth", Vector3.new(4, 3, 0.4), at(-17, 1.8, -D / 2 + 1.75), rgb(30, 24, 22))
		local fire = part(m, "FireGlow", Vector3.new(2.4, 1, 0.4), at(-17, 0.9, -D / 2 + 1.6), rgb(255, 150, 50), Enum.Material.Neon)
		Kit.light(fire, 12, 1, rgb(255, 150, 60))
		for k = -1, 1 do part(m, "MantelFrame", Vector3.new(1.2, 1.4, 0.2), at(-17 + k * 2.4, 7.2, -D / 2 + 0.6), ({ rgb(220, 190, 90), P.accent, rgb(200, 200, 210) })[k + 2]) end

		-- KITCHEN (right, along the back wall): counters with a fridge, a stove, a sink; cupboards
		local kx0 = 4
		part(m, "Counter", Vector3.new(16, 3.2, 3), at(kx0 + 10, 1.6, -D / 2 + 1.6), white)
		part(m, "Worktop", Vector3.new(16.4, 0.3, 3.3), at(kx0 + 10, 3.35, -D / 2 + 1.6), rgb(60, 60, 66), Enum.Material.Granite)
		part(m, "Cupboards", Vector3.new(12, 3, 1.6), at(kx0 + 8, 9, -D / 2 + 0.9), white)
		for k = 0, 2 do part(m, "CupboardDoorLine", Vector3.new(0.1, 3, 1.62), at(kx0 + 4 + k * 4, 9, -D / 2 + 0.9), rgb(200, 200, 200)) end
		part(m, "Fridge", Vector3.new(3.6, 8, 3), at(W / 2 - 2.3, 4, -D / 2 + 1.6), rgb(235, 238, 240), Enum.Material.Metal)
		part(m, "FridgeHandle", Vector3.new(0.2, 2.4, 0.3), at(W / 2 - 3.8, 5, -D / 2 + 3.2), rgb(150, 150, 160), Enum.Material.Metal)
		part(m, "Stove", Vector3.new(3.4, 0.2, 2.6), at(kx0 + 6, 3.55, -D / 2 + 1.6), rgb(30, 30, 34))
		for _, b in { { -0.8, -0.6 }, { 0.8, 0.6 } } do Kit.cylY(m, "Burner", 1.1, 0.1, (at(kx0 + 6 + b[1], 3.7, -D / 2 + 1.6 + b[2])).Position, rgb(200, 60, 40), Enum.Material.Neon) end
		Kit.cylY(m, "Pot", 1.6, 1.2, (at(kx0 + 5.2, 4.3, -D / 2 + 1)).Position, rgb(190, 190, 200), Enum.Material.Metal)
		part(m, "Sink", Vector3.new(3, 0.3, 2), at(kx0 + 13, 3.45, -D / 2 + 1.6), rgb(180, 185, 195), Enum.Material.Metal)
		part(m, "Tap", Vector3.new(0.3, 1.2, 0.3), at(kx0 + 13, 4.1, -D / 2 + 0.7), rgb(190, 190, 200), Enum.Material.Metal)
		Kit.plant(m, "Bush", c.X + kx0 + 16.5, c.Z - D / 2 + 1.6, 0.35, Interiors.Y + 3.5)
		-- the dining table and chairs (right, in the middle)
		part(m, "DiningTable", Vector3.new(8, 0.4, 5), at(13, 3, 3), darkWood, Enum.Material.Wood)
		for _, dx in { -3.4, 3.4 } do for _, dz in { -2, 2 } do part(m, "TableLeg", Vector3.new(0.4, 2.8, 0.4), at(13 + dx, 1.4, 3 + dz), darkWood, Enum.Material.Wood) end end
		for _, ch in { { 10.5, -0.2, 0 }, { 15.5, -0.2, 0 }, { 10.5, 6.2, 180 }, { 15.5, 6.2, 180 } } do
			part(m, "ChairSeat", Vector3.new(2, 0.3, 2), at(ch[1], 1.9, ch[2]), wood, Enum.Material.Wood)
			part(m, "ChairBack", Vector3.new(2, 2.4, 0.3), atR(ch[1], 3.1, ch[2] + (ch[3] == 0 and -0.9 or 0.9), 0), wood, Enum.Material.Wood)
			for _, lx in { -0.8, 0.8 } do for _, lz in { -0.8, 0.8 } do part(m, "ChairLeg", Vector3.new(0.2, 1.8, 0.2), at(ch[1] + lx, 0.9, ch[2] + lz), darkWood, Enum.Material.Wood) end end
		end
		Kit.cylY(m, "FruitBowl", 2, 0.6, (at(13, 3.5, 3)).Position, white)
		for k = 0, 2 do Kit.ball(m, "Fruit", 0.7, (at(12.6 + k * 0.4, 3.9, 3 + (k % 2) * 0.4)).Position, ({ rgb(220, 40, 40), rgb(250, 200, 40), rgb(120, 200, 60) })[k + 1]) end
		-- the stairs up to a landing (back left corner, behind the sofa)
		for k = 0, 9 do
			part(m, "Stair", Vector3.new(4, 1, 1.4), at(-W / 2 + 12 + k * 0, 0.5 + k, -D / 2 + 3 + k * 1.3) * CFrame.new(0, 0, 0), darkWood, Enum.Material.WoodPlanks)
		end
		part(m, "Banister", Vector3.new(0.3, 0.3, 14), at(-W / 2 + 14.2, 6.5, -D / 2 + 8.8) * CFrame.Angles(math.rad(-37), 0, 0), darkWood, Enum.Material.Wood)
		part(m, "Landing", Vector3.new(8, 0.6, 4), at(-W / 2 + 12, 10, -D / 2 + 17.5), darkWood, Enum.Material.WoodPlanks)
		part(m, "Bookshelf", Vector3.new(6, 9, 1.4), at(-W / 2 + 4, 4.5, -D / 2 + 1), darkWood, Enum.Material.Wood)
		for k = 0, 3 do
			part(m, "Shelf", Vector3.new(5.6, 0.2, 1.2), at(-W / 2 + 4, 1 + k * 2.2, -D / 2 + 1.1), wood, Enum.Material.Wood)
			for b = 0, 5 do part(m, "Book", Vector3.new(0.6, 1.6, 1), at(-W / 2 + 1.6 + b * 0.8, 1.9 + k * 2.2, -D / 2 + 1.2), ({ rgb(200, 60, 60), rgb(60, 110, 200), rgb(90, 170, 90), rgb(230, 190, 60), rgb(140, 80, 170), rgb(240, 240, 240) })[(b + k) % 6 + 1]) end
		end
		-- pictures on the right wall
		for k = 0, 1 do
			part(m, "PictureFrame", Vector3.new(0.3, 3, 4), at(W / 2 - 0.2, 8, -2 + k * 8), darkWood, Enum.Material.Wood)
			part(m, "Picture", Vector3.new(0.1, 2.4, 3.4), at(W / 2 - 0.4, 8, -2 + k * 8), ({ rgb(120, 180, 230), rgb(240, 200, 120) })[k + 1])
		end

		-- the styles' own things
		if style == "rose" then
			-- baking: trays of cookies and a pie on the worktop, a rolling pin; a rocking chair and knitting
			for k = 0, 1 do
				part(m, "BakingTray", Vector3.new(3, 0.2, 2), at(kx0 + 9 + k * 3.4, 3.6, -D / 2 + 1.6), rgb(170, 170, 180), Enum.Material.Metal)
				for cx = -1, 1 do for cz = -1, 1, 2 do Kit.cylY(m, "Cookie", 0.6, 0.2, (at(kx0 + 9 + k * 3.4 + cx * 0.9, 3.8, -D / 2 + 1.6 + cz * 0.5)).Position, rgb(200, 150, 90)) end end
			end
			Kit.cylY(m, "Pie", 2, 0.6, (at(13, 3.5, 4.5)).Position, rgb(220, 150, 70))
			part(m, "RockingChair", Vector3.new(2.4, 0.4, 2.4), at(-16, 2, 9), rgb(150, 100, 60), Enum.Material.Wood)
			part(m, "RockingBack", Vector3.new(0.4, 3.2, 2.4), at(-17.1, 3.6, 9), rgb(150, 100, 60), Enum.Material.Wood)
			part(m, "Rocker", Vector3.new(3.4, 0.3, 0.3), at(-16, 0.6, 8) * CFrame.Angles(0, 0, math.rad(8)), rgb(130, 85, 50), Enum.Material.Wood)
			part(m, "Rocker", Vector3.new(3.4, 0.3, 0.3), at(-16, 0.6, 10) * CFrame.Angles(0, 0, math.rad(8)), rgb(130, 85, 50), Enum.Material.Wood)
			Kit.cylY(m, "KnittingBasket", 1.8, 1, (at(-14, 0.5, 11.5)).Position, rgb(190, 150, 90), Enum.Material.Fabric)
			for k = 0, 2 do Kit.ball(m, "Yarn", 0.7, (at(-14.3 + k * 0.4, 1.2, 11.4)).Position, ({ rgb(240, 120, 170), rgb(120, 180, 240), rgb(250, 240, 120) })[k + 1], Enum.Material.Fabric) end
		elseif style == "timmy" then
			-- toys everywhere, drawings on the fridge, Mr. Whiskers' empty bed and a MISSING poster
			for k = 0, 5 do part(m, "ToyBlock", Vector3.new(1, 1, 1), at(-14 + (k % 3) * 1.1, 0.5 + math.floor(k / 3), 8.5), ({ rgb(230, 60, 60), rgb(60, 120, 230), rgb(250, 200, 50) })[k % 3 + 1]) end
			Kit.ball(m, "ToyBall", 1.4, (at(-8, 0.7, 10)).Position, rgb(240, 90, 60))
			part(m, "ToyTruck", Vector3.new(2, 1, 1.2), at(-6, 0.5, -2), rgb(250, 200, 50))
			for k = 0, 2 do part(m, "Drawing", Vector3.new(0.05, 1.2, 1), at(W / 2 - 4.13, 5 + k * 0.4, -D / 2 + 2 + k * 0.4) * CFrame.Angles(0, 0, math.rad(k * 8 - 8)), rgb(250, 250, 250)) end
			Kit.cylY(m, "CatBed", 3, 0.8, (at(-18, 0.4, 12)).Position, rgb(120, 80, 170), Enum.Material.Fabric)
			local poster = part(m, "MissingPoster", Vector3.new(3, 3.6, 0.1), at(8, 7, D / 2 - 0.05) * CFrame.Angles(0, math.pi, 0), rgb(250, 250, 240))
			Kit.sign(poster, Enum.NormalId.Front, "MISSING!\nMR. WHISKERS\n\u{1F408}\nfluffy, orange,\nlikes purple butterflies", rgb(200, 40, 40), rgb(250, 250, 240), Enum.Font.PermanentMarker)
		elseif style == "grumbles" then
			-- a grandfather clock, stacks of newspapers, a framed sign, a big old armchair
			part(m, "GrandfatherClock", Vector3.new(2.4, 10, 1.8), at(W / 2 - 2, 5, 10), rgb(90, 55, 35), Enum.Material.Wood)
			Kit.cylX(m, "ClockFace", 1.8, 0.2, (at(W / 2 - 3.25, 8.4, 10)).Position, rgb(240, 230, 200))
			part(m, "Pendulum", Vector3.new(0.1, 3, 0.4), at(W / 2 - 3.2, 4, 10), rgb(220, 180, 80), Enum.Material.Metal)
			for k = 0, 2 do for j = 0, 4 do part(m, "Newspaper", Vector3.new(2, 0.2, 1.4), at(-18 + k * 2.6, 0.1 + j * 0.2, 12) * CFrame.Angles(0, math.rad(j * 7), 0), rgb(225, 225, 215)) end end
			local sign = part(m, "FramedSign", Vector3.new(0.2, 2.4, 5), at(W / 2 - 0.3, 8, -6) * CFrame.Angles(0, math.pi / 2, 0), rgb(245, 240, 225))
			Kit.sign(sign, Enum.NormalId.Back, "GET OFF MY GRASS\n(this means you)", rgb(150, 30, 30), rgb(245, 240, 225), Enum.Font.GothamBlack)
		elseif style == "coach" then
			-- a trophy shelf, pennants, dumbbells, a whiteboard with a play drawn on it
			part(m, "TrophyShelf", Vector3.new(0.6, 0.3, 10), at(W / 2 - 0.5, 7, -6), darkWood, Enum.Material.Wood)
			for k = 0, 4 do
				Kit.cylY(m, "Trophy", 0.8, 1.4, (at(W / 2 - 0.6, 7.9, -10 + k * 2)).Position, rgb(230, 190, 60), Enum.Material.Metal)
				Kit.ball(m, "TrophyCup", 1, (at(W / 2 - 0.6, 8.8, -10 + k * 2)).Position, rgb(230, 190, 60), Enum.Material.Metal)
			end
			for k = 0, 2 do
				local pn = Instance.new("WedgePart")
				pn.Size = Vector3.new(0.1, 1.4, 3.4)
				pn.CFrame = at(-8 + k * 6, 11, -D / 2 + 0.1) * CFrame.Angles(0, math.rad(90), math.rad(90))
				pn.Color = ({ rgb(210, 50, 50), rgb(50, 90, 200), rgb(240, 200, 50) })[k + 1]
				pn.Anchored = true
				pn.Parent = m
			end
			for _, dz in { -1, 1 } do
				Kit.cylX(m, "Dumbbell", 0.3, 2, (at(-6, 0.4, 11 + dz)).Position, rgb(80, 80, 86), Enum.Material.Metal)
				for _, e in { -1, 1 } do Kit.cylX(m, "Weight", 1, 0.4, (at(-6 + e, 0.5, 11 + dz)).Position, rgb(40, 40, 44), Enum.Material.Metal) end
			end
		elseif style == "skye" then
			-- posters, a skateboard rack, beanbags, fairy lights
			for k = 0, 2 do
				local poster = part(m, "Poster", Vector3.new(0.1, 4, 3), at(W / 2 - 0.1, 7, -10 + k * 5) * CFrame.Angles(0, math.pi / 2, 0), ({ rgb(255, 80, 190), rgb(40, 200, 200), rgb(250, 220, 60) })[k + 1])
				Kit.sign(poster, Enum.NormalId.Back, ({ "SKATE\nOR DIE\n(of fun)", "RECESS\nFOREVER", "\u{1F6F9}\nKICKFLIP\nCLUB" })[k + 1], rgb(20, 20, 30), nil, Enum.Font.PermanentMarker)
			end
			for k = 0, 2 do
				part(m, "RackPeg", Vector3.new(0.3, 0.3, 1), at(-W / 2 + 0.6, 4 + k * 2.4, 8), rgb(60, 60, 66), Enum.Material.Metal)
				part(m, "Skateboard", Vector3.new(0.3, 0.3, 4), at(-W / 2 + 1, 4.3 + k * 2.4, 8), ({ rgb(255, 80, 190), rgb(40, 200, 200), rgb(250, 220, 60) })[k + 1])
			end
			for _, b in { { -14, 10, rgb(255, 80, 190) }, { -9, 11, rgb(40, 200, 200) } } do Kit.ball(m, "Beanbag", 3, (at(b[1], 1.2, b[2])).Position, b[3], Enum.Material.Fabric) end
			for k = 0, 11 do
				local l = Kit.ball(m, "FairyLight", 0.35, (at(-W / 2 + 3 + k * 3.4, H - 2.9, -D / 2 + 0.4)).Position, ({ rgb(255, 80, 190), rgb(40, 200, 200), rgb(250, 220, 60) })[k % 3 + 1], Enum.Material.Neon)
				l.CanCollide = false
			end
		elseif style == "family1" or style == "family2" or style == "family3" then
			-- homework on the dining table (VexCorp worksheets everywhere: the story)
			for k = 0, 3 do part(m, "Worksheet", Vector3.new(1.4, 0.05, 1.8), at(11 + k * 1.2, 3.25, 2.4) * CFrame.Angles(0, math.rad(k * 9 - 12), 0), rgb(235, 225, 250)) end
			local flyer = part(m, "Flyer", Vector3.new(0.05, 2.4, 1.8), at(W / 2 - 4.13, 5.2, -D / 2 + 2.2), rgb(170, 90, 255))
			Kit.sign(flyer, Enum.NormalId.Left, "VEX PREP\nENROL NOW", rgb(255, 255, 255), rgb(170, 90, 255), Enum.Font.GothamBlack)
		end
	end
	return root
end

return Interiors
