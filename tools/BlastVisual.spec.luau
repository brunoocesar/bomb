local Simulation = require("../game/Shared/Simulation")
local Visual = require("../game/Shared/BlastVisual")
local checks = 0
local function expect(condition, message)
	checks += 1
	assert(condition, message)
end
local function fixture()
	return Simulation.new({
		width = 9,
		height = 7,
		fuse = 2.4,
		blastDuration = 0.45,
		moveInterval = 0.24,
		enemyInterval = 1,
		stages = {
			{ rows = { "#########", "#P......#", "#.......#", "#.......#", "#.......#", "#.....ED#", "#########" } },
		},
	})
end
local function bomb(sim, x, y, range)
	sim.bombs[x .. ":" .. y] = { x = x, y = y, range = range, at = 2.4 }
end
local function verifyCoverage(sim)
	local state = sim:snapshot()
	for y = 1, sim.definition.height do
		for x = 1, sim.definition.width do
			local key = x .. ":" .. y
			expect(
				(Visual.parts(state, x, y) ~= nil) == (state.blasts[key] ~= nil),
				"visual exactly matches hazardous cells"
			)
			expect(not (state.tiles[key] == "#" and Visual.parts(state, x, y)), "no flame on permanent wall")
		end
	end
end
local sim = fixture()
bomb(sim, 5, 4, 3)
sim:explode("5:4")
verifyCoverage(sim)
local state = sim:snapshot()
local parts = Visual.parts(state, 5, 4)
expect(parts.Core == "blastCore", "origin core")
expect(parts.Up == "blastJoinVertical" and parts.Down == "blastJoinVertical", "core joins vertical arms")
expect(parts.Left == "blastJoinHorizontal" and parts.Right == "blastJoinHorizontal", "core joins horizontal arms")
parts = Visual.parts(state, 6, 4)
expect(
	parts.Core == nil and parts.Left == "blastJoinHorizontal" and parts.Right == "blastJoinHorizontal",
	"intermediate without repeated core/caps"
)
parts = Visual.parts(state, 8, 4)
expect(parts.Left == "blastJoinHorizontal" and parts.Right == "blastTipRight", "right outer cap")
parts = Visual.parts(state, 2, 4)
expect(parts.Left == "blastTipLeft", "left outer cap")
expect(Visual.parts(state, 5, 2).Up == "blastTipUp", "top cap at wall")
expect(Visual.parts(state, 5, 6).Down == "blastTipDown", "bottom cap at wall")

sim = fixture()
sim.tiles["6:4"], sim.tiles["5:3"] = "B", "#"
bomb(sim, 5, 4, 3)
sim:explode("5:4")
verifyCoverage(sim)
state = sim:snapshot()
expect(Visual.parts(state, 5, 4).Up == nil, "no connection into blocking wall")
expect(Visual.parts(state, 6, 4).Right == "blastTipRight", "cap on destroyed crate")
expect(Visual.parts(state, 7, 4) == nil, "no propagation beyond destroyed crate")

sim = fixture()
bomb(sim, 3, 4, 2)
bomb(sim, 5, 4, 2)
sim:explode("3:4")
verifyCoverage(sim)
expect(next(sim.bombs) == nil, "chain still detonates immediately")
expect(Visual.parts(sim:snapshot(), 5, 4).Core == "blastCore", "chain origin retains center")
expect(Visual.parts(sim:snapshot(), 4, 4).Right == "blastJoinHorizontal", "chain link connects continuously")

-- Adjacent independent rays must not create a false corner or connection.
state = {
	time = 0,
	blasts = { ["3:3"] = 1, ["4:3"] = 1, ["3:4"] = 1, ["4:4"] = 1 },
	blastConnections = {},
	blastCenters = {},
}
Visual.connect(state.blastConnections, "3:3", "4:3", "right", 1)
Visual.connect(state.blastConnections, "3:4", "4:4", "right", 1)
expect(Visual.parts(state, 3, 3).Down == nil, "parallel rays don't merge sideways")
expect(Visual.parts(state, 3, 3).Core == nil, "parallel rays don't manufacture centers")
state.time = 1
expect(Visual.parts(state, 3, 3) == nil, "expired cells invisible")
state.time, state.blasts["3:3"], state.blasts["4:3"] = 0.8, 2, 2
state.blastConnections["3:3"].right = 0.7
expect(Visual.parts(state, 3, 3).Right == nil, "expired connection does not leak into newer blast")

sim = fixture()
bomb(sim, 5, 4, 1)
sim:explode("5:4")
sim:step(0.5)
expect(
	next(sim.blasts) == nil and next(sim.blastConnections) == nil and next(sim.blastCenters) == nil,
	"expiry cleans all visual metadata"
)
sim:loadStage()
expect(next(sim.blastConnections) == nil and next(sim.blastCenters) == nil, "restart clears effects")
print(string.format("Blast visuals passed: %d assertions.", checks))
