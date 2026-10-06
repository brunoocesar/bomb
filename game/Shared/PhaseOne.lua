-- Authored from Mundos_Fases_Etapas_Bomb_Your_Way (1).pdf v1.0, pages 2–6.
-- PDF coordinates describe INTERNAL cells. Runtime coordinates add one for the border.
local Phase = {
	phaseId = "world1_phase1",
	phaseName = "Awakening Fields",
	worldId = "world1",
	worldName = "First Glow Plains",
	keyId = "world1_phase1",
	width = 15,
	height = 13,
	fuse = 2.4,
	blastDuration = 0.45,
	moveInterval = 0.24,
	enemyInterval = 0.95,
	stages = {
		{
			name = "Entrance Flowerbeds",
			id = "world1_phase1_stage1",
			sourcePage = 5,
			composition = "islands",
			powerup = "capacity",
			secretId = "world1_phase1_cream",
			secretReward = "cream_body",
			secretHint = "blue_flowers",
			internalRows = {
				".BB....BBBBBD",
				"B#R#B#B#B#R#.",
				".BB.BBB..B.B.",
				"B#.B.#B#B#N#B",
				"..N.BBBBB.BS.",
				"B#.#B#B#.#.#.",
				".BBBBBB...BB.",
				".#.#.#B#..B#B",
				"..BUBB....BBB",
				"...#.#.#.#.#B",
				".P....B...BBB",
			},
			enemySpawns = {
				{ x = 11, y = 4, kind = "slug" },
				{ x = 3, y = 5, kind = "slug" },
			},
		},
		{
			name = "Sun Courtyard",
			id = "world1_phase1_stage2",
			sourcePage = 6,
			composition = "ring",
			powerup = "range",
			secretId = "world1_phase1_scarf",
			secretReward = "yellow_scarf",
			secretHint = "gold_ribbon",
			chest = { x = 6, y = 5, width = 3, height = 2 },
			internalRows = {
				"B.NBB..BBBS.B",
				"B#R#B#N#B#R#B",
				"BB.BB...B..B.",
				"B#B#..BBB#N#B",
				"..N.BXXXB..NB",
				".#B#BXXXB#B#B",
				"..BBB.B.BOBBB",
				"B#B#B#.#B#B#.",
				"B..U.BBB.N..B",
				"...#B#B#B#.#.",
				".P...BBBB.BBB",
			},
			enemySpawns = {
				{ x = 11, y = 4, kind = "slug" },
				{ x = 3, y = 5, kind = "slug" },
				{ x = 10, y = 9, kind = "beetle" },
				{ x = 7, y = 2, kind = "beetle" },
				{ x = 12, y = 5, kind = "slug" },
				{ x = 3, y = 1, kind = "beetle" },
			},
		},
	},
}

-- Keep the published notation available for map QA; convert legacy engine tokens
-- centrally rather than quietly changing coordinates or hand-retyping the map.
for _, stage in ipairs(Phase.stages) do
	stage.rows = { string.rep("#", Phase.width) }
	for _, row in ipairs(stage.internalRows) do
		local converted = row:gsub("R", "E"):gsub("N", "M"):gsub("O", "F")
		converted = converted:gsub("U", stage.powerup == "capacity" and "A" or "L")
		table.insert(stage.rows, "#" .. converted .. "#")
	end
	table.insert(stage.rows, string.rep("#", Phase.width))
end

return Phase
