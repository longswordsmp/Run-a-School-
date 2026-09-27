-- Run in Studio (Server, during Play), after clicking PLAY and skipping the intro. Sets up a test:
--   _G.dbg(cmd, ...)   the DebugBridge from the command bar (Main.server's debug commands)
--   ReplicatedStorage.TestBot   tools/factorybot.lua as a module the client can require
-- then puts the save on a To-Do step and starts its mission. Edit STEP / MISSION / AT below, or leave
-- them nil to only install the helpers.
local STEP, MISSION, AT = "k09_map", "k_map", Vector3.new(0, 3.5, 36)

local H = game:GetService("HttpService")
_G.dbg = function(cmd, ...)
	local b = game.ServerStorage.DebugBridge
	local seq = (b:GetAttribute("Seq") or 0) + 1
	b:SetAttribute("Request", H:JSONEncode({ cmd = cmd, args = { ... } }))
	b:SetAttribute("Seq", seq)
	local t = os.clock()
	while b:GetAttribute("Done") ~= seq and os.clock() - t < 10 do task.wait() end
	return H:JSONDecode(b:GetAttribute("Response"))
end
local old = game.ReplicatedStorage:FindFirstChild("TestBot")
if old then old:Destroy() end
local m = Instance.new("ModuleScript")
m.Name = "TestBot"
m.Source = H:GetAsync("http://127.0.0.1:8765/tools/factorybot.lua?" .. os.clock(), true)
m.Parent = game.ReplicatedStorage
task.wait(1.5)
local out = {}
if STEP then table.insert(out, "step " .. H:JSONEncode(_G.dbg("tutorialStep", STEP))) task.wait(1) end
if MISSION then table.insert(out, "mission " .. H:JSONEncode(_G.dbg("mission", MISSION))) end
local p = game.Players:GetPlayers()[1]
if AT and p and p.Character then p.Character:PivotTo(CFrame.new(AT)) end
return table.concat(out, " | ")
