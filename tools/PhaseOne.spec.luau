local Phase = require("../game/Shared/PhaseOne")
local Rewards = require("../game/Shared/PhaseRewards")
local checks = 0
local function expect(condition, message)
	checks += 1
	assert(condition, message)
end
expect(Phase.width == 15 and Phase.height == 13, "External border adds two cells to both dimensions")
expect(#Phase.stages == 2, "Phase 1 contains precisely two stages")
for index, stage in ipairs(Phase.stages) do
	local counts = {}
	expect(#stage.rows == 13, "All authored rows are retained")
	for y, row in ipairs(stage.rows) do
		expect(#row == 15, "Square cell coordinate width")
		expect(row:sub(1, 1) == "#" and row:sub(-1) == "#", "Closed external border")
		if y == 1 or y == 13 then
			expect(row == string.rep("#", 15), "Closed north/south border")
		end
	end
	for _, row in ipairs(stage.internalRows) do
		for x = 1, #row do
			local token = row:sub(x, x)
			counts[token] = (counts[token] or 0) + 1
		end
	end
	expect(counts.B == (index == 1 and 54 or 59), "Breakables match PDF")
	expect(counts["#"] == (index == 1 and 27 or 25), "Permanent pillars match PDF exceptions")
	expect(counts.R == 2 and counts.U == 1 and counts.S == 1, "Exact authored objective and secret counts")
	expect(counts.N == (index == 1 and 2 or 6), "Exact enemy count")
	expect(stage.internalRows[11]:sub(2, 2) == "P", "Safe southwest start")
	expect(stage.internalRows[9]:sub(4, 4) == "U", "Guaranteed power-up position")
	expect(
		stage.rows[3]:sub(4, 4) == "E" and stage.rows[3]:sub(12, 12) == "E",
		"Energy positions include border offset"
	)
	-- Permanent obstacles alone must not isolate any target or reward. This also
	-- verifies that the frog is optional for completion, since it grants no passage.
	local queue = { { 2, 11 } }
	local seen = { ["2:11"] = true }
	local cursor = 1
	while cursor <= #queue do
		local cell = queue[cursor]
		cursor += 1
		for _, delta in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local x, y = cell[1] + delta[1], cell[2] + delta[2]
			local id = x .. ":" .. y
			if x >= 1 and x <= 13 and y >= 1 and y <= 11 and not seen[id] then
				local token = stage.internalRows[y]:sub(x, x)
				if token ~= "#" and token ~= "X" then
					seen[id] = true
					table.insert(queue, { x, y })
				end
			end
		end
	end
	for y, row in ipairs(stage.internalRows) do
		for x = 1, 13 do
			local token = row:sub(x, x)
			if token == "R" or token == "U" or token == "S" or token == "O" or token == "D" then
				expect(seen[x .. ":" .. y], "Every objective/reward can be reached without a mount")
			end
		end
	end
	if index == 1 then
		expect(counts.D == 1 and not counts.X and not counts.O, "Intermediate gate without guaranteed frog")
	else
		expect(counts.X == 6 and not counts.D and counts.O == 1, "Final chest replaces stage gate")
		for y = 5, 6 do
			for x = 6, 8 do
				expect(stage.internalRows[y]:sub(x, x) == "X", "Chest footprint is exactly 3 by 2")
			end
		end
		expect(stage.internalRows[7]:sub(10, 10) == "O", "Authored rescue position")
		expect(stage.enemySpawns[3].kind == "beetle", "Distinct final enemy type")
	end
end
local profile = { coins = 7, deaths = 0 }
expect(Rewards.keyCandidate(profile, Phase.phaseId) == nil, "Locked chest never grants a key")
expect(Rewards.secret(profile, Phase.stages[1]), "First unique secret")
expect(not Rewards.secret(profile, Phase.stages[1]), "Secret does not duplicate")
expect(Rewards.secret(profile, Phase.stages[2]), "Stage 2 has its own secret")
expect(profile.cosmetics.cream_body and profile.cosmetics.yellow_scarf, "Distinct cosmetic grants")
expect(Rewards.unlockChest(profile, Phase.phaseId), "Chest unlock recorded")
local candidate = Rewards.keyCandidate(profile, Phase.phaseId)
expect(candidate.coins == 27 and candidate.finished, "One completion reward in save candidate")
expect(
	not profile.finished and not profile.phaseKeys[Phase.phaseId],
	"Live profile remains unchanged before save confirmation"
)
candidate.phaseSecrets.test = true
expect(not profile.phaseSecrets.test, "Candidate tables do not mutate live state")
local repeated = Rewards.keyCandidate(candidate, Phase.phaseId)
expect(repeated.coins == 27, "Replay does not duplicate key coins")
expect(Rewards.worldKeyCount(repeated, "world1") == 1, "One out of four world keys")
print("PhaseOne: " .. checks .. " checks passed")
