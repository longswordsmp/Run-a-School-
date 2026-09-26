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
local announce = event("Announce")

-- server-wide news (a bus due, recess, someone else's steal, an event starting) skips a principal
-- who is still on the To-Do list: in their first minutes they have enough to take in
local function settled(remote)
	return function(...)
		for _, pl in game:GetService("Players"):GetPlayers() do
			if not pl:GetAttribute("InTutorial") then remote:FireClient(pl, ...) end
		end
	end
end

return {
	Notify = notify, -- (text, kind) toast
	-- a toast about a school (a thief, a cheater, the gate) for everyone who plays for it
	notifySchool = function(player, text, kind)
		local Data = require(script.Parent.DataService)
		for _, pl in Data.schoolPlayers(player) do notify:FireClient(pl, text, kind) end
	end,
	CashPop = event("CashPop"), -- (amount, worldPos) floating +$ text
	Announce = announce, -- (text, color) big centre text
	announceAll = settled(announce), -- the same to everyone past the To-Do list
	notifyAll = settled(notify), -- a toast to everyone past the To-Do list
	Sfx = event("Sfx"), -- (name, worldPos?) play a sound effect
	Cutscene = schoolWide(event("Cutscene"), { Board = true, Finale = true }), -- (name, data) play a client cutscene
	Push = schoolWide(event("Push"), { -- (kind, data) server-pushed UI state (quests, offline earnings...)
		quest = true, questDone = true, chapter = true, chapterStep = true, chapterStart = true,
		raid = true, raidOver = true, dailyQ = true, weeklyQ = true, unlock = true,
	}),
	Action = func("Action"), -- client -> server requests
}
