-- ServerScriptService.Server.Actions
-- One RemoteFunction for every client request, routed by name, rate-limited per player.
--   Actions.register("buyUpgrade", function(player, profile, id) ... return { ok = true } end)
local Players = game:GetService("Players")

local Remotes = require(script.Parent.Remotes)
local Data = require(script.Parent.DataService)

local Actions = {}
-- actions that spend or move cash, refused while a School Board review is running
local SPENDING = { buyUpgrade = true, buyRow = true, buySupply = true, buyBuild = true, hireTeacher = true, callLetter = true }
local handlers = {}
local budget = {}

function Actions.register(name, fn)
	handlers[name] = fn
end

Remotes.Action.OnServerInvoke = function(player, action, ...)
	if type(action) ~= "string" then return { ok = false, err = "Bad request" } end
	-- 12 requests per second per player
	local now = os.clock()
	local b = budget[player] or { n = 0, at = now }
	if now - b.at > 1 then
		b.n, b.at = 0, now
	end
	b.n += 1
	budget[player] = b
	if b.n > 12 then return { ok = false, err = "Slow down" } end
	local h = handlers[action]
	local p = Data.get(player)
	if not h or not p then return { ok = false, err = "Not ready" } end
	if p.reviewing and SPENDING[action] then return { ok = false, err = "The School Board is meeting!" } end
	local ok, res = pcall(h, player, p, ...)
	if not ok then
		warn("[Actions]", action, "failed:", res)
		return { ok = false, err = "Something went wrong" }
	end
	return res
end

-- server-side call of a handler as if the player had asked (tests, tutorials)
function Actions.invoke(player, name, ...)
	local h = handlers[name]
	local p = Data.get(player)
	if not h or not p then return { ok = false, err = "Not ready" } end
	if p.reviewing and SPENDING[name] then return { ok = false, err = "The School Board is meeting!" } end
	return h(player, p, ...)
end

Players.PlayerRemoving:Connect(function(player)
	budget[player] = nil
end)

return Actions
