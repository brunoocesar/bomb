"""Original quiet camp loop and short menu cues. Standard library only."""
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art/audio/camp"
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050

def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)

def add_note(samples, start, duration, note, volume, bell=False):
    first = round(start * RATE)
    length = round(duration * RATE)
    hz = frequency(note)
    for i in range(min(length, len(samples) - first)):
        t = i / RATE
        attack = min(1, t / .018)
        release = min(1, max(0, (duration - t) / .15))
        decay = math.exp(-t * (2.8 if bell else 1.7))
        tone = math.sin(math.tau * hz * t)
        tone += (.22 if bell else .12) * math.sin(math.tau * hz * 2 * t) * math.exp(-t * 4)
        samples[first + i] += tone * attack * release * decay * volume

def save(name, samples):
    peak = max(abs(v) for v in samples) or 1
    scale = min(1, .75 / peak)
    pcm = b"".join(struct.pack("<h", round(max(-1, min(1, v * scale)) * 32767)) for v in samples)
    path = OUT / (name + ".wav")
    with wave.open(str(path), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(pcm)
    print(f"{path.relative_to(ROOT)}: {len(samples)/RATE:.2f}s, peak={peak*scale:.3f}")

# Eight bars, 80 BPM. Original C-major pentatonic phrase over C/Am/F/G.
beat = .75
duration = 8 * 4 * beat
music = [0.0] * round(duration * RATE)
chords = [(48, 52, 55), (45, 48, 52), (41, 45, 48), (43, 47, 50)] * 2
melody = [(0, 72), (1.5, 76), (3, 79), (4, 81), (6, 79), (7, 76),
          (8, 77), (9.5, 76), (11, 72), (12, 74), (14, 79), (15, 74),
          (16, 76), (18, 79), (19, 84), (20, 81), (22, 79), (23, 76),
          (24, 77), (26, 76), (27, 72), (28, 74), (30, 71), (31, 72)]
for bar, chord in enumerate(chords):
    for pulse in range(4):
        add_note(music, (bar * 4 + pulse) * beat, 1.25, chord[pulse % 3] + 12, .065)
for onset, note in melody:
    add_note(music, onset * beat, min(1.45, duration - onset * beat), note, .075, True)
# Soft boundary fade prevents clicks; no generated loop points outside the recording.
for i in range(round(.04 * RATE)):
    gain = i / (.04 * RATE)
    music[i] *= gain
    music[-1-i] *= gain
save("camp-theme-v1", music)
click = [0.0] * round(.18 * RATE)
add_note(click, 0, .16, 84, .2, True)
save("menu-click-v1", click)
reward = [0.0] * round(.95 * RATE)
for offset, note in [(0, 72), (.12, 76), (.24, 79), (.36, 84)]:
    add_note(reward, offset, .95-offset, note, .17, True)
save("reward-v1", reward)
