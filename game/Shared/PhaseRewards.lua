-- Server-owned, idempotent permanent rewards. No gameplay stats are sold or unlocked.
local Rewards = {}

function Rewards.initialize(profile)
	profile.phaseKeys = type(profile.phaseKeys) == "table" and profile.phaseKeys or {}
	profile.phaseSecrets = type(profile.phaseSecrets) == "table" and profile.phaseSecrets or {}
	profile.cosmetics = type(profile.cosmetics) == "table" and profile.cosmetics or {}
	profile.phaseChests = type(profile.phaseChests) == "table" and profile.phaseChests or {}
	profile.ownedSkinPacks = type(profile.ownedSkinPacks) == "table" and profile.ownedSkinPacks or { base = true }
	-- Recover complete packs from previously saved secret grants as well.
	if profile.cosmetics.cream_body then
		profile.ownedSkinPacks.cream = true
	end
	if profile.cosmetics.yellow_scarf then
		profile.ownedSkinPacks.scarf = true
	end
end

function Rewards.secret(profile, stage)
	Rewards.initialize(profile)
	if profile.phaseSecrets[stage.secretId] then
		return false
	end
	profile.phaseSecrets[stage.secretId] = true
	profile.cosmetics[stage.secretReward] = true
	Rewards.initialize(profile)
	return true
end

function Rewards.unlockChest(profile, phaseId)
	Rewards.initialize(profile)
	if profile.phaseChests[phaseId] then
		return false
	end
	profile.phaseChests[phaseId] = true
	return true
end

-- Apply to a SAVE CANDIDATE. The live simulation must wait for the repository to
-- confirm persistence before presenting victory. Never grant on a client request.
function Rewards.keyCandidate(profile, phaseId)
	Rewards.initialize(profile)
	if not profile.phaseChests[phaseId] then
		return nil
	end
	local candidate = table.clone(profile)
	for _, field in ipairs({ "phaseKeys", "phaseSecrets", "cosmetics", "phaseChests" }) do
		candidate[field] = table.clone(profile[field])
	end
	if not candidate.phaseKeys[phaseId] then
		candidate.phaseKeys[phaseId] = true
		candidate.coins = (candidate.coins or 0) + 20
	end
	candidate.completed = true
	candidate.finished = true
	candidate.noDeaths = candidate.noDeaths or candidate.deaths == 0
	return candidate
end

function Rewards.worldKeyCount(profile, worldId)
	local count = 0
	for phase = 1, 4 do
		if profile.phaseKeys and profile.phaseKeys[worldId .. "_phase" .. phase] == true then
			count += 1
		end
	end
	return count
end

return Rewards
