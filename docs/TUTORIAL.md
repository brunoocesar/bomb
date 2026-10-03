# Fase 1 — First Spark

Referência: GDD versão 2.0, páginas 7–14, 19–26 e 33–40 de `Plano_Profissional_Bomb_Your_Way (1).pdf`.

O PDF define duas etapas para a primeira fase do Mundo 1, mas não fornece coordenadas de um mapa de tutorial. Os mapas abaixo são uma implementação inicial dessa direção, sujeita a teste com jogadores. A Casa Apagada, com quatro ambientes, é um exemplo de fase no documento; não foi confundida com a primeira fase de duas etapas. O minichefe pertence à fatia vertical mais ampla e não foi colocado neste tutorial.

## Etapas

1. **Garden Gate:** área inicial segura, bloco que fecha o acesso à outra metade do jardim, melhoria garantida de capacidade, patrulheiro lento, duas caixas de energia e um segredo marcado com `?`.
2. **Rescue Courtyard:** sapinho acessível logo na entrada, melhoria de alcance, três caixas, patrulheiro e recompensa opcional de moedas.

O objetivo obrigatório é destruir as caixas de energia e atravessar a porta. Inimigos, segredo e montaria não bloqueiam a conclusão. As melhorias atravessam a porta entre etapas. A montaria absorve um acerto; morrer restaura obstáculos e inimigos da etapa, preservando recompensas únicas registradas. A conclusão concede uma recompensa única e registra as medalhas.

## Testar no Studio

O lugar confirmado **Bomb Your Way!**, Place ID **140221183064352**, está conectado ao Rojo em `localhost:34873`. Pressione **Play** no Studio. O tutorial começa diretamente, sem menu de loja. O build local `build/Bomb-Your-Way.rbxlx` também permite testes isolados.

- Computador: WASD ou setas; Espaço para bomba; P para pausa.
- Controle: direcional/analógico esquerdo; A para bomba; Start para pausa.
- Celular: botões de direção, BOMB e pausa. Há layouts autorados para retrato e paisagem compacta.
- A tela de pausa exige confirmação para reiniciar a etapa.

Todos os textos do jogo estão em inglês. A fase é renderizada em ScreenGui; a simulação, o dano e as recompensas são calculados por sessão no servidor. Jogadores não compartilham a campanha.

## Sprites

Os três PNGs foram enviados ao grupo **204998424 — Capyboom Studios** em 03/10/2026. Seus IDs estão vinculados em `game/Shared/SpriteImages.lua` e registrados em `art/sprites/roblox-assets.json`:

- `art/sprites/hero/base/hero-v1.png` → `hero`.
- `art/sprites/hero/base/hero-movement-v1.png` → `heroMovement`.
- `art/sprites/frog/base/frog-clean-v1.png` → `frog`.

O Roblox reduziu os atlas de 1254×1254 para 1024×1024, confirmado por `CreateEditableImageAsync` no Studio. O cliente ajusta os recortes à resolução entregue. O Play confirmou o personagem de frente e de costas sem quadros adjacentes; o carregamento do asset do sapo também foi confirmado. O protagonista e o sapinho permanecem em camadas independentes. O encaixe definitivo dos sprites montados precisa de conferência visual no Studio.

## Persistência

No Studio, o perfil fica em memória e a interface informa `Local Studio session`; sair do Play não grava dados permanentes. Em uma futura experiência publicada, a implementação usa DataStore no servidor, trava de sessão, checkpoints, tentativas de salvamento e proteção contra recompensas duplicadas. Falha de carregamento bloqueia a sessão para evitar sobrescrever progresso. Essa integração ainda precisa de teste real com DataStore; nada foi publicado.

O checkpoint guarda a etapa e suas melhorias de entrada. Sair no meio de uma etapa restaura essa etapa; não salva cada bloco destruído. Recompensas permanentes são registradas separadamente. A tela de resultados oferece rejogar e consultar recompensas; o lobby completo e a fase 2 não fazem parte desta entrega.

## Verificação

```powershell
build/tools/luau/luau.exe tools/Tutorial.spec.luau tools/TutorialRoute.spec.luau
selene game/Shared game/Server game/Client
stylua --check game/Shared game/Server game/Client
rojo build default.project.json --output build/Bomb-Your-Way.rbxlx
```

