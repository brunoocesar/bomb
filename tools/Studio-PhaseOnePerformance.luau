assert(game.PlaceId == 140221183064352, "Wrong project")
assert(game:GetService("RunService"):IsClient(), "Use the Studio client")
task.spawn(function()
	local run = game:GetService("RunService")
	local elapsed, worst, frames = 0, 0, 0
	local samples = {}
	while elapsed < 10 do
		local dt = run.RenderStepped:Wait()
		elapsed += dt
		worst = math.max(worst, dt)
		frames += 1
		table.insert(samples, dt)
	end
	table.sort(samples)
	print("BOMB_PHASE1_PERFORMANCE", frames / elapsed, samples[math.ceil(#samples * .95)] * 1000, worst * 1000, game:GetService("Stats"):GetTotalMemoryUsageMb())
end)
