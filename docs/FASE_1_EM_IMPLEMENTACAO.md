# Fase 1 — Campos do Despertar

> Registro cronológico. Consulte [FASE_1_VALIDACAO.md](FASE_1_VALIDACAO.md) para o estado atual e a matriz de requisitos/evidências. Afirmações antigas de pendência abaixo foram superadas pelas atualizações posteriores.

Referências: GDD v2.0 integral (40 páginas) e Mundos_Fases_Etapas_Bomb_Your_Way.pdf v1.0, páginas 2–6. Plantas das páginas 5 e 6 renderizadas e inspecionadas. A fase inteira tem duas etapas; as demais fases e a arena de chefe não fazem parte desta solicitação.

## Dados autorados

PhaseOne.lua mantém as plantas internas 13×11 do PDF, adicionando a borda permanente para 15×13 células. Coordenadas do PDF recebem +1 em cada eixo no runtime. O extrator Extract-PhaseOneMaps.py lê as posições dos símbolos do PDF; a comparação visual usa as renderizações produzidas por Render-DesignPdf.ps1.

Etapa 1: Canteiros da Entrada / Entrance Flowerbeds. 27 pilares, 16 blocos comuns, um bloco de capacidade +1, um segredo de corpo creme, duas caixas de energia, duas lesmas e porta intermediária. Etapa 2: Pátio do Sol / Sun Courtyard. 25 pilares, 20 blocos comuns, alcance +1, segredo de lenço amarelo, resgate do sapinho, duas lesmas e um besouro. Baú central bloqueia exatamente 3×2 células e substitui a porta final.

## Lógica implementada, integração em andamento

Simulation aceita o baú indestrutível, encerra perigos e retira inimigos sem evento de derrota quando a última energia é destruída. A interação exige proximidade de uma face. O estado claiming aguarda salvamento confirmado antes de vitória. PhaseRewards mantém chaves, segredos e cosméticos únicos, com candidato de gravação separado do perfil vivo. ProfileData preserva essas concessões em carregamentos. Baú liberado e não coletado retoma sem perigos.

O servidor usa o candidato no fluxo existente de salvamento e confirma a coleta após retorno bem-sucedido. Falhas seguem a fila de novas tentativas. A arena pode calcular células para dimensões diferentes sem perder DeviceSafeInsets. PhaseOneUI possui 195 células e componentes de baú/revelação, autorados offline.

## Evidência local atual

- PhaseOne.spec.luau: 105 verificações; geometria e objetivos conforme PDF, conectividade sem montaria e concessões únicas.
- PhaseOneSimulation.spec.luau: 36 verificações; upgrades, checkpoint, resgate, segredos distintos, bloqueio de explosão, retirada de inimigos, retomada segura e confirmação da chave.
- PhaseOnePersistence.spec.luau: 14 verificações com repositório e store injetado; falha transitória, retry e reconexão. Não comprova transporte da nuvem Roblox.
- PhaseOneLayout.spec.luau: 42 verificações geométricas em seis tamanhos. Não comprova execução em dispositivo.
- Regressões existentes executadas: Tutorial 69, ContinuousMovement 69, VisualMotion 329, ProfileRepository 21 e ArenaLayout 14 áreas seguras.
- Selene nos módulos alterados: sem erros/avisos. Build intermediária Rojo criada.
- Studio confirmado: Place 140221183064352, Universe 10769176732, grupo 204998424; contexto de edição e hierarquia correta; novos módulos sincronizados.

## Ainda necessário para concluir

Integrar e enviar os novos assets ao grupo autorizado; trocar a fase de testes pela PhaseOne com migração explícita do progresso antigo; conectar UI, interação desktop/toque/gamepad, revelação pulável até 3s, pistas dos segredos e leitura das duas caixas/selo. Tornar cosméticos concedidos utilizáveis e compatíveis com o pack único de personagem/sapinho/montado. Atualizar lobby para Campos do Despertar, chaves 0/4–1/4 e fases futuras indisponíveis. Validar percurso completo, mortes/checkpoints, fuga em bolsos, salvamento e interação no Studio desktop e emulador móvel. Nenhuma publicação automática.

Estado: em implementação. A definição ativa ainda é a fase de testes, até concluir a integração visual e a migração; os testes novos instanciam explicitamente PhaseOne.

## Atualização de integração — 05/10/2026

A entrada Tutorial.lua agora carrega PhaseOne: as duas etapas substituem a arena de testes. A migração preserva dados de conta, mas não concede a chave da fase por uma vitória no protótipo. PhaseOneUI e os três assets de cenário estão integrados; seus IDs foram verificados no Studio como pertencentes ao grupo 204998424. O lobby apresenta Awakening Fields e a contagem de Sun Keys.

O baú tem interação contextual por botão, teclado e gamepad, e revelação pulável de 2,2 segundos após confirmação do salvamento. As pistas de flores, fita e esculturas estão autoradas. A primeira etapa foi observada em execução no Studio; o percurso completo e a segunda etapa ainda precisam de validação em execução, incluindo emulador móvel.

Os seis atlas dos packs creme e lenço amarelo foram gerados e medidos, mas ainda não enviados nem registrados como packs equipáveis. Portanto, as recompensas cosméticas ainda não estão concluídas.

Correção adicional: o checkpoint do baú liberado conserva alcance, capacidade e montaria atuais. O teste de persistência agora possui 15 verificações e comprova a retenção do upgrade e da montaria após reconexão ao repositório injetado. A abertura do lobby fica bloqueada durante a confirmação da chave para evitar alterações de moedas concorrentes ao candidato de salvamento. PhaseOneSimulation mantém 36 verificações aprovadas; Selene nos dois scripts alterados retorna zero erros e avisos.

