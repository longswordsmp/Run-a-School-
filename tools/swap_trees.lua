-- Swaps the box trees in workspace.Map (Trunk + stacked Leaves models named "Tree") for the
-- low-poly models in ServerStorage.TownAssets, keeping each tree's spot, size and leaf colour.
-- Edit mode, through _G.oneOff; File > Save afterwards.
return function()
	local lib = game:GetService("ServerStorage"):FindFirstChild("TownAssets")
	if not lib then return "no ServerStorage.TownAssets" end
	local rng = Random.new(5)
	local swapped = 0
	for _, t in workspace.Map:GetDescendants() do
		if t:IsA("Model") and t.Name == "Tree" and t:FindFirstChild("Trunk") and t:FindFirstChild("Leaves") and t.Trunk:IsA("Part") then
			local trunk = t.Trunk
			local s = trunk.Size.Y / 8 -- build_map trees are 8 * s tall at the trunk
			local leafColor = t.Leaves.Color
			local kind = rng:NextNumber() < 0.7 and "Oak" or "Umbrella"
			local m = lib[kind]:Clone()
			m:ScaleTo(s * (kind == "Oak" and 1.15 or 1))
			local base = trunk.Position - Vector3.new(0, trunk.Size.Y / 2, 0)
			m:PivotTo(CFrame.new(base.X, base.Y - 0.2, base.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Leaves" then d.Color = leafColor end
			end
			m.Name = "Tree"
			m.Parent = t.Parent
			t:Destroy()
			swapped += 1
		end
	end
	return "swapped " .. swapped
end
