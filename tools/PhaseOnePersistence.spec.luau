local Phase = require("../game/Shared/PhaseOne")
local Simulation = require("../game/Shared/Simulation")
local Rewards = require("../game/Shared/PhaseRewards")
local Repository = require("../game/Server/ProfileRepository")
local checks = 0
local function expect(condition, message)
	checks += 1
	assert(condition, message)
end
local records = {}
local unavailable = false
local store = {}
function store:UpdateAsync(key, transform)
	if unavailable then
		error("Injected transient outage")
	end
	local result = transform(records[key])
	if result then
		records[key] = result
	end
	return result
end
local serial = 0
local repository = Repository.new(store, function()
	return 1000
end, function()
	serial += 1
	return "owner" .. serial
end)
local account = repository.open(1234)
local sim = Simulation.new(Phase, account.data)
sim.profile.cosmetics.cream_body = true
sim.profile.phaseSecrets.world1_phase1_cream = true
sim.capacity = 2
sim:advance()
expect(repository.save(account, sim:checkpoint(), false), "Stage gate checkpoint is saved")
expect(records["1234"].data.stage == 2 and records["1234"].data.capacity == 2, "Upgrade travels with checkpoint")
sim.energy = sim.totalEnergy
sim.range = 3
sim.frog = true
sim:unlockChest()
expect(repository.save(account, sim:checkpoint(), true), "Unlocked but unclaimed chest can be saved on exit")
local secondAccount = repository.open(1234)
local resumed = Simulation.new(Phase, secondAccount.data)
expect(resumed.chestUnlocked and resumed.stage == 2, "Reconnect safely resumes unclaimed chest")
expect(resumed.range == 3 and resumed.frog, "Safe chest resume retains this stage's upgrade and rescued mount")
expect(
	resumed.profile.cosmetics.cream_body and resumed.profile.phaseSecrets.world1_phase1_cream,
	"Sanitization retains permanent cosmetics"
)
resumed.x, resumed.y = 8, 8
expect(resumed:interactChest(), "Chest claim starts")
local candidate = Rewards.keyCandidate(resumed:checkpoint(), Phase.phaseId)
unavailable = true
expect(not repository.save(secondAccount, candidate, false), "Save failure is reported")
expect(resumed.mode == "claiming" and not resumed.profile.finished, "Failure cannot show victory")
expect(not records["1234"].data.phaseKeys[Phase.phaseId], "Failure grants no permanent key")
unavailable = false
expect(repository.save(secondAccount, candidate, false), "Retry succeeds")
expect(resumed:confirmChestClaim(candidate), "Successful persistence confirms victory")
expect(repository.save(secondAccount, resumed:checkpoint(), true), "Release committed completion")
local thirdAccount = repository.open(1234)
expect(
	thirdAccount.data.phaseKeys[Phase.phaseId] and thirdAccount.data.finished,
	"Reconnect retains successful key grant"
)
local repeatCandidate = Rewards.keyCandidate(thirdAccount.data, Phase.phaseId)
expect(repeatCandidate.coins == 20, "Repeat candidate cannot pay twice")
print("PhaseOnePersistence: " .. checks .. " checks passed; injected store, not Roblox cloud transport")
