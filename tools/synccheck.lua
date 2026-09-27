-- Run in Studio (Edit). Compares every script in Studio with git in one call.
-- First, in the repo: python tools/checksum.py > .loop/sums.txt (the file server on 8765 serves it).
-- Returns "113 checked, 0 off", or the scripts that differ or are missing (push those with _G.push).
_G.syncCheck = function()
	local H = game:GetService("HttpService")
	local txt = H:GetAsync("http://127.0.0.1:8765/.loop/sums.txt?" .. os.clock(), true)
	local bad = {}
	local n = 0
	for line in txt:gmatch("[^\n]+") do
		local path, len, sum = line:match("^(%S+) (%d+) (%d+)")
		if path then
			n += 1
			local inst = game
			for part in path:gmatch("[^%.]+") do
				inst = inst and inst:FindFirstChild(part)
			end
			if not inst then
				table.insert(bad, path .. " MISSING")
			else
				local src = inst.Source:gsub("\r\n", "\n"):gsub("\n+$", "")
				local s = 0
				for i = 1, #src do
					s = (s + string.byte(src, i) * ((i - 1) % 251 + 1)) % 2147483648
				end
				if tostring(#src) ~= len or tostring(s) ~= sum then table.insert(bad, path .. " DIFFERS") end
			end
		end
	end
	return ("%d checked, %d off%s"):format(n, #bad, #bad > 0 and (": " .. table.concat(bad, ", ")) or "")
end
return _G.syncCheck()
