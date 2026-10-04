local Progress = require("../game/Shared/LobbyProgress")
local Tutorial = require("../game/Shared/Tutorial")
local Simulation = require("../game/Shared/Simulation")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
local profile = { coins = 0, deaths = 0, stage = 1 }
Progress.initialize(profile, 0)
expect(Progress.primary(profile, Tutorial).text == "PLAY", "new profile starts adventure")
expect(not Progress.claim(profile, "supply", 0), "rewards locked before victory")
profile.visited = true
expect(Progress.primary(profile, Tutorial).text == "CONTINUE", "returning profile continues checkpoint")
profile.completed = true
for _ = 1, 3 do
	Progress.event(profile, "energy_box_destroyed", 0)
end
Progress.event(profile, "phase_completed", 0)
expect(Progress.claim(profile, "energy", 0), "completed crate mission")
expect(not Progress.claim(profile, "energy", 0), "crate reward idempotent")
expect(Progress.claim(profile, "clear", 0), "clean run reward")
expect(not Progress.claim(profile, "clear", 0), "clean run reward idempotent")
expect(Progress.claim(profile, "supply", 0), "daily supply")
expect(not Progress.claim(profile, "supply", 0), "supply idempotent")
expect(profile.coins == 18, "exact total rewards")
for day = 1, 6 do
	expect(Progress.claim(profile, "supply", day * 3 * 86400), "nonconsecutive days count")
end
expect(profile.supplies.count == 7, "badge unlocked in seven visits")
expect(profile.coins == 36, "no extra coins from skipped days")
expect(profile.daily.crates == 0 and not profile.daily.clear, "daily missions reset")
expect(not Progress.claim(profile, "fake", 18 * 86400), "unknown reward rejected")
expect(not Progress.setting(profile, "music", 0 / 0), "NaN rejected")
expect(not Progress.setting(profile, "sfx", math.huge), "infinity rejected")
expect(not Progress.setting(profile, "leftHanded", "yes"), "setting type validated")
expect(not Progress.setting(profile, "language", "pt"), "unavailable language rejected")
expect(Progress.setting(profile, "controlsOpacity", -10), "numeric setting clamped")
expect(profile.settings.controlsOpacity == 0.35, "controls remain visible")
profile.finished = true
expect(Progress.primary(profile, Tutorial).action == "select", "completed available campaign opens selection")
profile.ownedSkinPacks = { base = true }
local sim = Simulation.new(Tutorial, profile)
local checkpoint = sim:checkpoint()
for _, name in ipairs({ "settings", "daily", "supplies", "ownedSkinPacks" }) do
	expect(checkpoint[name] ~= sim.profile[name], "save data isolated from ongoing session: " .. name)
end
local savedOpacity = checkpoint.settings.controlsOpacity
Progress.setting(sim.profile, "controlsOpacity", 1)
expect(checkpoint.settings.controlsOpacity == savedOpacity, "pending save remains stable")
print(string.format("Lobby progress passed: %d checks.", checks))