O teste de rota usa a simulação de produção e movimenta o personagem de verdade pela grade, com inimigos ativos. Não teletransporta nem remove obstáculos diretamente. Ele comprova a existência de uma rota completa, não o tempo de conclusão de um jogador novo. Duração e clareza do tutorial devem ser avaliadas em Play com jogadores novos conforme o PDF.

Os assets de UI são versionados e só devem ser regenerados deliberadamente com `tools/Generate-TutorialUI.py`. Builds comuns usam os assets atuais. `tools/Generate-SpriteCatalog.py` exporta apenas metadados, preservando PNGs e IDs de imagens.

Verificação executada em 03/10/2026: 69 asserções de regras aprovadas; rota completa com inimigos ativos, segredo e sapinho, sem mortes; contrato estático de dois layouts aprovado em sete dimensões de área segura; Selene sem erros ou avisos; StyLua aprovado; build Rojo gerado. A rota automatizada levou 37,4 segundos simulados, o que não representa duração de uma primeira sessão humana.

O contrato de layout pode ser conferido com `tools/TutorialUI.spec.py`. O asset usa CoreUISafeInsets para preservar a área segura, conforme a [documentação do Roblox](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets). Os cálculos estáticos de área não comprovam renderização nem legibilidade em um aparelho real.

Play real executado em 03/10/2026 no lugar confirmado: hierarquia sincronizada, proprietários dos três assets conferidos, resolução entregue medida, personagem de frente e de costas, movimento WASD, bomba, fuga, destruição do primeiro obstáculo e pausa/retomada. Capturas em `build/Studio-play-sprites.png`, `build/Studio-play-back.png`, `build/Studio-play-bomb.png` e `build/Studio-play-after-bomb.png`. O teste foi encerrado deixando o Rojo conectado; nenhuma versão do lugar foi publicada.

## Arte dos mapas

Garden Gate e Rescue Courtyard agora usam os fundos PNG e o atlas transparente de `art/maps/tutorial/`. Todas as paredes, caixas, itens, bombas, explosões e inimigos do tabuleiro são ImageLabels autorados. Os sprites distinguem madeira comum, energia, bônus de capacidade, bônus de alcance, segredo rachado e tesouro. A porta muda de cadeado fechado para portal luminoso com seta ao completar o objetivo; o contador de caixas restantes desaparece quando abre.

Os três assets foram enviados ao grupo Capyboom Studios e tiveram propriedade e resolução conferidas no Studio. O atlas é entregue em 1024×1024 e os fundos em 1023×709. Metadados e hashes ficam em `art/maps/roblox-assets.json`; os prompts exatos em `art/maps/generation-prompts.md`. A lógica da grade e as colisões permanecem independentes da arte.

Capturas reais em `build/Studio-map-garden.png`, `build/Studio-map-open-garden.png`, `build/Studio-map-courtyard.png`, `build/Studio-map-open-courtyard.png` e `build/Studio-map-portrait.png`. O viewport vertical medido teve 368,8×466,8 pixels de área segura, com tabuleiro de 298,7×206,8, fundo e porta carregados. Essa verificação de proporções no Studio não representa teste de toque ou desempenho em um celular físico.

`tools/Studio-TutorialRoute.luau` é um controlador exclusivo para a Command Bar do cliente em Play no lugar confirmado. Ele envia movimentos e bombas pela mesma interface remota do jogo, sem teletransportar ou editar o estado do servidor. Pausa o jogo nos pontos de captura e oculta temporariamente o modal existente para inspecionar a arte. Para continuar, execute `_G.BombMapRoute.advance = true`. Não pertence à árvore sincronizada do jogo.

Live map verification on 2026-10-03: the Studio route controller completed both stages using normal server inputs, opened and crossed both exits, and rescued the frog. The server result was `won`, stage `2`, energy `3/3`, deaths `0`, frog collection unlocked. The optional secret was not collected during this run. The actual victory screen is captured in `build/Studio-map-route-result.png`. A fresh Play session confirmed that the final ground and gate images load and that the authored exit counter measures 18×18 pixels; see `build/Studio-map-final-garden.png`.

Pendentes de validação real: toque e desempenho em aparelhos reais, áudio final, animações de ação, composição montada e comportamento de DataStore publicado.
