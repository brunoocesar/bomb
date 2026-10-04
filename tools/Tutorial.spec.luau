local Tutorial = require("../game/Shared/Tutorial")
local Simulation = require("../game/Shared/Simulation")

local assertions = 0
local function expect(condition, message)
	assertions += 1
	assert(condition, message)
end
local function advance(sim, seconds, direction)
	for _ = 1, math.ceil(seconds / 0.05) do
		sim:step(0.05, direction)
	end
end
local function fixture(rows)
	return Simulation.new({
		width = #rows[1],
		height = #rows,
		stages = { { name = "Fixture", rows = rows } },
		fuse = 2.4,
		blastDuration = 0.45,
		moveInterval = 0.24,
		enemyInterval = 0.95,
	})
end

for _, stage in ipairs(Tutorial.stages) do
	expect(#stage.rows == Tutorial.height, "stage height")
	local energy, exits, spawns = 0, 0, 0
	for y, row in ipairs(stage.rows) do
		expect(#row == Tutorial.width, "stage width: " .. row)
		expect(row:sub(1, 1) == "#" and row:sub(-1) == "#", "sealed left/right boundary")
		if y == 1 or y == Tutorial.height then
			expect(row == string.rep("#", Tutorial.width), "sealed top/bottom boundary")
		end
		for x = 1, #row do
			energy += row:sub(x, x) == "E" and 1 or 0
			exits += row:sub(x, x) == "D" and 1 or 0
			spawns += row:sub(x, x) == "P" and 1 or 0
		end
	end
	expect(energy >= 2 and exits == 1 and spawns == 1, "stage objective contract")
end

local sim = fixture({ "#########", "#P.BE..D#", "#.......#", "#########" })
sim.range = 5
expect(sim:placeBomb(), "valid first bomb")
expect(not sim:placeBomb(), "no duplicate bomb")
advance(sim, 0.3, "down")
-- A changed direction starts immediately; release after one cell interval.
advance(sim, 0.25, "right")
advance(sim, 0.25, "up")
local x = sim.x
advance(sim, 0.3, "left")
expect(sim.x == x, "cannot reenter bomb after leaving it")
advance(sim, 0.3, "down")
advance(sim, 1.1)
expect(sim.tiles["4:2"] == nil, "crate destroyed")
expect(sim.tiles["5:2"] == "E", "crate stops blast before energy box")
expect(sim.tiles["1:2"] == "#", "permanent wall survives")
expect(sim.mode == "playing", "escape route survives blast")

sim = fixture({ "#########", "#P...E.D#", "#.......#", "#########" })
sim.capacity = 2
expect(sim:placeBomb(), "first chain bomb")
advance(sim, 0.3, "right")
expect(sim:placeBomb(), "second chain bomb")
advance(sim, 0.3, "down")
advance(sim, 0.3, "right")
advance(sim, 1.6)
expect(next(sim.bombs) == nil, "chain bomb detonates immediately")

sim = fixture({ "#######", "#P..ED#", "#.....#", "#######" })
advance(sim, 1.6)
sim.frog = true
sim:damage()
expect(not sim.frog and sim.mode == "playing", "frog absorbs damage")
sim:damage()
expect(sim.mode == "playing", "damage invulnerability prevents same-tick death")
advance(sim, 1.6)
sim:damage()
expect(sim.mode == "dead" and sim.profile.deaths == 1, "unprotected damage dies")
advance(sim, 0.9)
expect(sim.mode == "playing" and sim.x == 2 and sim.y == 2, "short stage restart")
expect(sim.tiles["5:2"] == "E", "stage reset restores energy boxes")

sim = Simulation.new(Tutorial)
sim.profile.secret = true
sim.profile.coins = 10
sim.items["2:2"] = "secret"
sim:pickup()
expect(sim.profile.coins == 10, "secret reward is idempotent")
sim.capacity = 2
sim.range = 3
sim.frog = true
sim.energy = sim.totalEnergy
sim.x, sim.y = sim.exitX, sim.exitY
sim:step(0.05)
expect(sim.stage == 2 and sim.capacity == 2 and sim.range == 3 and sim.frog, "door carries phase upgrades")
local checkpoint = sim:checkpoint()
local restored = Simulation.new(Tutorial, checkpoint)
expect(restored.stage == 2 and restored.range == 3 and restored.frog, "checkpoint restores viable state")
restored.energy = restored.totalEnergy
restored.x, restored.y = restored.exitX, restored.exitY
restored:step(0.05)
expect(restored.mode == "won" and restored.profile.completed, "last exit completes phase")
local coins = restored.profile.coins
local completedRestore = Simulation.new(Tutorial, restored:checkpoint())
expect(completedRestore.mode == "won", "completed checkpoint restores results")
expect(completedRestore.profile.noDeaths, "no-death medal persists")
restored:restartPhase()
expect(not restored.profile.finished, "replay marks active attempt")
restored.stage = 2
restored:loadStage()
restored.energy = restored.totalEnergy
restored.x, restored.y = restored.exitX, restored.exitY
restored:step(0.05)
expect(restored.profile.coins == coins, "completion reward does not duplicate")

sim = Simulation.new(Tutorial)
local enemy = sim.enemies[1]
local oldX, oldY = enemy.x, enemy.y
advance(sim, 1)
expect(enemy.x ~= oldX or enemy.y ~= oldY, "patrol enemy moves")
expect(not sim:blocked(enemy.x, enemy.y, "enemy"), "enemy patrol respects collision")

print(string.format("Tutorial tests passed: %d assertions.", assertions))
