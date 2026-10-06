-- Cell coordinates refer to actor origins; feet sit 0.32 cells below them.
-- Fixed stones fill their cell. Movement uses the ground contact, not a whole actor cell.
local Collision = {}
local SpriteLayout = require(if script then script.Parent.SpriteLayout else "./SpriteLayout")
Collision.halfWidth = 0.22
Collision.halfHeight = 0.08
Collision.groundOffset = SpriteLayout.ground[2] - 0.5

function Collision.crossesWall(px, py, x, y, wx, wy)
	local left, right = math.min(px, x) - Collision.halfWidth, math.max(px, x) + Collision.halfWidth
	local top = math.min(py, y) + Collision.groundOffset - Collision.halfHeight
	local bottom = math.max(py, y) + Collision.groundOffset + Collision.halfHeight
	return left < wx + 0.5 - 0.000001
		and right > wx - 0.5 + 0.000001
		and top < wy + 0.5 - 0.000001
		and bottom > wy - 0.5 + 0.000001
end

return Collision
