# Áudio do acampamento

Três composições originais geradas por `tools/Generate-CampAudio.py`, sem samples externos:

- `camp-theme-v1.wav`: tema suave de 24 segundos, oito compassos a 80 BPM, timbres de sino e cordas sintetizados.
- `menu-click-v1.wav`: confirmação de botão, 0,18 segundo.
- `reward-v1.wav`: confirmação de recompensa, 0,95 segundo.

Formato: WAV PCM de 16 bits, mono, 22050 Hz. O gerador preserva ataques e finais suaves para evitar cliques nas bordas do loop. A integração usa `CampFeedback` e `CampAudio`; volumes seguem as preferências do jogador e a música toca somente no lobby.

Os três arquivos foram enviados pelo Creator Dashboard ao grupo Capyboom Studios. `GetProductInfoAsync` confirmou proprietário 204998424 e os nomes. No Place ID 140221183064352, `Sound.IsLoaded` foi verdadeiro e a reprodução avançou para os três assets. Durações entregues: 24 s, 0,18 s e 0,9500226757 s. `CampAudio.lua` contém os IDs; nomes, hashes e identificação estão em `roblox-assets.json`. Falta conferir a reprodução vinculada aos botões e à entrada/saída do lobby na sessão recarregada. A reprodução diagnóstica usou volume zero; não comprova percepção auditiva nem vibração em aparelho físico.

Roblox aceita WAV, MP3, OGG e FLAC conforme a [documentação oficial de assets de áudio](https://create.roblox.com/docs/audio/assets). Compatibilidade documentada não comprova que esta tentativa de envio foi concluída.
