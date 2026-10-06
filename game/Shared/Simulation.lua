local Simulation = {}
Simulation.__index = Simulation
local ActorMotion = require(if script then script.Parent.ActorMotion else "./ActorMotion")
local BlastVisual = require(if script then script.Parent.BlastVisual else "./BlastVisual")
local SkinPacks = require(if script then script.Parent.SkinPacks else "./SkinPacks")
local PlayerMovement = require(if script then script.Parent.PlayerMovement else "./PlayerMovement")
local PhaseRewards = require(if script then script.Parent.PhaseRewards else "./PhaseRewards")

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
	PhaseRewards.initialize(self.profile)
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
	self.chestUnlocked = false
	self.chest = self.definition.stages[self.stage].chest
	self.exitX, self.exitY = 0, 0
	self.capacity, self.range, self.frog = self.entry.capacity, self.entry.range, self.entry.frog
	self.direction, self.mode = "down", "playing"
	self.motion = nil
	self.input = { 0, 0 }
	self.nextEnemy = self.time + self.definition.enemyInterval
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
				local kind = "patrol"
				for _, spawn in ipairs(self.definition.stages[self.stage].enemySpawns or {}) do
					if spawn.x + 1 == x and spawn.y + 1 == y then
						kind = spawn.kind
					end
				end
				self.enemies[#self.enemies + 1] = {
					x = x,
					y = y,
					direction = "left",
					alive = true,
					kind = kind,
					nextMove = self.time + (kind == "beetle" and 0.65 or self.definition.enemyInterval),
				}
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
	if self.chest and self.profile.phaseChests[self.definition.phaseId] then
		-- A previously unlocked, unclaimed final chest resumes without danger.
		for cell, tile in pairs(self.tiles) do
			if destructible[tile] then
				self.tiles[cell] = nil
			end
		end
		self.energy = self.totalEnergy
		self:unlockChest()
	end
	self:emit("stage_started")
end

function Simulation:unlockChest()
	if not self.chest or self.chestUnlocked then
		return false
	end
	self.chestUnlocked = true
	PhaseRewards.unlockChest(self.profile, self.definition.phaseId)
	self.bombs, self.blasts, self.blastCenters, self.blastConnections = {}, {}, {}, {}
	for _, enemy in ipairs(self.enemies) do
		if enemy.alive then
			enemy.alive = false
			enemy.retired = true
		end
	end
	self:emit("chest_unlocked")
	return true
end

function Simulation:canInteractChest()
	if not self.chestUnlocked or self.mode ~= "playing" then
		return false
	end
	local chest = self.chest
	local left, top = chest.x + 1, chest.y + 1
	local right, bottom = left + chest.width - 1, top + chest.height - 1
	local dx = math.max(left - self.x, 0, self.x - right)
	local dy = math.max(top - self.y, 0, self.y - bottom)
	-- Require an accessible face, not a diagonal corner across a wall.
	return (dx <= 1.25 and dy <= 0.45) or (dy <= 1.25 and dx <= 0.45)
end

function Simulation:interactChest()
	if not self:canInteractChest() then
		return false
	end
	self.mode = "claiming"
	self:steer("stop")
	self:emit("chest_claim_requested")
	return true
end

function Simulation:confirmChestClaim(candidate)
	if self.mode ~= "claiming" or not candidate.phaseKeys[self.definition.phaseId] then
		return false
	end
	for _, field in ipairs({ "phaseKeys", "coins", "completed", "finished", "noDeaths" }) do
		self.profile[field] = candidate[field]
	end
	self.mode = "won"
	self:emit("stage_completed")
	self:emit("phase_completed")
	return true
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
	if self.mode ~= "playing" or self.chestUnlocked then
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
	elseif item == "secret" then
		local stage = self.definition.stages[self.stage]
		if stage.secretId then
			if PhaseRewards.secret(self.profile, stage) then
				self:emit("secret_found")
			end
		elseif not self.profile.secret then
			self.profile.secret = true
			self.profile.coins = self.profile.coins + 10
			self:emit("secret_found")
		end
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
		if tile == "#" or tile == "X" then
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
					if self.chest then
						self:unlockChest()
					else
						self:emit("door_opened")
					end
				end
			else
				if not self.firstBlock then
					self.firstBlock = true
					self:emit("first_block_destroyed")
				end
				local reward = { A = "capacity", L = "range", S = "secret", C = "coins" }
				if
					reward[tile]
					and not (tile == "S" and (self.definition.stages[self.stage].secretId and self.profile.phaseSecrets[self.definition.stages[self.stage].secretId] or not self.definition.stages[self.stage].secretId and self.profile.secret))
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
	if self.chestUnlocked then
		self.bombs, self.blasts, self.blastCenters, self.blastConnections = {}, {}, {}, {}
	end
