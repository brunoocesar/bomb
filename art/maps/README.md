# Arte dos mapas — Bomb Your Way!

Os mapas do tutorial usam PNGs cartunescos em `ImageLabel`, com a mesma grade e colisão da simulação. Os fundos não contêm paredes ou objetos sólidos desenhados: cada obstáculo tem um sprite separado, removido quando sua regra permite.

- `tutorial/garden-ground-v1.png`: piso de grama do Garden Gate.
- `tutorial/courtyard-ground-v1.png`: piso de pedra clara do Rescue Courtyard.
- `tutorial/objects-v1.png`: atlas transparente com 20 sprites.
- `map-manifest.json`: recortes medidos nos arquivos locais.
- `roblox-assets.json`: IDs, proprietário, resoluções e hashes dos arquivos enviados.
- `generation-prompts.md`: prompts usados com a ferramenta integrada de geração de imagens.

O atlas distingue parede permanente, madeira destrutível, caixa de energia, bônus de bombas, bônus de alcance, segredo rachado e tesouro. Também fornece as duas versões da saída, itens, ovo de resgate, bomba, inimigo e explosões. A saída fechada exibe cadeado e quantidade restante; ao destruir a última caixa, muda para o portal aberto com seta e brilho.

As imagens pertencem ao grupo **204998424 — Capyboom Studios** e são vinculadas em `game/Shared/MapImages.lua`. Os recortes locais são exportados para `MapCatalog.lua` e convertidos para a resolução entregue pelo Roblox. Os fundos se ajustam ao tabuleiro 13×9; a arte não muda colisões, alcance ou rotas.

Para novas aparências, crie outra pasta temática e preserve o significado dos sprites. Não sobrescreva a arte base. O gerador `tools/Generate-TutorialUI.py` autoria os ImageLabels nos dois layouts; a execução do jogo apenas atualiza as instâncias existentes. Builds normais usam os assets já autorados.
