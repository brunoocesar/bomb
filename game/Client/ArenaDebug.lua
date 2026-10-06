-- Studio-only, lazy overlay. Set TutorialUI attribute ArenaDebug to true to enable.
local ArenaDebug = {}
local Collision = require(game:GetService("ReplicatedStorage").Shared.ObstacleCollision)
ArenaDebug.__index = ArenaDebug

function ArenaDebug.new(board, width, height)
	return setmetatable({ board = board, width = width, height = height }, ArenaDebug)
end

function ArenaDebug:enable(enabled)
	if not enabled then
		if self.root then
			self.root.Visible = false
		end
		return
	end
	if self.root then
		self.root.Visible = true
		return
	end
	local root = Instance.new("Frame")
	root.Name = "ArenaDebugOverlay"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.ZIndex = 38
	root.Parent = self.board
	self.root, self.cells, self.actors = root, {}, {}
	for y = 1, self.height do
		for x = 1, self.width do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.fromScale(1 / self.width, 1 / self.height)
			cell.Position = UDim2.fromScale((x - 1) / self.width, (y - 1) / self.height)
			cell.BackgroundTransparency = 1
			cell.BorderSizePixel = 1
			cell.BorderColor3 = Color3.fromRGB(100, 220, 255)
			cell.ZIndex = 38
			cell.Parent = root
			self.cells[x .. ":" .. y] = cell
		end
	end
end

function ArenaDebug:actor(name, x, y, cellX, cellY, visible)
	if not self.root or not self.root.Visible then
		return
	end
	local actor = self.actors[name]
	if not actor then
		local box = Instance.new("Frame")
		box.Name = name .. "CollisionCell"
		box.Size = UDim2.fromScale(1 / self.width, 1 / self.height)
		box.BackgroundTransparency = 1
		box.BorderColor3 = Color3.fromRGB(255, 230, 50)
		box.BorderSizePixel = 2
		box.ZIndex = 39
		box.Parent = self.root
		local contact = Instance.new("Frame")
		contact.Name = name .. "GroundContact"
		contact.Size = UDim2.fromScale(2 * Collision.halfWidth / self.width, 2 * Collision.halfHeight / self.height)
		contact.BackgroundTransparency = 0.65
		contact.BackgroundColor3 = Color3.fromRGB(80, 255, 110)
		contact.BorderSizePixel = 1
		contact.BorderColor3 = contact.BackgroundColor3
		contact.ZIndex = 39
		contact.Parent = self.root
		local dot = Instance.new("Frame")
		dot.Name = name .. "GroundPoint"
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Size = UDim2.fromOffset(5, 5)
		dot.BackgroundColor3 = Color3.fromRGB(255, 80, 180)
		dot.BorderSizePixel = 0
		dot.ZIndex = 39
		dot.Parent = self.root
		actor = { box = box, dot = dot, contact = contact }
		self.actors[name] = actor
	end
	actor.box.Visible, actor.dot.Visible = visible, visible
	actor.contact.Visible = visible and name == "Player"
	actor.contact.Position = UDim2.fromScale(
		(x - 0.5 - Collision.halfWidth) / self.width,
		(y - 0.5 + Collision.groundOffset - Collision.halfHeight) / self.height
	)
	actor.box.Position = UDim2.fromScale((cellX - 1) / self.width, (cellY - 1) / self.height)
	actor.dot.Position = UDim2.fromScale((x - 0.5) / self.width, (y - 0.18) / self.height)
end

function ArenaDebug:obstacles(state)
	if not self.root or not self.root.Visible then
		return
	end
	for cell, view in pairs(self.cells) do
		local solid = state.tiles[cell]
			or state.bombs[cell]
			or (cell == state.exitX .. ":" .. state.exitY and state.energy < state.totalEnergy)
		view.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		view.BackgroundTransparency = solid and 0.7 or 1
	end
end

return ArenaDebug
