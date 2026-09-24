-- Run in Studio (Edit). Same checksum as tools/checksum.py.
local paths = {
	"ReplicatedStorage.Shared.Config",
	"ReplicatedStorage.Shared.UI",
	"ServerScriptService.Server.Walkers",
	"ServerScriptService.Server.Remotes",
	"ServerScriptService.Server.DataService",
	"ServerScriptService.Server.StudentProps",
	"ServerScriptService.Server.StudentFactory",
	"ServerScriptService.Server.PlotService",
	"ServerScriptService.Server.HallService",
	"ServerScriptService.Server.DebugBridge",
	"ServerScriptService.Server.StealService",
	"ServerScriptService.Server.SchoolService",
	"ServerScriptService.Server.Main",
	"StarterPlayer.StarterPlayerScripts.HUD",
	"StarterPlayer.StarterPlayerScripts.Menus",
	"StarterPlayer.StarterPlayerScripts.Prompts",
	"StarterPlayer.StarterPlayerScripts.Effects",
}
local out = {}
for _, p in paths do
	local inst = game
	for part in p:gmatch("[^%.]+") do
		inst = inst and inst:FindFirstChild(part)
	end
	if inst then
		local src = inst.Source:gsub("\r\n", "\n"):gsub("\n+$", "")
		local s = 0
		for i = 1, #src do
			s = (s + string.byte(src, i) * ((i - 1) % 251 + 1)) % 2147483648
		end
		table.insert(out, ("%s %d %d"):format(p, #src, s))
	end
end
return table.concat(out, "\n")
