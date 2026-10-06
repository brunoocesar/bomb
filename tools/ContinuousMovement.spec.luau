local Simulation = require("../game/Shared/Simulation")
local Movement = require("../game/Shared/PlayerMovement")
local checks = 0
local function expect(value, message)
	checks += 1
	assert(value, message)
end
local function fixture()
	return Simulation.new({
		width = 30,
		height = 30,
		stages = { { rows = { "P............................D" } } },
		moveInterval = 0.24,
		enemyInterval = 100,
		fuse = 2.4,
		blastDuration = 0.45,
	})
end
for _, fps in ipairs({ 5, 10, 15, 20, 30, 60, 120, 144 }) do
	local sim = fixture()
	sim.x, sim.y = 10, 10
	for _ = 1, fps * 3 do
		sim:step(1 / fps, "right")
	end
	expect(math.abs(sim.x - 22.5) < 1e-8, "three seconds held at any fps")
	local x, y = sim.x, sim.y
	sim:steer("stop")
	sim:step(0.17)
	expect(sim.x == x and sim.y == y, "release stops at a fractional coordinate")
	sim = fixture()
	sim.x, sim.y = 10, 10
	for _ = 1, fps do
		sim:step(1 / fps, { 1, 1 })
	end
	expect(math.abs(math.sqrt((sim.x - 10) ^ 2 + (sim.y - 10) ^ 2) - 1 / 0.24) < 1e-8, "diagonal speed normalized")
end
for _, first in ipairs({ "left", "right", "up", "down" }) do
	for _, second in ipairs({ "left", "right", "up", "down" }) do
		local sim = fixture()
		sim.x, sim.y = 10, 10
		sim:step(0.037, first)
		local x, y = sim.x, sim.y
		sim:steer(second)
		expect(sim.x == x and sim.y == y, "steering never snaps")
		sim:step(0.019)
		local dx, dy = Movement.vector(second)
		expect(
			math.abs(sim.x - x - dx * 0.019 / 0.24) < 1e-9 and math.abs(sim.y - y - dy * 0.019 / 0.24) < 1e-9,
			"new direction acts immediately at fractional position"
		)
	end
end
for _, kind in ipairs({ "#", "B", "bomb", "gate" }) do
	local sim = fixture()
	sim.x, sim.y = 10, 10
	if kind == "bomb" then
		sim.bombs["11:10"] = { x = 11, y = 10, at = 100, range = 2, passThrough = false }
	elseif kind == "gate" then
		sim.exitX, sim.exitY, sim.totalEnergy = 11, 10, 1
	else
		sim.tiles["11:10"] = kind
	end
	for _ = 1, 60 do
		sim:step(1 / 60, "right")
	end
	expect(math.abs(sim.x - 10.28) < 1e-8, "solid object swept contact")
	local x, y = sim.x, sim.y
	sim:step(0.1, { 1, 1 })
	expect(sim.x == x and sim.y > y, "slides beside solid object")
end
local sim = fixture()
sim.x, sim.y = 10.37, 10.14
expect(sim:placeBomb(), "between-cell placement accepted")
expect(sim.bombs["10:10"] ~= nil and sim.x == 10.37 and sim.y == 10.14, "bomb cell selection never snaps player")
for _ = 1, 30 do
	sim:step(0.01, "right")
end
expect(not sim.bombs["10:10"].passThrough, "bomb becomes solid after entire contact exits")
for _ = 1, 60 do
	sim:step(0.01, "left")
end
expect(math.abs(sim.x - 10.72) < 1e-8, "cannot reenter own bomb")
local snapshot = sim:snapshot()
local x, y = Movement.advance(snapshot, sim.x, sim.y, { 0, 1 }, 0.03, 0.24)
expect(y > sim.y and x == sim.x, "client uses same collision module on snapshot")
print(string.format("Continuous movement passed: %d checks.", checks))
