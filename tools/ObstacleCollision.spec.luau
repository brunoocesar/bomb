local Simulation = require("../game/Shared/Simulation")
local Motion = require("../game/Shared/ActorMotion")
local Collision = require("../game/Shared/ObstacleCollision")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local function fixture()
	return Simulation.new({
		width = 7,
		height = 7,
		stages = { { rows = { "#######", "#P...D#", "#.....#", "#..#..#", "#.....#", "#....E#", "#######" } } },
		moveInterval = 0.24,
		enemyInterval = 0.95,
		fuse = 2.4,
		blastDuration = 0.45,
	})
end
for _, case in ipairs({
	{ 3, 4, "right", 3.28, 4 },
	{ 5, 4, "left", 4.72, 4 },
	{ 4, 3, "down", 4, 3.1 },
	{ 4, 5, "up", 4, 4.500001 },
}) do
	local sim = fixture()
	sim.x, sim.y = case[1], case[2]
	expect(sim:steer(case[3]), "approaches fixed stone from each side")
	for _ = 1, 100 do
		sim:step(0.01, case[3])
		local x, y = Motion.position(sim, sim.time)
		expect(not Collision.crossesWall(x, y, x, y, 4, 4), "feet never enter stone")
		local cx, cy = Motion.cell(sim, sim.time)
		expect(sim.tiles[cx .. ":" .. cy] == nil, "hazards and bombs retain free-cell occupancy")
	end
	local x, y = Motion.position(sim, sim.time)
	expect(math.abs(x - case[4]) < 1e-6 and math.abs(y - case[5]) < 1e-6, "stops at contact or grid safety boundary")
	expect(sim:placeBomb(), "bomb placement remains valid beside stone")
	local opposite = { right = "left", left = "right", down = "up", up = "down" }
	expect(sim:steer(opposite[case[3]]), "leaves stone immediately")
end
local sim = fixture()
sim.x, sim.y = 3.1, 3
sim:step(0.24, "down")
expect(math.abs(sim.y - 4) < 1e-8, "turn with clear feet does not block two entire columns")
sim = fixture()
sim.x, sim.y = 3.4, 3
sim:step(0.24, "down")
expect(math.abs(sim.y - 3.1) < 1e-8, "turn into stone remains blocked")
sim = fixture()
sim.x, sim.y = 3, 4
sim.tiles["4:4"] = "B"
sim:step(0.24, "right")
expect(math.abs(sim.x - 3.28) < 1e-8, "crate cannot be crossed")
sim = fixture()
sim.x, sim.y = 3, 4
sim.tiles["4:4"] = nil
sim.bombs["4:4"] = { x = 4, y = 4, at = 10, range = 2, passThrough = false }
sim:step(0.24, "right")
expect(math.abs(sim.x - 3.28) < 1e-8, "solid bomb cannot be crossed")
sim = fixture()
sim.x, sim.y = 3, 4
sim:placeBomb()
sim:explode("3:4")
expect(sim.blasts["4:4"] == nil and sim.blasts["5:4"] == nil, "stone still blocks the entire explosion ray")
print(string.format("Obstacle collision passed: %d checks.", checks))
