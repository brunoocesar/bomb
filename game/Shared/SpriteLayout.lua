-- Uniform source-pixel scale in square cells; margins never determine placement.
local SpriteLayout = {}
local Catalog = require(if script then script.Parent.SpriteCatalog else "./SpriteCatalog")
local packBounds = {}

function SpriteLayout.fit(atlasId, width, height)
	-- Measure the atlas envelope once. Never fit the changing frame's opaque box.
	local key = type(atlasId) == "table" and table.concat(atlasId, ":") or atlasId
	local bounds = packBounds[key]
	if not bounds then
		bounds = { 0, 0 }
		for _, id in ipairs(type(atlasId) == "table" and atlasId or { atlasId }) do
			for _, frame in ipairs(Catalog.atlases[id].frames) do
				bounds[1] = math.max(bounds[1], frame.opaqueBounds[3])
				bounds[2] = math.max(bounds[2], frame.opaqueBounds[4])
			end
		end
		packBounds[key] = bounds
	end
	return math.min(width / bounds[1], height / bounds[2])
end
SpriteLayout.ground = { 0.5, 0.82 }
SpriteLayout.seats = {
	down = { 0.5, 0.37 },
	up = { 0.5, 0.37 },
	left = { 0.58, 0.37 },
	right = { 0.42, 0.37 },
}

function SpriteLayout.frame(frame, kind, mounted, direction)
	local scale = kind == "mounted" and 0.0032 or kind == "frog" and 0.0065 or mounted and 0.0065 or 0.0075
	local point = kind == "hero" and mounted and SpriteLayout.seats[direction] or SpriteLayout.ground
	local width, height = frame.rect[3] * scale, frame.rect[4] * scale
	return width, height, point[1] - frame.groundPivot[1] * width, point[2] - frame.groundPivot[2] * height
end

function SpriteLayout.depth(y, rows)
	-- Entire arena below HUD (40), with sublayers for frog and rider.
	return 8 + math.floor(math.clamp((y - 1) / ((rows or 9) - 1), 0, 1) * 24)
end

return SpriteLayout
