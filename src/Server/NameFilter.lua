-- ServerScriptService.Server.NameFilter
-- A second net under Roblox's own text filter for anything players name that others see (the school
-- name). Roblox's filter is the real one, but it barely runs in Studio, and a kids' game shouldn't
-- rely on it alone. Server-only, so nobody can read the list to get round it.
--   NameFilter.bad(text) -> true when it's not a friendly name
local NameFilter = {}

-- leet-speak and look-alikes back to letters
local LEET = { ["0"] = "o", ["1"] = "i", ["!"] = "i", ["|"] = "i", ["3"] = "e", ["4"] = "a", ["@"] = "a",
	["5"] = "s", ["$"] = "s", ["7"] = "t", ["+"] = "t", ["8"] = "b", ["9"] = "g", ["6"] = "g" }

-- found anywhere, even squashed together or spaced out ("n i g g a"). (Only roots that rarely hide in
-- ordinary words: "hoe" is in Phoenix and "kys" in Sky School, so those are left to the Roblox filter.)
local ROOTS = {
	"nigg", "niga", "nigr", "nig", "negro", "fag", "faggot", "retard", "tard", "spastic", "tranny", "chink", "spic",
	"kike", "coon", "wetback", "gook", "beaner", "raghead", "towelhead", "kkk", "nazi", "hitler", "heil",
	"fuck", "fuk", "fck", "shit", "bitch", "biatch", "cunt", "whore", "slut", "rape", "rapist",
	"porn", "penis", "vagina", "dick", "cock", "pussy", "boob", "tits", "titty", "sex", "nude", "naked",
	"asshole", "arse", "bastard", "dildo", "jizz", "horny", "killyourself", "suicide",
	"pedo", "molest", "stfu", "wtf", "milf", "thot", "twat", "wank", "bollock",
}
-- real words that contain a root: taken out before the check ("Knight Academy", "Scumble", "Class")
local ALLOW = {
	"knight", "night", "nigel", "nigeria", "niger", "snigger", "sussex", "essex", "middlesex", "cocker",
	"cockatoo", "cockatiel", "peacock", "hancock", "hitchcock", "dickens", "dickson", "scunthorpe",
	"therapist", "grape", "drape", "scrape", "cumulus", "cumber", "document", "cucumber", "accumulate",
	"shitake", "shiitake", "hoek", "shoe", "hoedown", "arsenal", "pedometer", "pedoll", "pedal", "hoes",
	"tardis", "stardust", "stardom", "tardy", "retardant", "mustard", "custard", "bastardo",
	"titanic", "titan", "titled", "petits", "tithe", "fagin", "fagus", "spice", "spick", "hoedown",
	"cocoon", "raccoon", "tycoon", "coonhound", "sextant", "sextet", "boobook", "horn", "spicy",
	"torpedo", "parse", "sparse",
}

-- "niiigga" -> "niga": each run of the same letter down to one (Lua patterns can't repeat a capture)
local function collapse(s)
	local out, last = {}, nil
	for c in s:gmatch(".") do
		if c ~= last then table.insert(out, c) end
		last = c
	end
	return table.concat(out)
end

local function normal(text)
	text = text:lower()
	text = text:gsub(".", function(c) return LEET[c] or c end)
	return text
end

function NameFilter.bad(text)
	if type(text) ~= "string" then return true end
	local s = normal(text)
	-- letters only, squashed together, and again with repeated letters collapsed ("niiigga")
	local squashed = s:gsub("[^%a]", "")
	local collapsed = collapse(squashed)
	for k, form in { squashed, collapsed } do
		local f = form
		for _, ok in ALLOW do
			-- (the collapsed form is checked against the allowed words collapsed the same way: essex, esex)
			f = f:gsub(k == 1 and ok or collapse(ok), " ")
		end
		f = f:gsub(" ", "")
		for _, root in ROOTS do
			if f:find(root, 1, true) then return true end
		end
	end
	return false
end

return NameFilter
