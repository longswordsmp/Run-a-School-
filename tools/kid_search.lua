-- Run in Studio (Edit) through loadstring (a require() of this yields too long for the MCP bridge).
-- Catalog candidates for the avatar kids (src/Server/KidAvatars.lua): for each
-- { label, slot, query [, minFavourites] } in QUERIES (substituted in), the most relevant catalog items of that
-- slot's type with at least minFavourites (default 100) favourites, up to 6. Returns JSON rows
-- [[label .. " " .. slot, [ids...]], ...] for `python tools/catalog.py rows`.
-- (The catalog allows about one search every two seconds.)
local AES = game:GetService("AvatarEditorService")
local HttpService = game:GetService("HttpService")
local T = Enum.AvatarAssetType
local TYPES = {
	shirt = { T.Shirt }, pants = { T.Pants }, tshirt = { T.TShirt },
	hair = { T.HairAccessory }, hat = { T.Hat }, face = { T.FaceAccessory }, neck = { T.NeckAccessory },
	back = { T.BackAccessory }, front = { T.FrontAccessory }, waist = { T.WaistAccessory },
	shoulder = { T.ShoulderAccessory },
}
local QUERIES = --@QUERIES@
local rows = {}
for _, q in QUERIES do
	local label, slot, query, minFav = q[1], q[2], q[3], q[4] or 100
	task.wait(2.3)
	local p = CatalogSearchParams.new()
	p.SearchKeyword = query
	p.AssetTypes = TYPES[slot]
	p.SortType = Enum.CatalogSortType.Relevance
	local ok, pages = pcall(function() return AES:SearchCatalog(p) end)
	local ids = {}
	if ok then
		for _, it in pages:GetCurrentPage() do
			if (it.FavoriteCount or 0) >= minFav then table.insert(ids, it.Id) end
			if #ids >= 6 then break end
		end
	else
		-- rate limited: wait and try once more
		task.wait(12)
		ok, pages = pcall(function() return AES:SearchCatalog(p) end)
		if ok then
			for _, it in pages:GetCurrentPage() do
				if (it.FavoriteCount or 0) >= minFav then table.insert(ids, it.Id) end
				if #ids >= 6 then break end
			end
		end
	end
	table.insert(rows, { label .. " " .. slot, ids })
end
return HttpService:JSONEncode(rows)
