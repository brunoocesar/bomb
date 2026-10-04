-- Uniform source-pixel scale in square cells; margins never determine placement.
local SpriteLayout = {}
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

function SpriteLayout.depth(y)
	-- Entire arena below HUD (40), with sublayers for frog and rider.
	return 8 + math.floor((y - 1) * 3)
end

return SpriteLayout
