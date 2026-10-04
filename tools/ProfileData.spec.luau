local Data = require("../game/Shared/ProfileData")
local Progress = require("../game/Shared/LobbyProgress")
local Simulation = require("../game/Shared/Simulation")
local Tutorial = require("../game/Shared/Tutorial")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local now = 86400 * 100
local fresh = Data.sanitize(nil, now)
expect(not fresh.visited, "first access does not open lobby")
expect(fresh.daily.day == 100, "daily initialized from server time")
local legacy = Data.sanitize({ version = 1, stage = 2, coins = 12, secret = true, frogUnlocked = true }, now)
expect(legacy.visited, "legacy saved session returns to lobby")
expect(legacy.stage == 2 and legacy.coins == 12 and legacy.secret and legacy.frogUnlocked, "legacy progress preserved")
expect(legacy.settings.language == "en" and legacy.skinPack == "base", "new fields migrate safely")
local invalid = Data.sanitize(
	{
		coins = 0 / 0,
		stage = math.huge,
		deaths = -4,
		skinPack = "unknown",
		ownedSkinPacks = { unknown = true },
		settings = { music = 0 / 0, leftHanded = "yes", language = "pt" },
		supplies = { count = 999 },
		daily = { day = 99, crates = 3, clear = true },
	},
	now
)
expect(invalid.coins == 0 and invalid.stage == 1 and invalid.deaths == 0, "invalid numeric progress repaired")
expect(invalid.skinPack == "base" and not invalid.ownedSkinPacks.unknown, "invalid cosmetics rejected")
expect(
	invalid.settings.music == 0.5 and not invalid.settings.leftHanded and invalid.settings.language == "en",
	"invalid settings repaired"
)
expect(
	invalid.supplies.count == 7 and invalid.daily.crates == 0 and not invalid.daily.clear,
	"bounded rewards and daily reset"
)
legacy.completed = true
legacy.finished = false
legacy.supplies.count = 6
Progress.setting(legacy, "music", 0.25)
Progress.setting(legacy, "leftHanded", true)
Progress.setting(legacy, "reducedEffects", true)
expect(Progress.claim(legacy, "supply", now), "seventh resupply collected")
legacy.campBadge = true
local simulation = Simulation.new(Tutorial, legacy)
local saved = simulation:checkpoint()
local reopened = Data.sanitize(saved, now)
expect(reopened.visited and reopened.stage == 2, "return restores checkpoint")
expect(reopened.completed and reopened.secret and reopened.frogUnlocked, "permanent progress survives")
expect(
	reopened.settings.music == 0.25 and reopened.settings.leftHanded and reopened.settings.reducedEffects,
	"settings survive serialization boundary"
)
expect(reopened.supplies.count == 7 and reopened.campBadge, "earned badge survives")
expect(not Progress.claim(reopened, "supply", now), "reconnect does not duplicate reward")
expect(reopened.coins == 15, "reconnect preserves exact balance")
local later = Data.sanitize(reopened, now + 3 * 86400)
expect(later.supplies.count == 7 and later.campBadge, "skipped days retain reward track")
expect(Progress.claim(later, "supply", now + 3 * 86400), "later day eligible")
expect(later.supplies.count == 7 and later.coins == 18, "completed track stays bounded")
print(string.format("Profile data passed: %d checks. DataStore transport not exercised.", checks))
