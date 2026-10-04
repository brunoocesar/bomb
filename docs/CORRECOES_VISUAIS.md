# Correções visuais — 03/10/2026

Registro da primeira revisão. A composição montada com duas imagens descrita aqui foi substituída pelo atlas unificado e pelo contrato de packs em [CURVAS_E_PACK_MONTADO.md](CURVAS_E_PACK_MONTADO.md). As pendências e testes abaixo representam o estado daquela revisão.

Referência lida: PDF atual, GDD 2.0, 40 páginas. As recomendações e exemplos do documento não foram convertidos em novos requisitos de campanha. Escopo desta tarefa: os três problemas pedidos no vídeo `WhatsApp Video 2026-10-03 at 17.31.58.mp4` (29,81 s, 1052 × 500, 20 fps).

## Módulos localizados antes das alterações

| Responsabilidade | Arquivos |
| --- | --- |
| Grade e mapas das etapas | `game/Shared/Tutorial.lua`, `game/Shared/Simulation.lua` |
| Layout responsivo, arena e HUD | `game/Assets/TutorialUI.model.json`, `TutorialCompactUI.model.json`; autoria em `tools/Generate-TutorialUI.py` |
| Posição, composição, animação e camadas | `game/Client/Tutorial.client.lua` |
| Frames, margens e pontos de apoio | `game/Shared/SpriteCatalog.lua`, `art/sprites/sprite-manifest.json`; autoria em `tools/Measure-SpriteAtlases.ps1` |
| Montaria, proteção e resgate | `Simulation.lua`; sprites/composição no cliente e nos atlas do herói/sapinho |
| Patrulha e dano dos inimigos | `Simulation.lua`; desenho no cliente; frame `enemy` em `MapCatalog.lua` |
| Bombas e explosões | `Simulation.lua` calcula áreas; cliente seleciona frames de `MapCatalog.lua` |
| Envio de estado, pausa e persistência | `game/Server/Tutorial.server.lua`, `Profiles.lua` |

## Evidências e distinção entre arte e código

- Vídeo: aos ~9–10 s, o cavaleiro encobre grande parte do sapinho; nas vistas laterais posteriores, sobram principalmente patas. Nos corredores e próximo à borda inferior, partes dos atores aparecem sobre as pedras. Isso mostra sobreposição visual; não prova atravessamento da colisão.
- Código confirmado: os `groundPivot` existentes não eram utilizados. Herói e sapinho tinham tamanhos/origens distintos, com deslocamentos fixos, e o herói usava `Stretch` com proporção independente do recorte. As margens variáveis dos frames podiam mudar a posição aparente do apoio. Camadas fixas desenhavam atores acima de todos os obstáculos.
- Código confirmado: `enemy.x/y` mudavam instantaneamente na simulação e `view.Position` recebia diretamente a nova célula, sem transição.
- Arte inspecionada: existem duas poses sentadas para cada direção na linha 5 do atlas `hero` e ciclos nas quatro direções do atlas `frog`. A composição offline corrigida conserva rosto/patas na frente, silhueta de costas e cabeça nas laterais. Não foi identificado sprite obrigatório ausente para estas correções. A qualidade final dessas poses em movimento no Roblox ainda precisa de Play; não há justificativa confirmada para substituir a arte agora.

## Etapa 1 — apoio e sobreposição

`SpriteLayout.lua` centraliza apoio no chão em `(0.5, 0.82)` da célula. Cada frame usa seu `groundPivot` medido, com uma escala uniforme em pixels de origem: largura e altura preservam a proporção. Esse ponto é o apoio extraído dos limites opacos existentes, não um novo registro manual feito por artista. Se um frame ainda mostrar apoio incorreto em Play, o próximo ajuste deve ser seu metadado, preservando o PNG.

Herói e sapinho usam a mesma origem de célula e trajetória. A profundidade acompanha a linha da posição interpolada; obstáculos abaixo do ator podem encobri-lo, e o ator abaixo do obstáculo fica à frente. HUD e controles permanecem acima da arena.

