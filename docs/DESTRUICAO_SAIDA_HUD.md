# Destruição, saída e HUD — 03/10/2026

GDD 2.0 de 40 páginas relido. Escopo: apresentação das regras existentes, sem novos poderes, objetivos ou recompensas. As instruções do usuário definem a tarefa; o documento fornece contexto do projeto.

## Diagnóstico confirmado

- `Simulation.lua` já removia a caixa e revelava o item imediatamente. `Tutorial.client.lua` apenas ocultava sua imagem: não havia animação de quebra.
- A seta existia dentro do recorte `exitOpen`, mas não tinha indicador separado. No frame de aproximadamente 27,5 segundos do vídeo ela está pequena. Isso confirma a limitação de legibilidade; não confirma uma falha no carregamento do asset.
- O HUD mostrava `B ... | R ...` e concatenava `Local Studio session` ao status normal.

## Implementação

`FeedbackPresentation.lua` detecta diferenças entre snapshots da mesma revisão, calcula quatro fragmentos, o salto dos itens e os textos do HUD. Não altera tiles, colisão, dano ou inventário. Mudanças de revisão não geram efeitos de destruição.

O cliente reaproveita 16 grupos GUI autorados em `Generate-TutorialUI.py`, divide o recorte original da caixa em quatro partes e aplica dispersão, rotação e desaparecimento em 0,42 segundo. Um brilho inicial dura 0,15 segundo. Ao exceder o pool, substitui o efeito mais antigo. Não cria peças físicas nem novas instâncias durante a animação; reinícios limpam o pool.

Itens aparecem imediatamente e recebem um salto de 0,5 segundo e contorno luminoso. O cliente mantém a retirada do item conforme o snapshot. O brilho permanece discreto para identificá-lo. A arte original e os IDs dos assets foram preservados.

O portal aberto recebe brilho pulsante, seta separada de 28–44 pixels, legenda `EXIT` e camada acima dos obstáculos. A instrução agora diz `Exit open! Enter the glowing portal.` O portal fechado mantém sua ordenação por profundidade e contador de energia.

O HUD mostra `BOMBS READY: disponível/capacidade` e `RANGE: n tiles`. Em telas com menos de 600 pixels seguros, o contador ocupa uma linha própria para evitar corte perto do botão de pausa. O rodapé apresenta o ícone do sapinho, `FROG: 1 HIT` ou `FROG: NONE`, e moedas. Mensagens úteis de salvamento ficam na pausa/resultado; o texto técnico da sessão Studio é filtrado. O overlay de grade continua desativado por padrão e restrito ao Studio.

## Validação e pendência

- 185 verificações de feedback: detecção de destruição, reinícios, duração, limites dos fragmentos, salto de item, textos e remoção imediata da colisão na simulação.
- Contrato dos dois modelos GUI e geometria em 14 áreas seguras de computador/celular aprovados.
- Regressões: tutorial 69, movimento 327, explosões 398; rota completa das duas etapas em 13 ações / 41,7 segundos simulados, sem mortes, com segredo e sapinho.
- Selene sem erros/avisos; StyLua aprovado; build Rojo atualizado em `build/Bomb-Your-Way-visual-fixes.rbxlx`.

## Validação real no Studio

A janela estava fora do isolamento inicial das ferramentas. Após acessar a sessão desktop, foram confirmados Place ID `140221183064352`, Universe ID `10769176732`, grupo `204998424`, modo de edição e hierarquia dos scripts. O Rojo já conectado sincronizou os módulos e os modelos atualizados; a inspeção confirmou `BOMB_FEEDBACK_SYNC_OK`.

- Play desktop: observer confirmou fragmento visível com rotação e transparência evoluindo (`BOMB_FEEDBACK_ANIMATED`). Capturas mostraram HUD legível, item do sapinho destacado e portal aberto com seta/legenda acima das pedras.
- Rota pelos remotes normais, sem teleportar nem editar estado do servidor: `BOMB_MAP_ROUTE_RESULT won 2 3 3 0 true` — duas etapas concluídas, nenhuma morte, sapinho resgatado.
- Simulador iPhone XR: paisagem e retrato inspecionados. O primeiro retrato mostrou pouco espaço para o texto das bombas; o contador foi separado em uma linha e o cliente recarregado. `BOMB_MOBILE_HUD_OK true 413, 755` confirmou TouchEnabled, texto dentro dos limites reais, células quadradas e botão de bomba de pelo menos 44 pixels.
- Botões móveis: toque sustentado moveu o personagem; BOMB produziu explosão. A fuga manual ficou curta e causou morte, seguida de reinício normal. `BOMB_MOBILE_RESTART_CLEAN` confirmou ausência de destroços após o reinício. Esse teste não é uma rota móvel sem mortes.

Capturas estão em `build/Studio-feedback-*.png`. Testes móveis usaram o simulador do Studio, não um aparelho físico; desempenho e toque no hardware real não foram medidos. A sessão de Play foi encerrada. Não houve publicação do lugar.
