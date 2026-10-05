local ProfileData =
	require(if script then game:GetService("ReplicatedStorage").Shared.ProfileData else "../Shared/ProfileData")
local Repository = {}
function Repository.new(store, clock, tokenFactory)
	local Profiles = {}
	local function defaults()
		return ProfileData.defaults(clock())
	end

	local function sanitize(value)
		return ProfileData.sanitize(value, clock())
	end

	function Profiles.open(userId)
		local profile = { key = tostring(userId), token = tokenFactory(), busy = false }
		if not store then
			profile.data, profile.localOnly = defaults(), true
			return profile
		end
		local ok, result = pcall(function()
			return store:UpdateAsync(profile.key, function(old)
				if type(old) == "table" and old.lock and old.lock.untilTime > clock() then
					return nil
				end
				local data = sanitize(old and old.data)
				return { data = data, lock = { token = profile.token, untilTime = clock() + 180 } }
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
				return {
					data = data,
					lock = not release and { token = profile.token, untilTime = clock() + 180 } or nil,
				}
			end)
		end)
		profile.busy = false
		return ok and result ~= nil
	end

	return Profiles
end
return Repository
