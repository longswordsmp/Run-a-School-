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

return {
	Notify = event("Notify"), -- (text, kind) server -> client toast
	CashPop = event("CashPop"), -- (amount, worldPos) server -> client
	Announce = event("Announce"), -- (text, color) big centre text
	Action = func("Action"), -- client -> server requests (name school, upgrade, rebirth...)
}
