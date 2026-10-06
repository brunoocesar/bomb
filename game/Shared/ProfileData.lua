local SkinPacks = require(if script then script.Parent.SkinPacks else "./SkinPacks")
local LobbyProgress = require(if script then script.Parent.LobbyProgress else "./LobbyProgress")
local PhaseRewards = require(if script then script.Parent.PhaseRewards else "./PhaseRewards")
local ProfileData = {}

function ProfileData.defaults(now)
	local result = {
		version = 2,
		phaseId = "world1_phase1",
		stage = 1,
		coins = 0,
		deaths = 0,
		completed = false,
		secret = false,
		frogUnlocked = false,
		skinPack = SkinPacks.default,
		ownedSkinPacks = { [SkinPacks.default] = true },
		visited = false,
	}
	LobbyProgress.initialize(result, now)
	PhaseRewards.initialize(result)
	return result
end

function ProfileData.sanitize(value, now)
	local result = ProfileData.defaults(now)
	if type(value) ~= "table" then
		return result
	end
	result.skinPack = SkinPacks.normalize(value.skinPack)
	if type(value.ownedSkinPacks) == "table" then
		for id in pairs(SkinPacks.packs) do
			if value.ownedSkinPacks[id] == true then
				result.ownedSkinPacks[id] = true
			end
		end
	end
	if not result.ownedSkinPacks[result.skinPack] then
		result.skinPack = SkinPacks.default
	end
	for _, name in ipairs({
		"visited",
		"campBadge",
		"rewardSeen",
		"completed",
		"finished",
		"noDeaths",
		"secret",
		"frogUnlocked",
		"frog",
		"coinCache",
	}) do
		result[name] = value[name] == true
	end
	-- Saved v1 profiles from before the lobby already represent returning players.
	if value.visited == nil and value.version == 1 then
		result.visited = true
	end
	for _, name in ipairs({ "stage", "coins", "deaths", "capacity", "range" }) do
		local number = value[name]
		if type(number) == "number" and number == number and math.abs(number) < 1e9 then
			result[name] = math.max(0, math.floor(number))
		end
	end
	result.settings = LobbyProgress.sanitizeSettings(value.settings)
	-- Whitelist known permanent grants; do not accept arbitrary reward identifiers.
	for _, field in ipairs({ "phaseKeys", "phaseChests" }) do
		if type(value[field]) == "table" then
			for phase = 1, 4 do
				local id = "world1_phase" .. phase
				if value[field][id] == true then
					result[field][id] = true
				end
			end
		end
	end
	for _, id in ipairs({ "world1_phase1_cream", "world1_phase1_scarf" }) do
		if type(value.phaseSecrets) == "table" and value.phaseSecrets[id] == true then
			result.phaseSecrets[id] = true
		end
	end
	for _, id in ipairs({ "cream_body", "yellow_scarf" }) do
		if type(value.cosmetics) == "table" and value.cosmetics[id] == true then
			result.cosmetics[id] = true
		end
	end
	result.daily = type(value.daily) == "table" and value.daily or nil
	PhaseRewards.initialize(result)
	result.supplies = type(value.supplies) == "table" and value.supplies or nil
	if value.phaseId ~= "world1_phase1" then
		-- The prototype's gate/medals are not a key grant for the authored phase.
		-- Preserve account inventory, settings and currency, restart the new route.
		result.stage, result.deaths, result.capacity, result.range = 1, 0, 1, 2
		result.frog, result.finished, result.completed, result.noDeaths = false, false, false, false
	else
		result.stage = math.clamp(result.stage, 1, 2)
		result.completed = result.phaseKeys.world1_phase1 == true
		result.finished = result.completed and result.finished
		if result.phaseChests.world1_phase1 and not result.finished then
			result.stage = 2
		end
	end
	LobbyProgress.initialize(result, now)
	return result
end
function ProfileData.isReturning(profile)
	return profile.visited == true or profile.completed == true
end

return ProfileData
