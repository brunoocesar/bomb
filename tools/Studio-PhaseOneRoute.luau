-- Studio QA: normal RemoteEvent input only. Forecasts are private copies.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 140221183064352, "Wrong Studio project")
assert(game.Players.LocalPlayer, "Run in Studio client")
local Tutorial = require(game.ReplicatedStorage.Shared.PhaseOne)
local Simulation = require(game.ReplicatedStorage.Shared.Simulation)
local remotes = game.ReplicatedStorage.Assets.TutorialRemotes
local directions = { { "up", 0, -1 }, { "right", 1, 0 }, { "down", 0, 1 }, { "left", -1, 0 } }
local vectors = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }
local latest, sim
local control = { running = true, stop = false, actions = 0 }
-- selene: allow(global_usage)
_G.BombPhaseOneQA = control
local connection = remotes.State.OnClientEvent:Connect(function(state)
	latest = state
	control.stage, control.mode, control.deaths = state.stage, state.mode, state.deaths
end)
local function synchronize()
	local model = Simulation.new(Tutorial, {
		stage = latest.stage,
		deaths = latest.deaths,
		coins = latest.coins,
		frogUnlocked = latest.frogUnlocked,
		phaseSecrets = latest.phaseSecrets,
		cosmetics = latest.cosmetics,
		phaseKeys = latest.phaseKeys,
		phaseChests = {},
		capacity = latest.capacity,
		range = latest.range,
		frog = latest.frog,
	})
	for key, value in pairs(latest) do
		if model[key] ~= nil and type(model[key]) ~= "function" then
			model[key] = value
		end
	end
	return model
end
local function liveWalk(path)
	local stage = latest.stage
	for _, direction in ipairs(path) do
		local vector = vectors[direction]
		local tx = math.floor(latest.x + 0.5) + vector[1]
		local ty = math.floor(latest.y + 0.5) + vector[2]
		local deadline = os.clock() + 2
		repeat
			if control.stop or latest.mode ~= "playing" then
				remotes.Input:FireServer("move", "stop")
				return false
			end
			if latest.stage ~= stage then
				remotes.Input:FireServer("move", "stop")
				return true
			end
			local delta = vector[1] ~= 0 and tx - latest.x or ty - latest.y
			if math.abs(delta) < 0.06 then
				break
			end
			local velocity = math.clamp(delta * 3, -1, 1)
			remotes.Input:FireServer("move", vector[1] ~= 0 and { velocity, 0 } or { 0, velocity })
			task.wait(0.07)
		until os.clock() > deadline
		remotes.Input:FireServer("move", "stop")
		task.wait(0.035)
		if os.clock() > deadline then
			return false
		end
	end
	return true
end
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in pairs(value) do
		result[k] = k == "definition" and v or copy(v)
	end
	return setmetatable(result, getmetatable(value))
end

local function walk(model, path)
	local originalStage = model.stage
	for _, direction in ipairs(path) do
		local vector = vectors[direction]
		local tx = math.floor(model.x + 0.5) + vector[1]
		local ty = math.floor(model.y + 0.5) + vector[2]
		local elapsed = 0
		while model.mode == "playing" and model.stage == originalStage and elapsed < 2 do
			local delta = vector[1] ~= 0 and tx - model.x or ty - model.y
			if math.abs(delta) < 0.06 then
				break
			end
			local velocity = math.clamp(delta * 3, -1, 1)
			model:step(0.07, vector[1] ~= 0 and { velocity, 0 } or { 0, velocity })
			elapsed += 0.07
		end
		model:steer("stop")
		if model.stage ~= originalStage then
			return true
		end
		if model.mode ~= "playing" or elapsed >= 2 then
			return false
		end
		model:step(0.035, "stop")
	end
	return true
end

