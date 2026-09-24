-- ServerScriptService.Server.DebugBridge
-- Studio-only test hook. Tools running outside the game VM (the Studio MCP) set
-- ServerStorage.DebugBridge's "Request" attribute to a JSON command and bump "Seq";
-- the game runs it and writes the JSON result to "Response" with the same "Done" seq.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local DebugBridge = {}

function DebugBridge.start(handlers)
	if not RunService:IsStudio() then return end
	local bridge = ServerStorage:FindFirstChild("DebugBridge") or Instance.new("Configuration")
	bridge.Name = "DebugBridge"
	bridge:SetAttribute("Seq", 0)
	bridge:SetAttribute("Done", 0)
	bridge.Parent = ServerStorage
	bridge:GetAttributeChangedSignal("Seq"):Connect(function()
		local seq = bridge:GetAttribute("Seq")
		local ok, result = pcall(function()
			local req = HttpService:JSONDecode(bridge:GetAttribute("Request") or "{}")
			local h = handlers[req.cmd]
			if not h then error("unknown cmd " .. tostring(req.cmd)) end
			local player = Players:GetPlayers()[1]
			return h(player, table.unpack(req.args or {}))
		end)
		bridge:SetAttribute("Response", HttpService:JSONEncode({ ok = ok, result = ok and result or tostring(result) }))
		bridge:SetAttribute("Done", seq)
	end)
end

return DebugBridge
