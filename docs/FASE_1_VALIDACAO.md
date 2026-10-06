# Fase 1 — implementação e validação

## Revisão das plantas após o primeiro teste — 05/10/2026

Referência atual: `Mundos_Fases_Etapas_Bomb_Your_Way (1).pdf`, páginas 5–6, arquivo de 49 páginas. As duas plantas foram extraídas e inspecionadas visualmente. Canteiros da Entrada passa de 16 para 54 blocos comuns B e mantém duas lesmas. Pátio do Sol passa de 20 para 59 B e de três para seis inimigos: três lesmas e três besouros, nas coordenadas da nova ficha. U/S são adicionais aos B.

PhaseOne contém as 22 linhas novas. As posições de entrada, pilares, energia, porta, baú, upgrades, segredos e resgate foram preservadas. O cliente, suas sombras e efeitos de retirada agora suportam seis inimigos; antes havia apenas quatro slots visuais. Arte, velocidade dos inimigos, controles, regras, recompensas e checkpoints permanecem como aprovados.

Verificações desta revisão: PhaseOne 105; Simulation 39; Persistence 15; Layout 42; Pockets 502 colocações com fuga geométrica; contrato da UI com seis sprites/sombras/fumaças. O percurso completo da simulação passou em 45 ações e 153,7 segundos simulados, com os dois segredos, ambos upgrades, resgate e chave, sem mortes; confirmação de gravação injetada. No Studio, clones isolados dos módulos sincronizados confirmaram 54/59 B e 2/6 inimigos no Place 140221183064352. Isso comprova os dados sincronizados, não um novo percurso completo em execução.

Os resultados de percurso e capturas descritos abaixo pertencem à planta anterior, salvo onde esta seção afirma explicitamente resultados novos. Os tempos de teste recomendados no PDF atualizado são 60–100 s e 90–150 s por etapa; ainda precisam ser avaliados com jogadores.

A primeira planta nova foi observada em execução no Studio desktop: `build/Studio-phase1-new-plants-playing.png`. As posições novas e a maior densidade de fardos estão visíveis, com HUD e controles livres. O percurso completo novo foi validado na simulação; não foi repetido integralmente no Studio ou em celular nesta revisão.

---

Referência: GDD v2.0 (40 páginas) e `Mundos_Fases_Etapas_Bomb_Your_Way.pdf` v1.0, páginas 2–6. Escopo: Campos do Despertar inteiro, com Canteiros da Entrada e Pátio do Sol. Textos apresentados em inglês. Demais fases e chefe separado não foram implementados nesta solicitação.

## Correspondência com o PDF

| Requisito | Implementação e evidência |
| --- | --- |
| Duas plantas internas 13×11, borda permanente e coordenadas exatas | `game/Shared/PhaseOne.lua`; extração independente em `build/phase1-pdf-maps.json`; páginas renderizadas `build/phase1-pdf-page-5.png` e `phase1-pdf-page-6.png`; PhaseOne.spec: 105 verificações. |
| Etapa 1: 27 pilares, 16 blocos B, U/S, duas energias, duas lesmas e porta | Definição ativa em `Tutorial.lua` carrega PhaseOne. U concede capacidade; S concede pack creme. Porta abre por energia, sem exigir eliminar inimigos. |
| Etapa 2: 25 pilares, 20 blocos B, U/S, duas energias, duas lesmas e besouro | U concede alcance; ovo em (10,7); segredo em (11,1) concede pack de lenço amarelo. Baú indestrutível ocupa as seis células indicadas. |
| Arte e pistas das duas etapas | Fundos próprios, palha com cintas laranja, energia creme/turquesa, arco/canteiros, três flores azuis nas pedras, fita dourada e quatro esculturas de sol. Atlas e fundos enviados ao grupo 204998424; IDs e hashes em `art/maps/world1/roblox-assets.json`. Captura real da etapa 2: `build/Studio-phase1-stage2-route.png`. |
| Movimento contínuo, colisão, explosões e inimigos | Módulos compartilhados de movimento e colisão preservados; lesmas patrulham lentamente e besouro continua em linha até bloquear. Explosões respeitam paredes e baú. PhaseOneSimulation: 36 verificações; ContinuousMovement: 69. |
| Acesso sem sapinho e fuga de bombas | PhaseOne.spec verifica conectividade sem montaria. PhaseOnePockets verifica 750 colocações nas plantas iniciais e abertas, alcances 2/3, usando movimento real da simulação. Não enumera todas as combinações intermediárias de blocos nem a pressão de inimigos. |
| Checkpoint por etapa, upgrades e montaria | Simulation gera checkpoint e ProfileData normaliza. Travessia real no Studio preservou capacidade 2. PhaseOnePersistence: 15 verificações, incluindo retomada do baú seguro com upgrades e sapinho, falha temporária e nova tentativa. Store injetado; não prova nuvem Roblox. |
| Final seguro e chave única | Última energia limpa bombas/explosões e retira inimigos sem recompensa de combate. Interação exige face próxima. Servidor grava candidato antes de confirmar vitória; baú permanece fechado até confirmação. Repetição não duplica chave/moedas. Retomada do baú liberado é segura. |
| Revelação pulável de até 3 segundos | Cliente usa 2,2 segundos e botão CONTINUE. Template atual foi renderizado isoladamente no emulador, sem conceder recompensa, com chave/moedas e texto separados. Clique real disparou `BOMB_REVEAL_PREVIEW_SKIPPED`; captura `build/Studio-phase1-reveal-mobile-preview-loaded.png`. |
| Segredos utilizáveis como packs completos | Cream e scarf incluem personagem, movimento, sapinho e sprite montado. Seis atlas novos enviados e verificados como 1024×1024 no grupo autorizado. `art/sprites/rewards/roblox-assets.json`; concessão/migração/equipamento em PhaseRewards/ProfileData/SkinPacks. Seleção e EQUIPPED observados por botões reais do lobby em desktop. SkinPacks.spec: 605 verificações. |
| Lobby, resultado e migração | Awakening Fields e Sun Keys 0/4–1/4; fases futuras indisponíveis. Vitória antiga no protótipo não concede chave nova. ProfileData.spec: 24; LobbyProgress.spec: 32. Resultado real: `build/Studio-phase1-result.png`. |
| Desktop e celular | Desktop real: duas etapas, dois segredos, upgrades, resgate e interação final concluídos no Studio. Emulador iPhone XR: DeviceSafeInsets, células quadradas, cinco alvos de toque ≥44 px dentro da área segura. Toque real confirmou movimento, bomba, destruição e fuga sem morte às 00:34:52 UTC de 06/10/2026. |

