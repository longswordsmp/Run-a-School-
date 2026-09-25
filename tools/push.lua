-- Run in Studio (Edit) while `python -m http.server 8765 --bind 127.0.0.1` serves the repo root.
-- Pulls each listed src file into its Studio script (creating it if missing) and returns the
-- same checksum as tools/checksum.py so the push can be verified line by line.
-- HttpEnabled is switched on only for the pull and restored afterwards.
local FILES = { --[[FILES]] }

local MAP = {
	Shared = "ReplicatedStorage.Shared",
	Server = "ServerScriptService.Server",
	Client = "StarterPlayer.StarterPlayerScripts",
}
local HttpService = game:GetService("HttpService")

local function resolve(path)
	local inst = game
	for part in path:gmatch("[^%.]+") do
		inst = inst:FindFirstChild(part) or error("missing " .. path)
	end
	return inst
end

local function checksum(src)
	src = src:gsub("\r\n", "\n"):gsub("\n+$", "")
	local s = 0
	for i = 1, #src do
		s = (s + string.byte(src, i) * ((i - 1) % 251 + 1)) % 2147483648
	end
	return #src, s
end

local was = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local out = {}
local ok, err = pcall(function()
	for _, rel in FILES do
		local folder, file = rel:match("^(%w+)/(.+)$")
		local base, kind = file:match("^(.-)%.(%a+)%.lua$")
		local class = kind == "server" and "Script" or kind == "client" and "LocalScript" or nil
		if not base then
			base = file:gsub("%.lua$", "")
			class = "ModuleScript"
		end
		local parent = resolve(MAP[folder])
		local src = HttpService:GetAsync("http://127.0.0.1:8765/src/" .. rel, true)
		src = src:gsub("\r\n", "\n")
		local inst = parent:FindFirstChild(base)
		if inst and inst.ClassName ~= class then
			error(rel .. " exists as " .. inst.ClassName)
		end
		if not inst then
			inst = Instance.new(class)
			inst.Name = base
			inst.Parent = parent
		end
		inst.Source = src
		local n, s = checksum(inst.Source)
		table.insert(out, ("%s.%s %d %d"):format(MAP[folder], base, n, s))
	end
end)
HttpService.HttpEnabled = was
if not ok then table.insert(out, "ERROR " .. tostring(err)) end
return table.concat(out, "\n")
