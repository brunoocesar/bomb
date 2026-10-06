assert(game.PlaceId == 140221183064352 and game.GameId == 10769176732, "Wrong project")
-- Isolated clone avoids Studio's cached require from earlier edit-mode QA.
local shared = game.ReplicatedStorage.Shared:Clone()
local definition = require(shared.PhaseOne)
local Simulation = require(shared.Simulation)
local ui = game.ReplicatedStorage.Assets.PhaseOneUI.PlayArea.Board
for index = 1, 6 do
	assert(ui:FindFirstChild("Enemy_" .. index), "Missing enemy sprite")
	assert(ui:FindFirstChild("EnemyShadow_" .. index), "Missing enemy shadow")
	assert(ui.RetireSmoke:FindFirstChild("Smoke_" .. index), "Missing retire effect")
end
for stage = 1, 2 do
	local sim = Simulation.new(definition, { stage = stage })
	local blocks, slugs, beetles = 0, 0, 0
	for _, tile in pairs(sim.tiles) do
		if tile == "B" then
			blocks += 1
		end
	end
	for _, enemy in ipairs(sim.enemies) do
		if enemy.kind == "slug" then
			slugs += 1
		end
		if enemy.kind == "beetle" then
			beetles += 1
		end
	end
	assert(blocks == (stage == 1 and 54 or 59), "Outdated synced plant")
	assert(slugs == (stage == 1 and 2 or 3) and beetles == (stage == 1 and 0 or 3), "Wrong enemy composition")
	print("BOMB_PHASE1_NEW_PLANT", stage, blocks, #sim.enemies, slugs, beetles)
end
print("BOMB_PHASE1_NEW_PLANTS_VERIFIED", game.PlaceId)
shared:Destroy()
