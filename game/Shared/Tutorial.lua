local Tutorial = {}

Tutorial.phaseId = "first_spark"
Tutorial.phaseName = "First Spark"
Tutorial.width = 13
Tutorial.height = 9
Tutorial.fuse = 2.4
Tutorial.blastDuration = 0.45
Tutorial.moveInterval = 0.24
Tutorial.enemyInterval = 0.95
Tutorial.stages = {
	{
		name = "Garden Gate",
		rows = {
			"#############",
			"#P..B.A...ED#",
			"#...#.#.#...#",
			"#...#...B...#",
			"#.#.#.#.#.#.#",
			"#...#...M...#",
			"#...#.#.#...#",
			"#...#E.B..S.#",
			"#############",
		},
	},
	{
		name = "Rescue Courtyard",
		rows = {
			"#############",
			"#P..F...B.ED#",
			"#.#.#.#.#...#",
			"#...B.L...M.#",
			"#.#.#.#.#.#.#",
			"#..C..B...E.#",
			"#...#.#.#...#",
			"#..E..B.....#",
			"#############",
		},
	},
}

return Tutorial
