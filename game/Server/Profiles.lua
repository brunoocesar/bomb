local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ProfileData = require(game:GetService("ReplicatedStorage").Shared.ProfileData)

local Profiles = {}
local store = nil
if not RunService:IsStudio() then
	store = DataStoreService:GetDataStore("BombYourWay_Tutorial_v1")
end

local function defaults()
	return ProfileData.defaults(os.time())
end

local function sanitize(value)
	return ProfileData.sanitize(value, os.time())
end

function Profiles.open(userId)
	local profile = { key = tostring(userId), token = HttpService:GenerateGUID(false), busy = false }
	if not store then
		profile.data, profile.localOnly = defaults(), true
		return profile
	end
	local ok, result = pcall(function()
		return store:UpdateAsync(profile.key, function(old)
			if type(old) == "table" and old.lock and old.lock.untilTime > os.time() then
				return nil
			end
			local data = sanitize(old and old.data)
			return { data = data, lock = { token = profile.token, untilTime = os.time() + 180 } }
		end)
	end)
	if not ok or not result or not result.lock or result.lock.token ~= profile.token then
		return nil
	end
	profile.data = sanitize(result.data)
	return profile
end

function Profiles.save(profile, data, release)
	if profile.busy then
		return false
	end
	if profile.localOnly then
		profile.data = data
		return true
	end
	profile.busy = true
	local ok, result = pcall(function()
		return store:UpdateAsync(profile.key, function(old)
			if not old or not old.lock or old.lock.token ~= profile.token then
				return nil
			end
			return { data = data, lock = not release and { token = profile.token, untilTime = os.time() + 180 } or nil }
		end)
	end)
	profile.busy = false
	return ok and result ~= nil
end

return Profiles