local function reachable(model)
	local cx, cy = math.floor(model.x + 0.5), math.floor(model.y + 0.5)
	local start = { x = cx, y = cy, path = {} }
	local queue, seen = { start }, { [cx .. ":" .. cy] = true }
	local index = 1
	while index <= #queue do
		local current = queue[index]
		index += 1
		for _, direction in ipairs(directions) do
			local x, y = current.x + direction[2], current.y + direction[3]
			local key = x .. ":" .. y
			if not seen[key] and not model:blocked(x, y, "player") then
				seen[key] = true
				local path = table.clone(current.path)
				path[#path + 1] = direction[1]
				queue[#queue + 1] = { x = x, y = y, path = path }
			end
		end
	end
	return queue
end

local function score(model, cell)
	local value = 0
	for _, direction in ipairs(directions) do
		for distance = 1, model.range do
			local x, y = cell.x + direction[2] * distance, cell.y + direction[3] * distance
			local tile = model.tiles[x .. ":" .. y]
			if tile == "#" or tile == "X" then
				break
			end
			for _, enemy in ipairs(model.enemies) do
				if enemy.alive and enemy.x == x and enemy.y == y then
					value += 15
				end
			end
			if tile then
				value += tile == "E" and 30 or (tile == "S" or tile == "A" or tile == "L") and 12 or 5
				break
			end
		end
	end
	return value - #cell.path * 0.25
end

local function safeBombPlan(cell)
	local model = copy(sim)
	if not walk(model, cell.path) or model.profile.deaths ~= sim.profile.deaths then
		return nil
	end
	if not model:placeBomb() then
		return nil
	end
	local at = model.time
	for _, refuge in ipairs(reachable(model)) do
		if #refuge.path <= 4 then
			local attempt = copy(model)
			if walk(attempt, refuge.path) then
				while attempt.time < at + Tutorial.fuse + Tutorial.blastDuration + 0.15 do
					attempt:step(0.05, "stop")
				end
				if
					attempt.mode == "playing"
					and attempt.profile.deaths == sim.profile.deaths
					and attempt.stage == sim.stage
					and (
						not attempt.chestUnlocked
						or (
							attempt.profile.cosmetics.yellow_scarf
							and attempt.profile.frogUnlocked
							and attempt.range == 3
						)
					)
				then
					return refuge.path
				end
			end
		end
	end
	return nil
end

task.spawn(function()
	local ok, err = pcall(function()
		remotes.Input:FireServer("ready")
		repeat
			task.wait(0.1)
		until latest or control.stop
		assert(latest and latest.phaseId == Tutorial.phaseId, "Wrong active phase")
		remotes.Input:FireServer("pause", false)
		task.wait(0.15)
		local deadline = os.clock() + 600
		while not control.stop and latest.mode ~= "won" and os.clock() < deadline do
			if latest.paused then
				remotes.Input:FireServer("pause", false)
				task.wait(0.1)
			end
			if latest.mode ~= "playing" then
				task.wait(0.2)
				continue
			end
			sim = synchronize()
			local cells = reachable(sim)
			local acted = false
			if sim.chestUnlocked then
				for _, cell in ipairs(cells) do
					local attempt = copy(sim)
					if walk(attempt, cell.path) and attempt:canInteractChest() and liveWalk(cell.path) then
						remotes.Input:FireServer("interact")
						print("BOMB_PHASE1_QA_INTERACT", latest.stage, latest.canInteractChest)
						acted = true
						break
					end
				end
			else
				for _, cell in ipairs(cells) do
					local item = sim.items[cell.x .. ":" .. cell.y]
					local exit = sim.energy == sim.totalEnergy
						and cell.x == sim.exitX
						and cell.y == sim.exitY
						and sim.profile.cosmetics.cream_body
						and sim.capacity == 2
					if item or exit then
						local attempt = copy(sim)
						if walk(attempt, cell.path) and attempt.profile.deaths == sim.profile.deaths then
							acted = liveWalk(cell.path)
							break
						end
					end
				end
				if not acted then
					table.sort(cells, function(a, b)
						return score(sim, a) > score(sim, b)
					end)
					for _, cell in ipairs(cells) do
						if score(sim, cell) > 0 then
							local refuge = safeBombPlan(cell)
							if refuge and liveWalk(cell.path) then
								remotes.Input:FireServer("bomb")
								task.wait(0.06)
								local placed = os.clock()
								liveWalk(refuge)
								while os.clock() < placed + Tutorial.fuse + Tutorial.blastDuration + 0.2 do
									task.wait(0.05)
								end
								acted = true
								break
							end
						end
					end
				end
			end
			control.actions += 1
			print(
				"BOMB_PHASE1_QA_ACTION",
				control.actions,
				latest.stage,
				latest.energy,
				latest.deaths,
				latest.capacity,
				latest.range,
				latest.frogUnlocked
			)
			if not acted then
				task.wait(0.4)
			end
			task.wait(0.08)
		end
		assert(latest.mode == "won", "Route did not complete within deadline")
		assert(latest.phaseKeys[Tutorial.phaseId], "No confirmed key")
		assert(latest.cosmetics.cream_body and latest.cosmetics.yellow_scarf, "Missing secret reward")
		assert(latest.frogUnlocked and latest.capacity == 2 and latest.range == 3, "Missing rescue or upgrades")
		print("BOMB_PHASE1_QA_COMPLETED", control.actions, latest.deaths, latest.coins, latest.saveStatus)
		control.completed = true
	end)
	remotes.Input:FireServer("move", "stop")
	connection:Disconnect()
	control.running = false
	if not ok then
		control.error = tostring(err)
		warn("BOMB_PHASE1_QA_FAILED", err)
	end
end)
