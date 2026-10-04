local Simulation = {}
Simulation.__index = Simulation
local ActorMotion = require(if script then script.Parent.ActorMotion else "./ActorMotion")
local BlastVisual = require(if script then script.Parent.BlastVisual else "./BlastVisual")
local SkinPacks = require(if script then script.Parent.SkinPacks else "./SkinPacks")

local directions = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }
local patrolOrder = { "left", "up", "right", "down" }
local destructible = { B = true, A = true, L = true, S = true, C = true, E = true }

local function key(x, y)
	return x .. ":" .. y
end

function Simulation.new(definition, saved)
	local self = setmetatable({}, Simulation)
	self.definition = definition
	self.time = 0
	self.events = {}
	self.profile = saved
		or { stage = 1, coins = 0, secret = false, frogUnlocked = false, completed = false, deaths = 0 }
	self.profile.stage = math.clamp(math.floor(self.profile.stage or 1), 1, #definition.stages)
	self.profile.skinPack = SkinPacks.normalize(self.profile.skinPack)
	self.profile.ownedSkinPacks = self.profile.ownedSkinPacks or { [SkinPacks.default] = true }
	if not self.profile.ownedSkinPacks[self.profile.skinPack] then
		self.profile.skinPack = SkinPacks.default
	end
	self.entry = {
		capacity = math.clamp(self.profile.capacity or 1, 1, 3),
		range = math.clamp(self.profile.range or 2, 2, 4),
		frog = self.profile.frog == true,
	}
	self.stage = self.profile.stage
	self:loadStage()
	if self.profile.finished then
		self.mode = "won"
	end
	self:emit("ftue_started")
	return self
end

function Simulation:emit(name)
	self.events[#self.events + 1] = name
end

function Simulation:equipSkinPack(id)
	if type(id) ~= "string" or not SkinPacks.packs[id] or not self.profile.ownedSkinPacks[id] then
		return false
	end
	if self.profile.skinPack ~= id then
		self.profile.skinPack = id
		self:emit("cosmetic_equipped")
	end
	return true
end

function Simulation:loadStage()
	self.tiles, self.bombs, self.blasts, self.items, self.enemies = {}, {}, {}, {}, {}
	self.blastConnections, self.blastCenters = {}, {}
	self.totalEnergy, self.energy = 0, 0
	self.capacity, self.range, self.frog = self.entry.capacity, self.entry.range, self.entry.frog
	self.direction, self.mode = "down", "playing"
	self.motion = nil
	self.nextMove, self.nextEnemy = self.time, self.time + self.definition.enemyInterval
	self.invulnerableUntil = self.time + 1.5
	self.revision = (self.revision or 0) + 1
	for y, row in ipairs(self.definition.stages[self.stage].rows) do
		for x = 1, #row do
			local tile = row:sub(x, x)
			local cell = key(x, y)
			if tile == "P" then
				self.x, self.y = x, y
			elseif tile == "D" then
				self.exitX, self.exitY = x, y
			elseif tile == "M" then
				self.enemies[#self.enemies + 1] = { x = x, y = y, direction = "left", alive = true }
			elseif tile == "F" then
				self.items[cell] = "frog"
			elseif tile ~= "." then
				self.tiles[cell] = tile
				if tile == "E" then
					self.totalEnergy = self.totalEnergy + 1
				end
			end
		end
	end
	self:emit("stage_started")
end

function Simulation:blocked(x, y, actor)
	if x < 1 or y < 1 or x > self.definition.width or y > self.definition.height then
		return true
	end
	if self.tiles[key(x, y)] then
		return true
	end
	if x == self.exitX and y == self.exitY and self.energy < self.totalEnergy then
		return true
	end
	local bomb = self.bombs[key(x, y)]
	return bomb ~= nil and not (actor == "player" and bomb.passThrough)
end

function Simulation:placeBomb()
	if self.mode ~= "playing" then
		return false
	end
	local x, y = ActorMotion.cell(self, self.time)
	local cell = key(x, y)
	local count = 0
	for _ in pairs(self.bombs) do
		count = count + 1
	end
	if self.bombs[cell] or count >= self.capacity or self.tiles[cell] or cell == key(self.exitX, self.exitY) then
		return false
	end
	self.bombs[cell] = { x = x, y = y, at = self.time + self.definition.fuse, range = self.range, passThrough = true }
	if not self.firstBomb then
		self.firstBomb = true
		self:emit("first_bomb")
	end
	self:emit("bomb_placed")
	return true
end

function Simulation:pickup()
	local x, y = ActorMotion.cell(self, self.time)
	local cell = key(x, y)
	local item = self.items[cell]
	if not item then
		return
	end
	self.items[cell] = nil
	if item == "capacity" then
		self.capacity = math.min(self.capacity + 1, 3)
	elseif item == "range" then
		self.range = math.min(self.range + 1, 4)
	elseif item == "frog" then
		self.frog = true
		self.profile.frogUnlocked = true
		self:emit("frog_rescued")
	elseif item == "secret" and not self.profile.secret then
		self.profile.secret = true
		self.profile.coins = self.profile.coins + 10
		self:emit("secret_found")
	elseif item == "coins" and not self.profile.coinCache then
		self.profile.coinCache = true
		self.profile.coins = self.profile.coins + 5
	end
	self:emit("item_collected")
end

function Simulation:damage()
	if self.mode ~= "playing" or self.time < self.invulnerableUntil then
		return
	end
	if self.frog then
		self.frog = false
		self.invulnerableUntil = self.time + 1.5
		self:emit("frog_lost")
	else
		self.profile.deaths = self.profile.deaths + 1
		self.mode = "dead"
		self.respawnAt = self.time + 0.85
		self:emit("player_died")
	end
end

function Simulation:explode(cell)
	local bomb = self.bombs[cell]
	if not bomb then
		return
	end
	self.bombs[cell] = nil
	local untilTime = self.time + self.definition.blastDuration
	self.blastCenters[cell] = untilTime
	self:emit("bomb_exploded")
	local function hit(x, y)
		local target = key(x, y)
		local tile = self.tiles[target]
		if tile == "#" then
			return false
		end
		self.blasts[target] = self.time + self.definition.blastDuration
		if self.bombs[target] then
			self:explode(target)
			return false
		end
		if destructible[tile] then
			self.tiles[target] = nil
			if tile == "E" then
				self.energy = self.energy + 1
				self:emit("energy_box_destroyed")
				if self.energy == self.totalEnergy then
					self:emit("door_opened")
				end
			else
				if not self.firstBlock then
					self.firstBlock = true
					self:emit("first_block_destroyed")
				end
				local reward = { A = "capacity", L = "range", S = "secret", C = "coins" }
				if
					reward[tile]
					and not (tile == "S" and self.profile.secret)
					and not (tile == "C" and self.profile.coinCache)
				then
					self.items[target] = reward[tile]
				end
				self:emit("block_destroyed")
			end
			return false
		end
		return true
	end
	hit(bomb.x, bomb.y)
	for direction, delta in pairs(directions) do
		local previous = cell
		for distance = 1, bomb.range do
			local x, y = bomb.x + delta[1] * distance, bomb.y + delta[2] * distance
			if x < 1 or y < 1 or x > self.definition.width or y > self.definition.height then
				break
			end
			local continues = hit(x, y)
			local target = key(x, y)
			if self.blasts[target] then
				BlastVisual.connect(self.blastConnections, previous, target, direction, untilTime)
			end
			if not continues then
				break
			end
			previous = target
		end
	end
end

function Simulation:checkHazards()
	local playerX, playerY = ActorMotion.cell(self, self.time)
	for _, bomb in pairs(self.bombs) do
		if bomb.passThrough and (bomb.x ~= playerX or bomb.y ~= playerY) then
			bomb.passThrough = false
		end
	end
	if self.blasts[key(playerX, playerY)] then
		self:damage()
	end
	for _, enemy in ipairs(self.enemies) do
		local enemyX, enemyY = ActorMotion.cell(enemy, self.time)
		if enemy.alive and self.blasts[key(enemyX, enemyY)] then
			enemy.alive = false
			self:emit("enemy_defeated")
		end
		if enemy.alive and enemyX == playerX and enemyY == playerY then
			self:damage()
		end
	end
end

function Simulation:advance()
	self:emit("stage_completed")
	if self.stage == #self.definition.stages then
		self.mode = "won"
		if not self.profile.completed then
			self.profile.coins = self.profile.coins + 20
		end
		self.profile.completed = true
		self.profile.finished = true
		self.profile.noDeaths = self.profile.noDeaths or self.profile.deaths == 0
		self:emit("phase_completed")
	else
		self.stage = self.stage + 1
		self.profile.stage = self.stage
		self.entry = { capacity = self.capacity, range = self.range, frog = self.frog }
		self:loadStage()
		self:emit("checkpoint_reached")
	end
end

function Simulation:checkpoint()
	local result = table.clone(self.profile)
	-- Snapshot mutable account data before the asynchronous save starts.
	for _, name in ipairs({ "settings", "daily", "supplies", "ownedSkinPacks" }) do
		if type(result[name]) == "table" then
			result[name] = table.clone(result[name])
		end
	end
	result.capacity, result.range, result.frog = self.entry.capacity, self.entry.range, self.entry.frog
	result.version = 1
	return result
end

function Simulation:restartPhase()
	self.stage, self.profile.stage, self.profile.deaths = 1, 1, 0
	self.profile.finished = false
	self.entry = { capacity = 1, range = 2, frog = false }
	self:loadStage()
	self:emit("phase_started")
end

-- Check both grid lanes under an off-center support. A turn may only start
-- between centers if the whole corridor is clear, including bombs and the gate.
function Simulation:clearPath(px, py, points)
	for _, point in ipairs(points) do
		if px ~= point[1] and py ~= point[2] then
			return false
		end
		for x = math.floor(math.min(px, point[1]) + 0.000001), math.ceil(math.max(px, point[1]) - 0.000001) do
			for y = math.floor(math.min(py, point[2]) + 0.000001), math.ceil(math.max(py, point[2]) - 0.000001) do
				if self:blocked(x, y, "player") then
					return false
				end
			end
		end
		px, py = point[1], point[2]
	end
	return true
end

function Simulation:steer(direction)
	local delta = directions[direction]
	if not delta or self.mode ~= "playing" then
		return false
	end
	local px, py = ActorMotion.position(self, self.time)
	local moving = self.motion and self.time < self.motion.at + self.motion.duration
	local points
	if moving then
		if (self.motion.input or self.direction) == direction then
			self.direction = direction
			return false
		end
		local fx, fy = ActorMotion.position(self, self.time + 0.00001)
		local opposite = delta[1] * (fx - px) + delta[2] * (fy - py) < -0.00000001
		local x = delta[1] < 0 and math.floor(px) or delta[1] > 0 and math.ceil(px) or px
		local y = delta[2] < 0 and math.floor(py) or delta[2] > 0 and math.ceil(py) or py
		if not opposite then
			if delta[1] ~= 0 and x == px then
				x += delta[1]
			end
			if delta[2] ~= 0 and y == py then
				y += delta[2]
			end
		end
		points = { { x, y }, { math.floor(x + 0.5), math.floor(y + 0.5) } }
		if not self:clearPath(px, py, points) then
			-- Beside a solid corner, approach the nearest reachable intersection
			-- instead of finishing the old step in the wrong direction.
			points = nil
			local best = math.huge
			for _, center in ipairs({
				{ math.floor(px), math.floor(py) },
				{ math.ceil(px), math.floor(py) },
				{ math.floor(px), math.ceil(py) },
				{ math.ceil(px), math.ceil(py) },
			}) do
				local candidate = { center, { center[1] + delta[1], center[2] + delta[2] } }
				local distance = math.abs(center[1] - px) + math.abs(center[2] - py)
				if distance < best and self:clearPath(px, py, candidate) then
					points, best = candidate, distance
				end
			end
		end
	else
		if self.time < self.nextMove and direction == self.direction then
			return false
		end
		points = { { self.x + delta[1], self.y + delta[2] } }
	end
	if not points or not self:clearPath(px, py, points) then
		self.direction = direction
		if not moving then
			self.nextMove = self.time + self.definition.moveInterval
		end
		return false
	end
	self.direction = direction
	local duration = ActorMotion.beginPath(self, points, direction, self.time, self.definition.moveInterval)
	self.nextMove = self.time + duration
	if not self.firstMove then
		self.firstMove = true
		self:emit("first_move")
	end
	return true
end

function Simulation:step(dt, direction)
	self.time = self.time + dt
	if self.mode == "dead" then
		if self.time >= self.respawnAt then
			self:loadStage()
		end
		return
	elseif self.mode ~= "playing" then
		return
	end
	for cell, untilTime in pairs(self.blasts) do
		if untilTime <= self.time then
			self.blasts[cell] = nil
			self.blastConnections[cell], self.blastCenters[cell] = nil, nil
		end
	end
	local due = {}
	for cell, bomb in pairs(self.bombs) do
		if bomb.at <= self.time then
			due[#due + 1] = cell
		end
	end
	table.sort(due)
	for _, cell in ipairs(due) do
		self:explode(cell)
	end
	self:checkHazards()
	if self.mode ~= "playing" then
		return
	end
	self:steer(direction)
	self:pickup()
	if self.time >= self.nextEnemy then
		self.nextEnemy = self.time + self.definition.enemyInterval
		for _, enemy in ipairs(self.enemies) do
			if enemy.alive then
				for offset = 0, 3 do
					local index = table.find(patrolOrder, enemy.direction) or 1
					local nextDirection = patrolOrder[(index + offset - 1) % 4 + 1]
					local delta = directions[nextDirection]
					local x, y = enemy.x + delta[1], enemy.y + delta[2]
					if not self:blocked(x, y, "enemy") then
						ActorMotion.begin(enemy, x, y, self.time, self.definition.enemyInterval)
						enemy.direction = nextDirection
						break
					end
				end
			end
		end
	end
	self:checkHazards()
	local occupiedX, occupiedY = ActorMotion.cell(self, self.time)
	if
		self.mode == "playing"
		and occupiedX == self.exitX
		and occupiedY == self.exitY
		and self.energy == self.totalEnergy
	then
		self:advance()
	end
end

function Simulation:snapshot()
	return {
		stage = self.stage,
		revision = self.revision,
		time = self.time,
		mode = self.mode,
		x = self.x,
		y = self.y,
		direction = self.direction,
		motion = self.motion,
		frog = self.frog,
		skinPack = self.profile.skinPack,
		capacity = self.capacity,
		range = self.range,
		energy = self.energy,
		totalEnergy = self.totalEnergy,
		exitX = self.exitX,
		exitY = self.exitY,
		tiles = self.tiles,
		bombs = self.bombs,
		blasts = self.blasts,
		blastConnections = self.blastConnections,
		blastCenters = self.blastCenters,
		items = self.items,
		enemies = self.enemies,
		coins = self.profile.coins,
		secret = self.profile.secret,
		deaths = self.profile.deaths,
		frogUnlocked = self.profile.frogUnlocked,
		invulnerable = self.time < self.invulnerableUntil,
		firstMove = self.firstMove == true,
		firstBomb = self.firstBomb == true,
		firstBlock = self.firstBlock == true,
		noDeathsMedal = self.profile.noDeaths == true,
	}
end

return Simulation
