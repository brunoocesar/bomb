local Feedback = require("../game/Shared/FeedbackPresentation")
local Simulation = require("../game/Shared/Simulation")
local assertions = 0
local function expect(condition, message)
	assertions += 1
	assert(condition, message)
end
local before = { revision = 1, time = 2, tiles = { ["2:2"] = "A", ["1:1"] = "#" }, items = {} }
local after = { revision = 1, time = 3, tiles = { ["1:1"] = "#" }, items = { ["2:2"] = "capacity" } }
local destroyed, revealed = Feedback.changes(before, after)
expect(#destroyed == 1 and destroyed[1].tile == "A", "only removed crate generates fragments")
expect(revealed["2:2"] == 3, "new item gets reveal time")
after.revision = 2
destroyed, revealed = Feedback.changes(before, after)
expect(#destroyed == 0 and next(revealed) == nil, "restart must not look like mass destruction")
for index = 1, 4 do
	for step = 0, 41 do
		local pose = Feedback.fragment(index, step / 100)
		expect(pose.size > 0 and pose.transparency >= 0 and pose.transparency <= 1, "bounded fragment")
	end
	expect(Feedback.fragment(index, Feedback.duration) == nil, "fragment expires")
end
expect(Feedback.item(0).size == Feedback.item(1).size, "item returns to authored size")
expect(Feedback.item(0.25).size > Feedback.item(0).size, "item reveal has visible pop")
expect(
	Feedback.stats({ capacity = 2, range = 3, bombs = { a = {}, b = {} } }) == "BOMBS READY: 0/2\nRANGE: 3 tiles",
	"ready bombs reflect used capacity"
)
expect(Feedback.mount({ frog = true }) == "FROG: 1 HIT", "mount explains protection")
expect(
	Feedback.stats({ capacity = 1, range = 2, bombs = {} }, true) == "BOMBS READY\n1/1\nRANGE: 2 tiles",
	"narrow HUD separates count"
)
expect(Feedback.saveMessage({ saveStatus = "Local Studio session" }) == "", "technical session message hidden")
expect(Feedback.saveMessage({ saveStatus = "Save pending" }) ~= "", "saving feedback preserved")
local sim = Simulation.new({
	width = 7,
	height = 4,
	stages = { { name = "Fixture", rows = { "#######", "#P.A.D#", "#.....#", "#######" } } },
	fuse = 0.2,
	blastDuration = 0.1,
	moveInterval = 0.24,
	enemyInterval = 0.95,
})
sim.range = 3
local snapshot = sim:snapshot()
snapshot.tiles = table.clone(snapshot.tiles)
snapshot.items = table.clone(snapshot.items)
sim:placeBomb()
sim:step(0.25)
destroyed = Feedback.changes(snapshot, sim:snapshot())
expect(#destroyed == 1 and sim.tiles["4:2"] == nil, "collision tile removed immediately despite fragments")
expect(sim.items["4:2"] ~= nil, "reward revealed immediately")
expect(sim.tiles["1:2"] == "#", "wall survives")
print(string.format("Feedback presentation passed: %d assertions.", assertions))