A visualização temporária está desligada por padrão e só pode ser ativada no Studio. Em **Play / cliente**, na Command Bar:

```lua
game:GetService("Players").LocalPlayer.PlayerGui.TutorialUI:SetAttribute("ArenaDebug", true)
```

Use `false` para ocultar. Grade azul; sólidos/bombas/porta fechada em vermelho; célula usada para dano em amarelo; ponto de apoio no chão em rosa. Os objetos da depuração só são criados ao ativar e são reutilizados. Bombas marcadas como sólidas ainda mantêm a exceção existente de saída do jogador que acabou de colocá-las.

## Etapa 2 — montaria

As poses sentadas existentes são encaixadas acima do sapinho. O apoio do cavaleiro fica em `(0.5, 0.37)` para frente/costas, `(0.58, 0.37)` para esquerda e `(0.42, 0.37)` para direita. O deslocamento lateral coloca o assento atrás da cabeça do sapinho. O apoio no chão da dupla permanece igual em todas as direções. Não houve alteração de PNGs, ordem dos frames ou IDs enviados.

Prévia reproduzível: `powershell -ExecutionPolicy Bypass -File tools/Preview-Mounted.ps1`. Saída: `build/video-analysis/mounted-preview.png`. Ela mostra duas poses nas quatro direções, com proporção preservada; não é captura do Roblox.

## Etapa 3 — inimigo e dano durante o movimento

`ActorMotion.lua` é usado pelo servidor e pelo cliente. O inimigo percorre continuamente uma célula durante o intervalo de patrulha já existente. Destinos são validados contra os mesmos obstáculos; ordem e frequência da patrulha foram preservadas. O herói mantém a duração anterior da transição, 75% do intervalo de movimento.

O dano por contato e explosão usa a célula mais próxima da posição na trajetória, em vez de usar imediatamente o destino. Isso mantém o combate por células e muda **o instante da ocupação**: a célula muda quando a trajetória cruza seu meio. Uma explosão ainda pode atingir a origem enquanto o ator está saindo; não mata antecipadamente um inimigo que ainda não chegou à célula perigosa. Destinos lógicos continuam usados para os comandos existentes de bomba, coleta e porta.

O cliente amostra a mesma trajetória, com extrapolação limitada a 50 ms entre estados; pausa/morte congelam a amostragem. Há latência de rede e a simulação de dano continua em passos de 50 ms; isso não garante simultaneidade absoluta entre tela e servidor sob rede ruim. Reinício/checkpoint eliminam trajetórias antigas.

## Validação executada e pendências

- `Tutorial.spec.luau`: 69 verificações passaram.
- `VisualMotion.spec.luau`: 327 verificações passaram, incluindo proporção/apoio de frames, profundidade, posições intermediárias, contato e explosões na origem/destino, reinício.
- `TutorialRoute.spec.luau`: rota das duas etapas concluída em 13 ações / 41,7 segundos simulados, sem mortes, com segredo e sapinho.
- `TutorialUI.spec.py`: dois layouts, sete proporções de área segura e 117 células por layout passaram. Inclui telas de desktop, retrato e celular horizontal; verifica geometria dos controles, não interação por toque real.
- Selene: zero erros, avisos ou erros de análise sintática. Build Rojo gerado em `build/Bomb-Your-Way-visual-fixes.rbxlx`.
- Inspeção offline da composição e dos quadros do vídeo; nenhuma medição real de FPS/memória/toque.

Não havia processo Roblox Studio aberto durante esta tarefa. As mudanças estão no repositório; não foram sincronizadas com uma sessão nem publicadas. O destino Rojo permanece `127.0.0.1:34873`, Place ID `140221183064352`.

Pendência em Studio/celular: verificar sessão, Place ID e hierarquia antes de sincronizar; testar apoio nos corredores e quinas nas quatro direções, parado/andando, montado/desmontado; oclusão dos obstáculos e legibilidade durante explosões; contato e explosões durante a patrulha; pausa/reinício/resgate/perda da montaria; controles, FPS e memória em desktop e celular. Os resultados offline não comprovam esse comportamento no Roblox.
