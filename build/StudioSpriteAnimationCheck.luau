assert(game.PlaceId==140221183064352);
local Animation = require(game.ReplicatedStorage.Shared.SpriteAnimation)
local Catalog = require(game.ReplicatedStorage.Shared.SpriteCatalog)
local Layout = require(game.ReplicatedStorage.Shared.SpriteLayout)
local checks = 0
local function expect(ok, message)
	checks += 1
	assert(ok, message)
end
for _, random in ipairs({ 0, 0.5, 0.999999 }) do
	for _, kind in ipairs({ "hero", "frog" }) do
		local selector = Animation.new(function()
			return random
		end)
		local open = selector:select("actor", "base", kind, "idle", "down", 0)
		local wait = 3 + random * 3
		for i = 1, 299 do
			local frame, _, blink = selector:select("actor", "base", kind, "idle", "down", wait * i / 300)
			expect(frame == open and not blink, "idle stays open until its separate blink deadline")
		end
		local closed, _, blink = selector:select("actor", "base", kind, "idle", "down", wait)
		expect(blink and closed ~= open, "occasional blink uses authored closed eyes")
		local duration = selector.slots.actor.blinkUntil - wait
		expect(duration >= 0.1 - 1e-9 and duration <= 0.2, "blink lasts 0.1 to 0.2 seconds")
		local frame = selector:select("actor", "base", kind, "idle", "down", wait + duration + 0.001)
		expect(frame == open, "blink returns to open idle")
		expect(
			selector.slots.actor.nextBlink - selector.slots.actor.blinkUntil >= 3 - 1e-9,
			"blink never loops with idle"
		)
		selector:select("actor", "base", kind, "walk", "down", wait + duration + 0.01)
		expect(selector.slots.actor.blinkUntil == nil, "movement cancels the idle blink state")
	end
end
local selector = Animation.new(function()
	return 0
end)
selector:select("jitter", "base", "hero", "idle", "down", 0)
selector:select("jitter", "base", "hero", "idle", "down", 2)
selector:select("jitter", "base", "hero", "idle", "down", 1.98)
expect(selector.slots.jitter.nextBlink == 3, "snapshot jitter does not restart blink schedule")
for _, kind in ipairs({ "hero", "frog", "mounted" }) do
	for _, direction in ipairs({ "down", "left", "right", "up" }) do
		local frame, atlasId = selector:select(kind .. direction, "base", kind, "idle", direction, 0)
		local scale = Layout.fit(atlasId, 240, 240)
		for _, f in ipairs(Catalog.atlases[atlasId].frames) do
			local w, h = f.rect[3] * scale, f.rect[4] * scale
			expect(math.abs(w / h - f.rect[3] / f.rect[4]) < 1e-9, "common pixel scale preserves source proportion")
		end
		expect(frame ~= nil, "all idle directions resolve")
	end
end
local frog = Catalog.atlases.frog
local apex, rest = frog.frames[5 * 8 + 4], frog.frames[5 * 8 + 8]
local function feetHeight(f)
	return f.groundPivot[2] * f.rect[4] - f.opaqueBounds[2] - f.opaqueBounds[4]
end
expect(feetHeight(apex) > feetHeight(rest) + 15, "authored jump elevation survives ground alignment")
expect(apex.rect[2] <= 780 and apex.rect[2] + apex.rect[4] >= 895, "jump retains full head and feet")
local before = frog.frames[4 * 8 + 4]
expect(before.rect[2] + before.rect[4] < apex.rect[2], "idle no longer includes next frame's eyes")
print(string.format("Sprite animation passed: %d checks.", checks))
