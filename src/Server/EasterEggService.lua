-- ServerScriptService.Server.EasterEggService
-- Secret easter eggs: three scraps of paper hidden round town, each with part of a code on it. Find all
-- three and you can put the code together: 963GOLDHOVER. Typed into Settings > Codes it gives the Secret
-- Gold Hoverboard, 2.5x as fast as a regular hoverboard (MoveService). A code works for anyone who
-- knows it, once each (that's how codes spread); the scraps are how you find out.
local Players = game:GetService("Players")

local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)

local EasterEggService = {}

local rgb = Color3.fromRGB

-- where the scraps hide: a point in the hiding place (the nearest clear spot with a floor is used, so
-- a scrap is never buried in a wall or a shelf)
local EGGS = {
	{ id = "963", text = "963", at = Vector3.new(-166, 7, 96) }, -- up in the play fort's tall tower, Recess Commons
	{ id = "GOLD", text = "GOLD", at = Vector3.new(485, -47.5, -70) }, -- the sewer's east dead end
	{ id = "HOVER", text = "HOVER", at = Vector3.new(-204, 0.5, -92) }, -- the back corner of the Confiscation Closet
}

-- codes: case and spaces don't matter; each works once per player
local CODES = {
	["963GOLDHOVER"] = {
		reward = "codeBoard",
		text = "\u{1F6F9} SECRET GOLD HOVERBOARD UNLOCKED! 2.5x as fast as a regular hoverboard.",
	},
}
EasterEggService.CODES = CODES

-- the nearest spot to `pos` with room for the scrap and a kid, and a floor under it
local function clearAt(c)
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(c + Vector3.new(0, 2.6, 0)), Vector3.new(2, 4.2, 2), OverlapParams.new()) do
		if part.Transparency < 0.9 and not (part:FindFirstAncestorOfClass("Model") and part:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid")) then
			return false
		end
	end
	return workspace:Raycast(c + Vector3.new(0, 1.5, 0), Vector3.new(0, -3.5, 0), RaycastParams.new())
end
local function spotNear(pos)
	local hit = clearAt(pos)
	if hit then return hit.Position end
	for r = 2, 12, 2 do
		for k = 0, 11 do
			local a = math.rad(k * 30)
			local c = pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			hit = clearAt(c)
			if hit then return hit.Position end
		end
	end
	return pos
end

local function found(player, egg)
	local own = Data.own(player)
	if not own then return end
	own.eggs = own.eggs or {}
	if own.eggs[egg.id] then
		Remotes.Notify:FireClient(player, ("A scrap of paper. It still says: \"%s\""):format(egg.text), "info")
		return
	end
	own.eggs[egg.id] = true
	local n = 0
	for _ in own.eggs do n += 1 end
	Remotes.Sfx:FireClient(player, "Enroll")
	if n >= #EGGS then
		Remotes.Announce:FireClient(player, "SECRET CODE: 963GOLDHOVER", rgb(255, 215, 80))
		Remotes.Notify:FireClient(player, "\u{1F92B} All three scraps! Together they say 963GOLDHOVER. Type it in Settings > Codes.", "good")
	else
		Remotes.Notify:FireClient(player, ("\u{1F4DC} A secret scrap of paper! It says \"%s\". (%d of %d: there are more hidden around town)"):format(egg.text, n, #EGGS), "good")
	end
end

local function buildScrap(folder, egg)
	local at = spotNear(egg.at)
	local p = Instance.new("Part")
	p.Name = "SecretScrap"
	p.Size = Vector3.new(1.3, 0.08, 1.7)
	p.CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, math.rad(23), 0)
	p.Color = rgb(245, 238, 215)
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanTouch = true, false, false
	p.Parent = folder
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.2
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.PermanentMarker
	t.TextScaled = true
	t.Text = egg.text
	t.TextColor3 = rgb(200, 30, 40)
	t.Rotation = 90
	t.Parent = gui
	-- (a faint glint, only when you're close: it's a secret)
	local a = Instance.new("Attachment")
	a.Parent = p
	local glint = Instance.new("ParticleEmitter")
	glint.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	glint.Color = ColorSequence.new(rgb(255, 240, 180))
	glint.Size = NumberSequence.new(0.35, 0)
	glint.Lifetime = NumberRange.new(0.5, 0.9)
	glint.Rate = 2
	glint.Speed = NumberRange.new(0.3, 0.8)
	glint.LightEmission = 1
	glint.Parent = a
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ReadPrompt"
	prompt.ActionText = "Read"
	prompt.ObjectText = "Scrap of paper"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = p
	prompt.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - p.Position).Magnitude > 12 then return end
		found(player, egg)
	end)
end

local function grant(player, def)
	local own = Data.own(player)
	if not own then return end
	if def.reward == "codeBoard" then
		own.codeBoard = true
		player:SetAttribute("CodeGoldBoard", true)
		local GearService = require(script.Parent.GearService)
		if GearService.has and not GearService.has(player, "Hoverboard") then GearService.give(player, "Hoverboard") end
		require(script.Parent.StealService).setSpeed(player)
	end
end

local lastTry = {}
Actions.register("redeemCode", function(player, _, code)
	-- (one try a second: nobody guesses codes by spamming)
	local now = os.clock()
	if lastTry[player] and now - lastTry[player] < 1 then return { ok = false, err = "One code at a time!" } end
	lastTry[player] = now
	if type(code) ~= "string" or #code > 40 then return { ok = false, err = "That's not a code." } end
	code = code:upper():gsub("%s", "")
	local def = CODES[code]
	if not def then return { ok = false, err = "That code doesn't work. Check the spelling!" } end
	local own = Data.own(player)
	if not own then return { ok = false, err = "Not ready" } end
	own.codes = own.codes or {}
	if own.codes[code] then return { ok = false, err = "You've already used that code!" } end
	own.codes[code] = true
	grant(player, def)
	Remotes.Sfx:FireClient(player, "Upgrade")
	Remotes.Announce:FireClient(player, "CODE REDEEMED!", rgb(255, 215, 80))
	return { ok = true, text = def.text }
end)

function EasterEggService.start()
	-- (after the town and Recess Commons are up, so the clear-spot search sees the real buildings)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 60 do
			local town = workspace:FindFirstChild("Town")
			if town and town:FindFirstChild("RecessCommons", true) then break end
			task.wait(1)
		end
		local folder = Instance.new("Folder")
		folder.Name = "SecretScraps"
		folder.Parent = workspace
		for _, egg in EGGS do buildScrap(folder, egg) end
	end)
	-- the code's board comes back every time you join
	local function joined(player)
		for _ = 1, 60 do
			if Data.own(player) then break end
			task.wait(0.5)
		end
		local own = player.Parent and Data.own(player)
		if own and own.codeBoard then
			player:SetAttribute("CodeGoldBoard", true)
			require(script.Parent.StealService).setSpeed(player)
		end
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(joined, player) end)
	for _, player in Players:GetPlayers() do task.spawn(joined, player) end
	Players.PlayerRemoving:Connect(function(player) lastTry[player] = nil end)
end

return EasterEggService