end

function Simulation:checkHazards()
	if self.chestUnlocked then
		return
	end
	local playerX, playerY = ActorMotion.cell(self, self.time)
	for _, bomb in pairs(self.bombs) do
		if bomb.passThrough and not PlayerMovement.overlapsBomb(self.x, self.y, bomb) then
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
	if self.chest then
		return self:interactChest()
	end
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
	for _, name in ipairs({
		"settings",
		"daily",
		"supplies",
		"ownedSkinPacks",
		"phaseKeys",
		"phaseSecrets",
		"phaseChests",
		"cosmetics",
	}) do
		if type(result[name]) == "table" then
			result[name] = table.clone(result[name])
		end
	end
	if self.chestUnlocked then
		-- Once danger ends, resume the rescued mount and upgrades beside the
		-- claimable chest instead of rolling them back to the stage entrance.
		result.capacity, result.range, result.frog = self.capacity, self.range, self.frog
	else
		result.capacity, result.range, result.frog = self.entry.capacity, self.entry.range, self.entry.frog
	end
	result.version = 2
	result.phaseId = self.definition.phaseId
	return result
end

function Simulation:restartPhase()
	self.stage, self.profile.stage, self.profile.deaths = 1, 1, 0
	self.profile.finished = false
	self.profile.phaseChests[self.definition.phaseId] = nil
	self.entry = { capacity = 1, range = 2, frog = false }
	self:loadStage()
	self:emit("phase_started")
end

-- Input changes velocity only; it never commits a destination cell.
function Simulation:steer(input)
	local vx, vy = PlayerMovement.vector(input)
	self.input = { vx, vy }
	self.direction = PlayerMovement.facing(vx, vy, self.direction)
	self.motion = nil
	return vx ~= 0 or vy ~= 0
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
	if direction ~= nil then
		self:steer(direction)
	end
	local oldX, oldY = self.x, self.y
	self.x, self.y = PlayerMovement.advance(self, self.x, self.y, self.input, dt, self.definition.moveInterval)
	if not self.firstMove and (self.x ~= oldX or self.y ~= oldY) then
		self.firstMove = true
		self:emit("first_move")
	end
	self:pickup()
	if not self.chestUnlocked then
		for _, enemy in ipairs(self.enemies) do
			if enemy.alive and self.time >= (enemy.nextMove or self.nextEnemy) then
				local interval = enemy.kind == "beetle" and 0.65 or self.definition.enemyInterval
				enemy.nextMove = self.time + interval
				for offset = 0, 3 do
					local index = table.find(patrolOrder, enemy.direction) or 1
					local nextDirection = patrolOrder[(index + offset - 1) % 4 + 1]
					local delta = directions[nextDirection]
					local x, y = enemy.x + delta[1], enemy.y + delta[2]
					if not self:blocked(x, y, "enemy") then
						ActorMotion.begin(enemy, x, y, self.time, interval)
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
		width = self.definition.width,
		height = self.definition.height,
		stage = self.stage,
		phaseId = self.definition.phaseId,
		revision = self.revision,
		time = self.time,
		mode = self.mode,
		x = self.x,
		y = self.y,
		direction = self.direction,
		motion = self.motion,
		input = self.input,
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
		chest = self.chest,
		chestUnlocked = self.chestUnlocked,
		canInteractChest = self:canInteractChest(),
		phaseKeys = self.profile.phaseKeys,
		phaseSecrets = self.profile.phaseSecrets,
		cosmetics = self.profile.cosmetics,
		invulnerable = self.time < self.invulnerableUntil,
		firstMove = self.firstMove == true,
		firstBomb = self.firstBomb == true,
		firstBlock = self.firstBlock == true,
		noDeathsMedal = self.profile.noDeaths == true,
	}
end

return Simulation
