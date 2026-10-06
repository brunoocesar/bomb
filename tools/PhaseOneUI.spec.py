"""Check authored phase and reward UI contracts; does not prove Studio behavior."""
import json
from pathlib import Path
root = Path(__file__).resolve().parent.parent

def children(node):
    return {n['Name']: n for n in node.get('Children', [])}

phase = json.loads((root / 'game/Assets/PhaseOneUI.model.json').read_text())
assert phase['Properties']['ScreenInsets'] == 'DeviceSafeInsets'
top = children(phase)
board = children(children(top['PlayArea'])['Board'])
assert sum(name.startswith('Cell_') for name in board) == 195
for y in range(1, 14):
    for x in range(1, 16):
        cell = board[f'Cell_{x}_{y}']
        size = cell['Properties']['Size']['UDim2']
        assert abs(size[0][0] - 1/15) < 1e-9
        assert abs(size[1][0] - 1/13) < 1e-9
        assert set(children(cell)) == {'Object', 'ItemGlow', 'Item', 'Blast', 'Bomb'}
assert {'Sprite', 'SunKey', 'Seal'} <= set(children(board['Chest']))
reveal = children(children(top['ChestReveal'])['Panel'])
assert {'Title', 'Detail', 'Key', 'Coins', 'Skip'} <= set(reveal)
for name in ['Key', 'Coins']:
    p = reveal[name]['Properties']['Position']['UDim2'][1][0]
    h = reveal[name]['Properties']['Size']['UDim2'][1][0]
    assert p + h <= reveal['Detail']['Properties']['Position']['UDim2'][1][0]
assert {'Flower_1', 'Flower_2', 'Flower_3', 'Ribbon', 'Sun_1', 'Sun_2', 'Sun_3', 'Sun_4'} <= set(children(board['Decorations']))
assert len(children(board['SealWires'])) == 2
assert len(children(board['RetireSmoke'])) == 6
assert sum(name.startswith('Enemy_') for name in board) == 6
assert sum(name.startswith('EnemyShadow_') for name in board) == 6
assert 'Bomb' in children(top['Controls'])
lobby = json.loads((root / 'game/Assets/LobbyUI.model.json').read_text())
assert lobby['Properties']['ScreenInsets'] == 'DeviceSafeInsets'
character = children(children(children(children(lobby)['Panel'])['Content'])['Character'])
for name in ['Select_base', 'Select_cream', 'Select_scarf', 'Equip', 'Preview']:
    button = character[name]
    assert button['ClassName'] == 'TextButton'
    assert button['Properties']['Size']['UDim2'][1][1] >= 44
assert {'Hero', 'Frog', 'Mounted'} == set(children(character['PackArt']))
print('PhaseOne UI: 195 cells, chest, reveal, clues, smoke and three complete-pack selections checked; static only.')
