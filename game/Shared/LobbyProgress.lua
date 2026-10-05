-- Server-owned lobby data. Clock is injected so daily rewards can be tested.
local LobbyProgress = {}
LobbyProgress.settings = {
	music = 0.5,
	sfx = 0.7,
	muted = false,
	vibration = true,
	reducedEffects = false,
	largeText = false,
	leftHanded = false,
	controlsOpacity = 0.85,
	language = "en",
}

local function count(value, limit)
	return type(value) == "number" and value == value and math.clamp(math.floor(value), 0, limit) or 0
end

function LobbyProgress.sanitizeSettings(value)
	local result = table.clone(LobbyProgress.settings)
	if type(value) ~= "table" then
		return result
	end
	for name, default in pairs(result) do
		if type(default) == "boolean" and type(value[name]) == "boolean" then
			result[name] = value[name]
		elseif type(default) == "number" and type(value[name]) == "number" and value[name] == value[name] then
			result[name] = math.clamp(value[name], name == "controlsOpacity" and 0.35 or 0, 1)
		end
	end
	return result
end

function LobbyProgress.initialize(profile, now)
	profile.settings = LobbyProgress.sanitizeSettings(profile.settings)
	profile.visited = profile.visited == true
	local supply = type(profile.supplies) == "table" and profile.supplies or {}
	profile.supplies =
		{ count = count(supply.count, 7), lastDay = type(supply.lastDay) == "number" and supply.lastDay or -1 }
	profile.campBadge = profile.campBadge == true and profile.supplies.count == 7
	profile.rewardSeen = profile.rewardSeen == true
	local day = math.floor(now / 86400)
	local daily = type(profile.daily) == "table" and profile.daily or {}
	profile.daily = {
		day = day,
		crates = daily.day == day and count(daily.crates, 3) or 0,
		clear = daily.day == day and daily.clear == true,
		energyClaimed = daily.day == day and daily.energyClaimed == true,
		clearClaimed = daily.day == day and daily.clearClaimed == true,
	}
end

function LobbyProgress.refresh(profile, now)
	if not profile.daily or profile.daily.day ~= math.floor(now / 86400) then
		LobbyProgress.initialize(profile, now)
	end
end

function LobbyProgress.event(profile, event, now)
	LobbyProgress.refresh(profile, now)
	if event == "energy_box_destroyed" then
		profile.daily.crates = math.min(profile.daily.crates + 1, 3)
	elseif event == "phase_completed" and profile.deaths == 0 then
		profile.daily.clear = true
	end
end

function LobbyProgress.claim(profile, kind, now)
	LobbyProgress.refresh(profile, now)
	if not profile.completed then
		return false
	end
	local coins
	if kind == "energy" and profile.daily.crates == 3 and not profile.daily.energyClaimed then
		profile.daily.energyClaimed, coins = true, 5
	elseif kind == "clear" and profile.daily.clear and not profile.daily.clearClaimed then
		profile.daily.clearClaimed, coins = true, 10
	elseif kind == "supply" and profile.supplies.lastDay ~= profile.daily.day then
		profile.supplies.lastDay = profile.daily.day
		profile.supplies.count = math.min(profile.supplies.count + 1, 7)
		coins = 3
	else
		return false
	end
	profile.coins += coins
	return true
end

function LobbyProgress.setting(profile, name, value)
	local default = LobbyProgress.settings[name]
	if default == nil or type(value) ~= type(default) then
		return false
	end
	if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then
		return false
	end
	if name == "language" and value ~= "en" then
		return false
	end
	profile.settings = LobbyProgress.sanitizeSettings(profile.settings)
	profile.settings[name] = value
	profile.settings = LobbyProgress.sanitizeSettings(profile.settings)
	return true
end

function LobbyProgress.primary(profile, definition)
	if profile.finished then
		return {
			text = "CHOOSE STAGE",
			detail = "First Spark complete. Explore your medals or replay the trail.",
			action = "select",
		}
	end
	local stage = math.clamp(profile.stage or 1, 1, #definition.stages)
	return {
		text = profile.visited and "CONTINUE" or "PLAY",
		detail = string.format(
			"First trail • %s\nStage %d/%d • %s",
			definition.phaseName,
			stage,
			#definition.stages,
			definition.stages[stage].name
		),
		action = "continue",
	}
end

return LobbyProgress
