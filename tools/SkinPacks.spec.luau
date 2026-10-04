local Packs = require("../game/Shared/SkinPacks")
local Catalog = require("../game/Shared/SpriteCatalog")
local Layout = require("../game/Shared/SpriteLayout")
local Simulation = require("../game/Shared/Simulation")
local Tutorial = require("../game/Shared/Tutorial")
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
expect(Packs.normalize("unknown") == "base", "unrecognized skin falls back safely")
for id, pack in pairs(Packs.packs) do
	for _, kind in ipairs({ "hero", "frog", "mounted" }) do
		for _, direction in ipairs({ "down", "left", "right", "up" }) do
			for _, animation in ipairs({ "idle", "walk" }) do
				local sequence = Catalog.animations[kind][animation][direction]
				local atlasId = Packs.atlas(id, kind, sequence[1])
				local atlas = Catalog.atlases[atlasId]
				expect(atlas ~= nil, "complete pack has every directional animation")
				for column = sequence[3], sequence[4] do
					local frame = atlas.frames[sequence[2] * atlas.columns + column + 1]
					expect(frame ~= nil, "frame resolves using actual atlas column count")
					if kind == "mounted" then
						local b = frame.opaqueBounds
						expect(
							b[1] > 0 and b[2] > 0 and b[1] + b[3] < frame.rect[3] and b[2] + b[4] < frame.rect[4],
							"mounted frames retain padding; no adjacent-row fragment"
						)
						local w, h, x, y = Layout.frame(frame, kind, true, direction)
						expect(math.abs(x + w * frame.groundPivot[1] - 0.5) < 1e-9, "mounted center stable")
						expect(math.abs(y + h * frame.groundPivot[2] - 0.82) < 1e-9, "ground stays under frog feet")
						expect(math.abs(w / h - frame.rect[3] / frame.rect[4]) < 1e-9, "no artwork distortion")
					end
				end
			end
		end
	end
	expect(pack.heroMovement ~= nil, "back walk belongs to same pack")
end
local sim = Simulation.new(Tutorial, { stage = 1, skinPack = "unknown" })
expect(sim:snapshot().skinPack == "base", "server snapshot uses canonical equipped pack")
expect(sim:checkpoint().skinPack == "base", "checkpoint retains entire equipped pack")
expect(not sim:equipSkinPack("unknown"), "server rejects unavailable pack")
expect(not sim:equipSkinPack({ hero = "base", frog = "other" }), "independent skin selection rejected")
expect(sim:equipSkinPack("base"), "owned pack equips as one unit")
Packs.packs.test = Packs.packs.base
expect(not sim:equipSkinPack("test"), "known but unowned pack cannot equip")
sim.profile.ownedSkinPacks.test = true
expect(sim:equipSkinPack("test"), "owned complete pack can equip")
local before = { sim.x, sim.y, sim.capacity, sim.range, sim.frog }
expect(sim:snapshot().skinPack == "test", "all forms share new equipped ID")
local restored = Simulation.new(Tutorial, sim:checkpoint())
expect(restored:snapshot().skinPack == "test", "checkpoint reload preserves owned equipped pack")
expect(
	sim.x == before[1]
		and sim.y == before[2]
		and sim.capacity == before[3]
		and sim.range == before[4]
		and sim.frog == before[5],
	"equipping has no gameplay effects"
)
sim:loadStage()
expect(sim:snapshot().skinPack == "test", "stage restart preserves pack")
sim.frog = true
sim.invulnerableUntil = 0
sim:damage()
expect(not sim.frog and sim:snapshot().skinPack == "test", "frog loss keeps coordinated skin for on-foot form")
sim:equipSkinPack("base")
Packs.packs.test = nil
sim:restartPhase()
expect(sim:snapshot().skinPack == "base", "replay preserves cosmetics")
print(string.format("Skin packs passed: %d checks.", checks))
