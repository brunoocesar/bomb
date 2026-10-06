local Motion = require("../game/Shared/ActorMotion")
local Layout = require("../game/Shared/SpriteLayout")
local Catalog = require("../game/Shared/SpriteCatalog")
local Simulation = require("../game/Shared/Simulation")
local checks = 0
local function expect(value, message)
	checks += 1
	assert(value, message)
end

local actor = { x = 4, y = 2 }
Motion.begin(actor, 3, 2, 10, 1)
expect(Motion.position(actor, 10) == 4, "movement starts at source")
expect(Motion.position(actor, 10.25) == 3.75, "continuous quarter-step")
expect(Motion.position(actor, 10.5) == 3.5, "continuous midpoint")
expect(Motion.position(actor, 11.5) == 3, "movement clamps at destination")
expect(Motion.cell(actor, 10.25) == 4, "collision remains in source before midpoint")
expect(Motion.cell(actor, 10.75) == 3, "collision follows support into destination")
Motion.begin(actor, 3, 3, 11, 1)
local x, y = Motion.position(actor, 11.5)
expect(x == 3 and y == 2.5, "turn does not introduce a diagonal or teleport")

for _, kind in ipairs({ "hero", "frog" }) do
	for _, direction in ipairs({ "up", "down", "left", "right" }) do
		for _, mounted in ipairs({ false, true }) do
			local sequence = Catalog.animations[kind][kind == "hero" and mounted and "mounted" or "walk"][direction]
			local atlas = Catalog.atlases[sequence[1]]
			for column = sequence[3], sequence[4] do
				local frame = atlas.frames[sequence[2] * 8 + column + 1]
				local width, height, left, top = Layout.frame(frame, kind, mounted, direction)
				local point = kind == "hero" and mounted and Layout.seats[direction] or Layout.ground
				expect(math.abs(left + frame.groundPivot[1] * width - point[1]) < 1e-9, "all frames share support x")
				expect(math.abs(top + frame.groundPivot[2] * height - point[2]) < 1e-9, "all frames share support y")
				expect(math.abs(width / height - frame.rect[3] / frame.rect[4]) < 1e-9, "no sprite deformation")
			end
		end
	end
end
expect(Layout.depth(2) + 1 < Layout.depth(3) + 2, "foreground obstacle occludes actor behind it")
expect(Layout.depth(4) > Layout.depth(3) + 2, "actor below obstacle draws in front")

local function fixture()
	local sim = Simulation.new({
		width = 8,
		height = 4,
		stages = { { rows = { "########", "#P.M.ED#", "#......#", "########" } } },
		moveInterval = 0.24,
		enemyInterval = 1,
		fuse = 2.4,
		blastDuration = 0.45,
	})
	sim.time, sim.invulnerableUntil = 2, 0
	return sim
end
local sim = fixture()
local enemy = sim.enemies[1]
Motion.begin(enemy, 3, 2, sim.time, 1)
sim.blasts["3:2"] = 5
sim:checkHazards()
expect(enemy.alive, "destination blast does not kill enemy still at source")
sim.time = 2.75
sim:checkHazards()
expect(not enemy.alive, "enemy hit when its support reaches dangerous cell")
sim = fixture()
enemy = sim.enemies[1]
Motion.begin(enemy, 3, 2, sim.time, 1)
sim.blasts["4:2"] = 5
sim:checkHazards()
expect(not enemy.alive, "source blast hits enemy before it leaves source")
sim = fixture()
sim.x = 3
enemy = sim.enemies[1]
Motion.begin(enemy, 3, 2, sim.time, 1)
sim:checkHazards()
expect(sim.mode == "playing", "no premature destination contact damage")
sim.time = 2.75
sim:checkHazards()
expect(sim.mode == "dead", "contact damage follows occupied cell")
sim:loadStage()
expect(sim.motion == nil and sim.enemies[1].motion == nil, "checkpoint resets trajectories")
sim = fixture()
sim.enemies = {}
sim:step(0.05, "right")
local earlyX = sim.x
sim:step(0.02, "right")
expect(sim.x > earlyX and sim.motion == nil, "player advances continuously without a destination trajectory")
for _ = 1, 50 do
	sim:step(0.05, "left")
end
local supportX = Motion.position(sim, sim.time)
expect(math.abs(sim.x - 1.72) < 1e-8 and supportX == sim.x, "continuous player stops at wall contact")
print(string.format("Visual motion tests passed: %d assertions.", checks))
