-- ServerScriptService.Server.AreaService
-- The town's locked areas (Config.Areas, docs/TOWN.md). An area is open for a player when their
-- school has reached what it needs (the tutorial, a chapter; later a story quest), or they opened
-- it themselves (a quest reward, or UNLOCK NOW for Robux: saved in their own save as p.areas).
--   attributes  Area_<id> = true on the player for each open area; the client draws a glowing barrier
--               at a closed area's gate (only that player's client has it, so it only stops them)
--   the guard   twice a second, anyone standing in an area that isn't open for them is sent back
--               to its gate (so a barrier can't be walked around or skipped)
--   pushes      "areaOpen" { id } the moment an area opens (the client shows the reveal)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local AreaService = {}

local function inBox(pos, b)
	if pos.X < b.x0 or pos.X > b.x1 or pos.Z < b.z0 or pos.Z > b.z1 then return false end
	if b.y1 and pos.Y > b.y1 then return false end
	if not b.y1 and pos.Y < -40 then return false end -- (the underground Lair is its own area)
	return true
end
AreaService.inBox = inBox

-- does the player's school meet what the area needs?
local function earned(player, area)
	local p = Data.get(player)
	if not p then return false end
	local n = area.needs or {}
	if n.tutorial and (p.tutorial or 1) <= #Config.Tutorial then return false end
	if n.chapter then
		if (p.tutorial or 1) <= #Config.Tutorial then return false end
		local ch = p.chapter and p.chapter.n or 1
		if p.finaleSeen then ch = 99 end
		if ch < n.chapter then return false end
	end
	if n.quest then
		local own = Data.own(player)
		local done = own and own.tq and own.tq.done
		if not (done and done[n.quest]) then return false end
	end
	return true
end

function AreaService.isOpen(player, id)
	local area = Config.AreaById[id]
	if not area then return true end
	local own = Data.own(player)
	if own and own.areas and own.areas[id] then return true end
	return earned(player, area)
end

-- open an area for good (a quest reward, a purchase, the admin panel)
function AreaService.open(player, id, quiet)
	local own = Data.own(player)
	if not own or not Config.AreaById[id] then return false end
	own.areas = own.areas or {}
	if own.areas[id] then return true end
	own.areas[id] = true
	AreaService.refresh(player, quiet)
	-- (their own save, not the school's: saveSoon would save a co-op host's)
	task.spawn(Data.save, player)
	return true
end

local shown = {} -- [player] = { [id] = true }: open areas already announced this session

-- mirror each area onto the player (Area_<id>) and announce any that just opened
function AreaService.refresh(player, quiet)
	if not player.Parent then return end
	shown[player] = shown[player] or {}
	for _, area in Config.Areas do
		local open = AreaService.isOpen(player, area.id)
		if player:GetAttribute("Area_" .. area.id) ~= (open or nil) then
			player:SetAttribute("Area_" .. area.id, open or nil)
		end
		if open and not shown[player][area.id] then
			shown[player][area.id] = true
			-- (on joining, areas that were already open aren't news)
			if not quiet and player:GetAttribute("AreasReady") then
				Remotes.Push:FireClient(player, "areaOpen", { id = area.id })
				Signals.fire("areaOpen", player, area.id)
			end
		end
	end
	player:SetAttribute("AreasReady", true)
end

-- the spot just outside an area's gate (where a trespasser is put back)
local function outside(area)
	local g = area.gate
	if not g then return Vector3.new(0, 4, -18) end
	local b = area.box
	local cx, cz = (b.x0 + b.x1) / 2, (b.z0 + b.z1) / 2
	local dir
	if g.alongX then dir = Vector3.new(0, 0, (g.z > cz) and 1 or -1) else dir = Vector3.new((g.x > cx) and 1 or -1, 0, 0) end
	-- (the gate is on the area's edge: step out of it, away from the area's middle)
	return Vector3.new(g.x, 4, g.z) + dir * 12
end
AreaService.outside = outside

local function guard()
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local pos = root.Position
			for _, area in Config.Areas do
				if inBox(pos, area.box) and not AreaService.isOpen(player, area.id) then
					local to = area.id == "Lair" and Vector3.new(560, 6, 0) or outside(area)
					player.Character:PivotTo(CFrame.new(to))
					Remotes.Notify:FireClient(player, ("\u{1F512} %s is locked. %s to open it."):format(area.name, area.hint), "bad")
					break
				end
			end
		end
	end
end

function AreaService.start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			for _ = 1, 60 do
				if Data.own(player) then break end
				task.wait(0.5)
			end
			AreaService.refresh(player, true)
		end)
	end)
	for _, player in Players:GetPlayers() do task.spawn(AreaService.refresh, player, true) end
	Players.PlayerRemoving:Connect(function(player) shown[player] = nil end)
	-- progress that can open an area: re-check (cheap: a few table reads per player)
	for _, sig in { "questDone", "review", "chapterDone", "questStep", "crewJoin" } do
		Signals.on(sig, function(player)
			if typeof(player) == "Instance" and player:IsA("Player") then
				for _, pl in Data.schoolPlayers(player) do AreaService.refresh(pl) end
			end
		end)
	end
	task.spawn(function()
		local n = 0
		while true do
			task.wait(0.5)
			n += 1
			local ok, err = pcall(guard)
			if not ok then warn("[Areas]", err) end
			-- (and every few seconds, catch anything that opened an area without a signal)
			if n % 10 == 0 then
				for _, player in Players:GetPlayers() do pcall(AreaService.refresh, player) end
			end
		end
	end)
end

return AreaService