Esta atualização substitui a afirmação anterior de que a definição ativa ainda era a arena de testes. O estado continua em implementação, sem publicação automática.

## Validação complementar e packs integrados

Os packs cream e scarf estão registrados em SkinPacks/SpriteImages e são concedidos pelos respectivos segredos. LobbyController permite selecionar, prever e equipar cada pack completo; itens não obtidos ficam identificados como bloqueados. Os seis IDs, nomes, grupo 204998424 e dimensões efetivas 1024×1024 foram verificados no Studio por MarketplaceService e CreateEditableImageAsync (log 05/10/2026 23:54:12–20 UTC). Manifests: art/sprites/rewards/roblox-assets.json e art/maps/world1/roblox-assets.json; prompts exatos dos packs: art/sprites/rewards/generation-prompts.md.

PhaseOneRoute.spec.luau percorre ambas as etapas com movimento contínuo, bombas e inimigos ativos, sem teleporte nem alterações de mapa. Passou em 19 ações e 75,2 segundos simulados, sem mortes, com dois segredos, capacidade 2, alcance 3 e sapinho resgatado. A confirmação de salvamento deste teste é injetada; não equivale a percurso aprovado no Roblox.

A primeira execução de Studio-PhaseOneRoute foi encerrada após mortes: sua previsão usava movimentos mais rápidos que a execução. O controlador de QA foi corrigido para prever o mesmo controle proporcional que envia. A nova execução está ativa, com progresso observado na primeira etapa; não há ainda prova de conclusão no Studio. Nenhuma regra de jogo foi afrouxada para o teste.

Última suíte aprovada: PhaseOne 105, Simulation 36, Persistence 15, Layout 42, ContinuousMovement 69, ProfileData 24, ProfileRepository 21, LobbyProgress 32, SkinPacks 605 e SpriteAnimation 2385. Persistência usa repositório injetado, e layout usa verificações geométricas. Permanecem pendentes: percurso completo no Studio, avaliação visual da segunda etapa e validação móvel.

## Segunda etapa alcançada em execução

O controlador normal atravessou a porta da primeira etapa e iniciou Sun Courtyard no Studio, preservando capacidade 2. A captura build/Studio-phase1-stage2-route.png mostra a etapa real em execução: baú central, quatro esculturas, duas ligações de energia, pista de fita dourada, ovo do sapinho e inimigos. HUD, controles e arena ficam legíveis no viewport desktop 1043×688, sem painéis inferiores do Studio comprimindo a prévia. A execução corrigida não havia registrado novas mortes até a travessia (as sete mortes no contador pertencem à tentativa anterior). Conclusão do baú e avaliação móvel continuam pendentes.

## Vitória desktop e interface móvel medidas

Às 00:08:46 UTC de 06/10, o percurso no Studio concluiu a interação próxima ao baú e confirmou vitória, chave world1_phase1, 20 moedas, dois segredos, capacidade 2, alcance 3 e resgate. O contador final teve nove mortes (sete da primeira tentativa de QA e duas da execução posterior). O salvamento confirmado foi Local Studio session; não é prova de DataStore em produção. Captura: build/Studio-phase1-result.png.

Os botões reais do lobby selecionaram e equiparam os packs creme e lenço amarelo. Capturas build/Studio-phase1-cream-equipped.png e Studio-phase1-scarf-equipped.png mostram o estado EQUIPPED e a montaria correspondente.

Uma nova sessão usa iPhone XR emulado 896×414. Studio-PhaseOneUICheck mediu área segura 801×392, tabuleiro 343×297,266663, células quadradas e cinco alvos de toque de pelo menos 44 pixels, todos dentro da área segura, com TouchEnabled=true e DeviceSafeInsets. Captura inicial: build/Studio-phase1-mobile-ready.png. O percurso móvel está ativo e ainda não concluído.

Após observar a apresentação do baú, a renderização foi ajustada: liberar o selo conserva o baú fechado; a chave e a arte aberta só aparecem após vitória confirmada. A sessão móvel carrega essa versão. A dica da etapa final agora orienta liberar o Sun Chest, em vez de uma saída inexistente.

## Auditoria de bolsos e revelação

PhaseOnePockets.spec.luau verificou 750 colocações de bomba em casas alcançáveis nas plantas iniciais e abertas, com alcance 2 e 3, sem montaria e sem inimigos. Cada caso possui fuga que sobrevive à explosão usando o movimento contínuo real. É verificação geométrica; não prova fuga sob pressão dos inimigos nem enumera todas as combinações intermediárias de blocos destruídos.

Na UI autorada da revelação, a imagem da chave sobrepunha a região do texto. A composição agora separa chave/moedas, detalhe e botão CONTINUE. O detalhe anuncia +20 coins apenas para a primeira chave; repetição comunica que não há recompensa duplicada. PhaseOneUI.spec.py verifica que as imagens terminam antes da região do detalhe. Essa alteração ainda precisa de inspeção renderizada; a execução móvel em andamento usa o clone anterior da UI.

## Encerramento do QA móvel e prévia da revelação atualizada

O controlador móvel terminou às 00:22:30 UTC sem conclusão, após 54 ações e 18 mortes. A limitação fica registrada: não há evidência de conclusão automatizada do percurso móvel; isso não confirma uma causa no código do jogo.

Studio-PhaseOneRevealPreview.luau renderizou o template atualizado em uma fixture visual isolada, sem conceder chave ou modificar gameplay. Captura build/Studio-phase1-reveal-mobile-preview-loaded.png mostra chave e moedas proporcionais, detalhe separado e botão CONTINUE legível. A ferramenta de comandos agora lê UTF-8 explicitamente; isso corrige caracteres de textos de QA, sem alterar o idioma do jogo. O teste direto dos controles móveis ainda precisa ser concluído.
