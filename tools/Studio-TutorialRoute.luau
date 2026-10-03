-- Studio-only client controller: sends normal inputs; never teleports or edits server state.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 140221183064352)
assert(game.Players.LocalPlayer, "Run in the Studio client Command Bar")
local Tutorial = require(game.ReplicatedStorage.Shared.Tutorial)
local Simulation = require(game.ReplicatedStorage.Shared.Simulation)
local directions = { { "up", 0, -1 }, { "right", 1, 0 }, { "down", 0, 1 }, { "left", -1, 0 } }
local sim = Simulation.new(Tutorial)
local remotes = game.ReplicatedStorage.Assets.TutorialRemotes
local latest
local nextEnemy = 0
local previousEnemyPosition = ""
local control = { advance = false, stop = false }
_G.BombMapRoute = control
local connection = remotes.State.OnClientEvent:Connect(function(value)
	if value.error then
		control.stop = true
		warn("BOMB_MAP_ROUTE_ERROR", value.error)
		return
	end
	latest = value
	local enemy = value.enemies[1]
	local position = enemy and (enemy.x .. ":" .. enemy.y) or ""
	if position ~= previousEnemyPosition then
		nextEnemy = value.time + Tutorial.enemyInterval
		previousEnemyPosition = position
	end
end)

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
	for _, direction in ipairs(path) do
		local x, y = model.x, model.y
		for _ = 1, 8 do
			model:step(0.05, direction)
			if model.x ~= x or model.y ~= y or model.mode ~= "playing" then
				break
			end
		end
		if (model.x == x and model.y == y) or model.mode ~= "playing" then
			return false
		end
	end
	return true
end

local function reachable(model)
	local start = { x = model.x, y = model.y, path = {} }
	local queue, seen = { start }, { [model.x .. ":" .. model.y] = true }
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
			if tile == "#" then
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
		if #refuge.path <= 7 then
			local attempt = copy(model)
			if walk(attempt, refuge.path) then
				while attempt.time < at + Tutorial.fuse + Tutorial.blastDuration + 0.15 do
					attempt:step(0.05)
				end
				if
					attempt.mode == "playing"
					and attempt.profile.deaths == sim.profile.deaths
					and attempt.stage == sim.stage
				then
					return refuge.path
				end
			end
		end
	end
	return nil
end

local function refreshModel()
	local model = Simulation.new(Tutorial, {
		stage = latest.stage,
		coins = latest.coins,
		secret = latest.secret,
		frogUnlocked = latest.frogUnlocked,
		deaths = latest.deaths,
		capacity = latest.capacity,
		range = latest.range,
		frog = latest.frog,
	})
	for _, name in
		{
			"stage",
			"revision",
			"time",
			"mode",
			"x",
			"y",
			"direction",
			"frog",
			"capacity",
			"range",
			"energy",
			"totalEnergy",
			"exitX",
			"exitY",
			"tiles",
			"bombs",
			"blasts",
			"items",
			"enemies",
		}
	do
		model[name] = copy(latest[name])
	end
	model.nextMove = latest.time + Tutorial.moveInterval
	model.nextEnemy = math.max(nextEnemy, latest.time + 0.05)
	model.invulnerableUntil = latest.invulnerable and latest.time + 0.05 or latest.time
	sim = model
end

local function realWalk(path)
	for _, direction in ipairs(path) do
		if control.stop or latest.mode ~= "playing" then
			return false
		end
		local x, y, stage = latest.x, latest.y, latest.stage
		local deadline = os.clock() + 0.75
		remotes.Input:FireServer("move", direction)
		repeat
			task.wait(0.015)
		until latest.x ~= x
			or latest.y ~= y
			or latest.stage ~= stage
			or latest.mode ~= "playing"
			or os.clock() > deadline
		remotes.Input:FireServer("move", "stop")
		if latest.stage ~= stage then
			return true
		end
		if (latest.x == x and latest.y == y) or latest.mode ~= "playing" then
			return false
		end
	end
	return true
end

local function inspectionStop(label)
	remotes.Input:FireServer("move", "stop")
	remotes.Input:FireServer("pause", true)
	task.wait(0.15)
	-- Freeze gameplay for screenshots while exposing the existing map beneath its pause modal.
	local ui = game.Players.LocalPlayer.PlayerGui.TutorialUI
	local revealMap = game:GetService("RunService").RenderStepped:Connect(function()
		ui.PauseOverlay.Visible = false
	end)
	control.advance = false
	print("BOMB_MAP_ROUTE_INSPECT", label, latest.stage, latest.energy, latest.totalEnergy, latest.deaths)
	while not control.advance and not control.stop do
		task.wait(0.1)
	end
	revealMap:Disconnect()
	remotes.Input:FireServer("pause", false)
end

task.spawn(function()
	local ok, failure = pcall(function()
		remotes.Input:FireServer("ready")
		while not latest do
			task.wait(0.05)
		end
		remotes.Input:FireServer("pause", false)
		local inspectedStage, inspectedExit = 1, 0
		for action = 1, 100 do
			if control.stop or latest.mode == "won" then
				break
			end
			if latest.mode == "dead" then
				task.wait(1)
				continue
			end
			if latest.paused then
				remotes.Input:FireServer("pause", false)
				task.wait(0.1)
			end
			if latest.stage ~= inspectedStage then
				inspectedStage = latest.stage
				inspectionStop("stage-entry")
			end
			if latest.energy == latest.totalEnergy and inspectedExit ~= latest.stage then
				inspectedExit = latest.stage
				inspectionStop("exit-open")
			end
			refreshModel()
			local cells = reachable(sim)
			local acted = false
			for _, cell in ipairs(cells) do
				local item = sim.items[cell.x .. ":" .. cell.y]
				local exit = sim.energy == sim.totalEnergy and cell.x == sim.exitX and cell.y == sim.exitY
				if item or exit then
					local attempt = copy(sim)
					walk(attempt, cell.path)
					if attempt.profile.deaths == sim.profile.deaths then
						realWalk(cell.path)
						acted = true
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
						if refuge then
							if realWalk(cell.path) then
								remotes.Input:FireServer("bomb")
								realWalk(refuge)
								local untilTime = os.clock() + Tutorial.fuse + Tutorial.blastDuration + 0.2
								repeat
									task.wait(0.05)
								until os.clock() >= untilTime or latest.mode == "dead"
							end
							acted = true
							break
						end
					end
				end
			end
			if not acted then
				error("No safe route plan at " .. latest.stage .. ":" .. latest.x .. ":" .. latest.y)
			end
			task.wait(0.1)
		end
		print(
			"BOMB_MAP_ROUTE_RESULT",
			latest.mode,
			latest.stage,
			latest.energy,
			latest.totalEnergy,
			latest.deaths,
			latest.frogUnlocked
		)
	end)
	remotes.Input:FireServer("move", "stop")
	connection:Disconnect()
	if not ok then
		warn("BOMB_MAP_ROUTE_ERROR", failure)
	end
end)
