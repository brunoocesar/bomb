from pathlib import Path
root = Path.cwd()
src = (root / 'tools/TutorialRoute.spec.luau').read_text()
head = src.split('local actions = 0')[0]
head = head.replace('-- A planning controller walks the actual production simulation; it never teleports or edits level state.\n', '-- Studio-only client controller: sends normal inputs; never teleports or edits server state.\nassert(game:GetService("RunService"):IsStudio() and game.PlaceId == 140221183064352)\nassert(game.Players.LocalPlayer, "Run in the Studio client Command Bar")\n')
head = head.replace('require("../game/Shared/Tutorial")','require(game.ReplicatedStorage.Shared.Tutorial)').replace('require("../game/Shared/Simulation")','require(game.ReplicatedStorage.Shared.Simulation)')
(root / 'tools/Studio-TutorialRoute.luau').write_text(head, encoding='utf-8')
