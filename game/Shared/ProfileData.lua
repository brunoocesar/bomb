local SkinPacks = require(if script then script.Parent.SkinPacks else "./SkinPacks")
local LobbyProgress = require(if script then script.Parent.LobbyProgress else "./LobbyProgress")
local ProfileData = {}

function ProfileData.defaults(now)
	local result = {
		version = 1,
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
	result.daily = type(value.daily) == "table" and value.daily or nil
	result.supplies = type(value.supplies) == "table" and value.supplies or nil
	LobbyProgress.initialize(result, now)
	return result
end
function ProfileData.isReturning(profile)
	return profile.visited == true or profile.completed == true
end

return ProfileData
