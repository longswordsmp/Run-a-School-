-- ServerScriptService.Server.Signals
-- Tiny in-process event bus so systems (quests, stats, achievements) can hear what happened
-- without every service requiring every other one.
--   Signals.fire("enroll", player, def, grade)
--   Signals.on("enroll", function(player, def, grade) ... end)
local Signals = {}
local handlers = {}

function Signals.on(name, fn)
	handlers[name] = handlers[name] or {}
	table.insert(handlers[name], fn)
end

function Signals.fire(name, ...)
	for _, fn in handlers[name] or {} do
		task.spawn(fn, ...)
	end
end

return Signals
