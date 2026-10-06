local Phase = require("../game/Shared/PhaseOne")
local Simulation = require("../game/Shared/Simulation")
local Rewards = require("../game/Shared/PhaseRewards")
local checks = 0
local function expect(value, message)
	checks += 1
	assert(value, message)
end
local sim = Simulation.new(Phase)
expect(sim.x == 3 and sim.y == 12, "Spawn converts authored internal coordinates")
expect(sim.totalEnergy == 2 and #sim.enemies == 2, "Stage 1 authored encounters")
expect(sim.exitX == 14 and sim.exitY == 2, "Authored intermediate gate")
expect(sim.enemies[1].kind == "slug", "Slug metadata is preserved")
-- Isolated reward test: the new plant has a normal bale west of U.
-- Full traversal and clearing are covered by PhaseOneRoute, without fixture edits.
sim.tiles["4:10"] = nil
sim.x, sim.y = 4, 10
expect(sim:placeBomb(), "Guaranteed capacity bale can be bombed from its cleared west neighbor")
sim:explode("4:10")
expect(sim.items["5:10"] == "capacity", "Guaranteed capacity upgrade, without random drops")
sim.x, sim.y = 5, 10
sim:pickup()
expect(sim.capacity == 2, "Capacity pickup")
sim.x, sim.y = 13, 6
sim.tiles["13:6"] = nil
sim.items["13:6"] = "secret"
sim:pickup()
expect(sim.profile.cosmetics.cream_body, "Permanent stage 1 cosmetic")
sim.energy = sim.totalEnergy
sim.x, sim.y = sim.exitX, sim.exitY
sim:step(0)
expect(sim.stage == 2 and sim.capacity == 2, "Gate carries the upgrade to stage 2")
expect(#sim.enemies == 6 and sim.enemies[1].kind == "beetle", "Final stage includes its beetle")
expect(sim.exitX == 0 and sim.exitY == 0, "Final stage does not contain a door")
expect(sim.tiles["7:6"] == "X" and sim.tiles["9:7"] == "X", "All chest cells are solid")
sim.x, sim.y = 7, 5
expect(sim:placeBomb(), "Bomb outside chest")
sim:explode("7:5")
expect(sim.tiles["7:6"] == "X" and not sim.blasts["7:6"], "Chest blocks blasts and cannot take damage")
sim.x, sim.y = 11, 8
sim:pickup()
expect(sim.frog and sim.profile.frogUnlocked, "Guaranteed frog rescue")
sim.x, sim.y = 4, 10
sim.bombs = {}
sim:placeBomb()
sim:explode("4:10")
expect(sim.items["5:10"] == "range", "Guaranteed range upgrade")
sim.x, sim.y = 5, 10
sim:pickup()
expect(sim.range == 3, "Range pickup")
sim.items["12:2"] = "secret"
sim.x, sim.y = 12, 2
sim:pickup()
expect(sim.profile.cosmetics.yellow_scarf, "Stage 2 secret remains independent of stage 1")
sim.events = {}
-- Destroy both authored energy boxes using real blast propagation.
for _, x in ipairs({ 4, 12 }) do
	sim.bombs[x .. ":2"] = { x = x, y = 2, range = 2 }
	sim:explode(x .. ":2")
end
expect(sim.energy == 2 and sim.chestUnlocked, "Final targets unlock chest")
expect(not next(sim.bombs) and not next(sim.blasts), "No residual danger after final unlock")
for _, enemy in ipairs(sim.enemies) do
	expect(not enemy.alive and enemy.retired, "Remaining enemies retire without combat defeat")
end
expect(not table.find(sim.events, "enemy_defeated"), "Retiring enemies do not pay combat rewards")
expect(not sim:placeBomb(), "Safe chest state cannot recreate danger")
expect(not sim:interactChest(), "Interaction rejected far from chest")
local saved = sim:checkpoint()
local resumed = Simulation.new(Phase, saved)
expect(resumed.stage == 2 and resumed.chestUnlocked and resumed.energy == 2, "Resume unclaimed unlocked chest")
expect(not next(resumed.bombs) and not next(resumed.blasts), "Resumed stage is safe")
resumed.x, resumed.y = 8, 8
expect(resumed:interactChest(), "Accessible south face can interact")
expect(resumed.mode == "claiming" and not resumed.profile.finished, "Victory awaits successful save")
local candidate = Rewards.keyCandidate(resumed:checkpoint(), Phase.phaseId)
expect(
	candidate.phaseKeys[Phase.phaseId] and not resumed.profile.phaseKeys[Phase.phaseId],
	"Uncommitted key is isolated"
)
expect(resumed:confirmChestClaim(candidate) and resumed.mode == "won", "Confirmed persistence allows victory")
expect(resumed.profile.phaseKeys[Phase.phaseId], "Confirmed world key")
expect(not resumed:confirmChestClaim(candidate), "Duplicate confirmation rejected")
resumed:restartPhase()
expect(resumed.stage == 1 and not resumed.profile.phaseChests[Phase.phaseId], "Replay resets chest stage state")
expect(
	resumed.profile.phaseKeys[Phase.phaseId] and resumed.profile.cosmetics.yellow_scarf,
	"Replay retains permanent rewards"
)
print("PhaseOneSimulation: " .. checks .. " checks passed")
