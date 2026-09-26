-- ServerScriptService.Server.Remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local function event(name)
	local e = folder:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
	end
	return e
end

local function func(name)
	local f = folder:FindFirstChild(name)
	if not f then
		f = Instance.new("RemoteFunction")
		f.Name = name
		f.Parent = folder
	end
	return f
end

-- co-op (CrewService): a push about the SCHOOL (its to-do card, chapter, raids, dailies, a newly
-- unlocked button) or the Board's cutscenes reach everyone who plays for that school, whoever it
-- was sent to; everything else (a heist, a mission, a toast) stays with that one player
local function schoolWide(remote, kinds)
	return setmetatable({
		FireClient = function(_, player, kind, ...)
			if kinds[kind] then
				local Data = require(script.Parent.DataService)
				for _, pl in Data.schoolPlayers(player) do remote:FireClient(pl, kind, ...) end
			else
				remote:FireClient(player, kind, ...)
			end
		end,
		FireAllClients = function(_, ...) remote:FireAllClients(...) end,
		Instance = remote,
	}, { __index = function(_, k) return remote[k] end })
end

local notify = event("Notify")

return {
	Notify = notify, -- (text, kind) toast
	-- a toast about a school (a thief, a cheater, the gate) for everyone who plays for it
	notifySchool = function(player, text, kind)
		local Data = require(script.Parent.DataService)
		for _, pl in Data.schoolPlayers(player) do notify:FireClient(pl, text, kind) end
	end,
	CashPop = event("CashPop"), -- (amount, worldPos) floating +$ text
	Announce = event("Announce"), -- (text, color) big centre text
	Sfx = event("Sfx"), -- (name, worldPos?) play a sound effect
	Cutscene = schoolWide(event("Cutscene"), { Board = true, Finale = true }), -- (name, data) play a client cutscene
	Push = schoolWide(event("Push"), { -- (kind, data) server-pushed UI state (quests, offline earnings...)
		quest = true, questDone = true, chapter = true, chapterStep = true, chapterStart = true,
		raid = true, raidOver = true, dailyQ = true, weeklyQ = true, unlock = true,
	}),
	Action = func("Action"), -- client -> server requests
}