## Evidências de execução e limites

O percurso desktop terminou às 00:08:46 UTC de 06/10/2026, com chave `world1_phase1`, 20 moedas, dois segredos e sapinho resgatado. Houve nove mortes no total das tentativas; não foi uma execução sem mortes. Confirmação de gravação: **Local Studio session**. O transporte de DataStore desta fase em produção e aparelhos físicos permanecem sem validação.

O controlador automatizado no emulador terminou sem completar a fase após 54 ações e 18 mortes. Isso não confirma causa no código do jogo. O teste direto dos controles móveis passou separadamente, mas não equivale a percurso completo móvel aprovado.

A orientação retrato também passou no Studio às 00:36:29 UTC: área segura 411×813, tabuleiro 394,615356×342, células quadradas e cinco controles de pelo menos 44 px. A captura `build/Studio-phase1-audit-portrait-playing.png` registra a composição. Em paisagem, uma amostra de dez segundos apresentou média de 59,99 FPS, percentil 95 de frame em 19,90 ms e pior frame de 34,18 ms. A memória total reportada foi 821,07 MB no contexto de Studio; não representa o orçamento do jogo isolado ou de um aparelho físico.

PhaseOneRoute.spec percorre ambas as etapas na simulação de produção, com inimigos ativos, sem teleporte ou modificação de mapa, em 75,2 segundos simulados e sem mortes. Sua confirmação de salvamento é injetada. Os tempos recomendados pelo PDF são metas de playtest com jogadores, não critérios comprovados por esse percurso automatizado.

PhaseOneUI.spec verifica 195 células, componentes do baú, revelação sem sobreposição, pistas, fumaça e três opções de packs. PhaseOneLayout.spec verifica seis tamanhos de tela. Essas verificações estáticas não substituem renderização ou dispositivo real.

## Arte e reprodução

Prompts exatos: `art/maps/world1/generation-prompts.md` e `art/sprites/rewards/generation-prompts.md`. Originais preservados; importações redimensionadas proporcionalmente para 1024. Retângulos de atlas convertem dimensões originais em dimensões importadas, sem deformar personagens.

O repositório e Rojo são a fonte de verdade. Lugar autorizado: 140221183064352. Nenhuma versão do lugar foi publicada automaticamente. O registro cronológico anterior está em `FASE_1_EM_IMPLEMENTACAO.md`; este relatório substitui suas afirmações antigas de integração pendente.

Build local final: `build/Bomb-Your-Way-phase1.rbxlx`. Suite de auditoria: PhaseOne 105, Simulation 36, Persistence 15, Layout 42, Route concluído, Pockets 750, ProfileData 24, SkinPacks 605 e contrato da UI aprovados; Stylua nos módulos principais e Selene sem erros/avisos. Comparação independente confirmou as 22 linhas das duas plantas contra a extração do PDF.
