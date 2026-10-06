# Lobby — implementação em andamento

Referência: GDD 2.0, 40 páginas, especialmente seções 18–20, 23, 26 e 31–34. A leitura integral foi realizada para esta tarefa. A decisão mais recente do usuário prevalece: cosméticos são packs completos de personagem, sapinho e versão montada.

## Implementado nos arquivos

- LobbyUI autorada no repositório, com cenário, personagem central, navegação, próximo objetivo, perfil, configurações, missões e recompensas.
- Layout independente da arena. Painéis laterais no computador e abaixo do personagem no formato vertical.
- Fluxo servidor: primeiro acesso entra na aventura; perfil retornando entra no lobby; primeira vitória libera loja e retorno ao acampamento.
- Botão Camp dos resultados abre a interface real. A pausa permite voltar ao acampamento quando liberado.
- Simulação e entradas ficam congeladas no lobby. Continuar preserva a etapa; repetir o conteúdo concluído começa nova tentativa.
- Pack base possui prévia das três formas. Sapinho bloqueado informa a origem do resgate.
- Recompensas são validadas no servidor, sem duplicação no mesmo dia. Dados mutáveis do lobby são copiados antes de salvar assincronamente.
- Configurações de lado/opacidade dos controles, texto maior e redução dos efeitos foram ligadas à interface.
- Configurações acessíveis pela pausa antes da primeira vitória, com retorno à arena ainda pausada. Esse acesso não libera loja, recompensas ou seleção de fases.
- Dados de perfil separados em `ProfileData.lua`; perfis v1 anteriores ao lobby migram como retornando, preservando campanha e coleção.
- Música original de 24 segundos, clique de menu e recompensa gerados em `art/audio/camp`. `CampFeedback.lua` liga os volumes aos controles, toca sons de menu/recompensas e inclui feedback tátil opcional. Os IDs de áudio ainda estão vazios; não há prova de reprodução no Roblox.
- Folhas discretas animadas no fundo, desativadas pela opção de efeitos reduzidos.
- Arte nova: `art/lobby/camp-background-v1.png` e `art/lobby/menu-icons-v1.png`, produzida com imagegen integrada, no estilo cartoon existente.

Missões de três caixas/5 moedas, conclusão sem mortes/10 moedas e suprimentos diários/3 moedas são propostas de balanceamento para teste. A trilha de sete dias não consecutivos e o emblema Campfire implementam a recomendação do PDF. Não representam preços aprovados. Não há produtos pagos configurados nem compras simuladas.

## Evidência estática atual

- LobbyProgress: 32 verificações, incluindo idempotência, dias não consecutivos, validação de configurações e isolamento de snapshots para salvamento.
- ProfileData: 19 verificações de migração, reparação de campos inválidos, reconstrução de checkpoint, configurações, emblema e recompensas após reentrada. Transporte DataStore não exercitado.
- LobbyLayout: 280 verificações em 14 áreas seguras, incluindo limites, sobreposição com personagem e dimensões de toque.
- Regressões: tutorial 69; entradas 2524; packs 225; movimento visual 330; feedback 185; UI da arena em 14 áreas seguras.
- Selene: zero erros/avisos. Build Rojo: `build/Bomb-Your-Way-lobby.rbxlx`.

## Trabalho ainda necessário

1. Imagens enviadas e integradas; verificar sua apresentação em todos os painéis e proporções de tela.
2. Validar todos os painéis e botões no Roblox, computador e simulador de celular, com imagens carregadas.
3. Verificar primeira vitória → Camp, continuação, replay, coleta de recompensas e reentrada de perfil.
4. Enviar os três WAVs próprios, preencher `CampAudio.lua`, validar volumes, reprodução e feedback tátil em dispositivo compatível.
5. Completar estados adicionais do catálogo de fases e revisar a animação ambiental em execução.
6. Registrar prompts completos e verificação dos assets, capturas, limitações de persistência e auditoria final do GDD.

## Estado do Studio observado

Lugar confirmado `140221183064352`. A consulta retornou `RunService:IsRunning() == false` e `IsClient() == true`, com avaliação pelo debugger. O botão Stop mostra “Finalização”; Stop e Shift+F5 não removeram a sessão. A fila de importação não ficou visível depois de selecionar os PNGs, e não há prova de upload. Foi solicitado ao usuário reabrir o lugar e reconectar ao Rojo, enquanto prosseguem ajustes independentes. Não afirmar validação visual deste lobby nem publicação do lugar.

Uma consulta posterior também retornou `IsEdit() == true`, `RunState == Stopped`, `IsServer() == false` e um jogador presente. Os indicadores não bastam para confirmar a causa da falha do importador. Não tratar a hipótese de finalização travada como diagnóstico confirmado. Uma alternativa com `StudioService:PromptImportFilesAsync` carregou o seletor, mas `CreateAssetAsync` retornou explicitamente “not available yet” nesta instalação. Nenhum novo asset foi criado por essa alternativa. O script de diagnóstico/upload está em `tools/Studio-ImportLobbyArt.luau`, limitado aos dois PNGs e ao grupo autorizado, sem publicar lugar.

Referências consultadas: [HapticEffect](https://create.roblox.com/docs/reference/engine/classes/HapticEffect), [StudioService](https://create.roblox.com/docs/reference/engine/classes/StudioService) e [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService). A documentação de uma API não prova que ela está liberada nesta instalação; o resultado observado acima prevalece.

O servidor Rojo respondeu em `127.0.0.1:34873` com projeto `Bomb Your Way!`, versão 7.7.0 e Place ID autorizado. A resposta prova que o servidor está ativo, mas não prova que o Studio aplicou todas as mudanças na sessão atual.

## Recuperação e integração verificadas — 03/10/2026

A sessão foi reaberta após salvar `build/Studio-before-lobby-recovery.rbxl`. O importador voltou a apresentar a fila e concluiu os dois PNGs no grupo Capyboom Studios. As observações da seção anterior são históricas.

- Fundo: `91547200008356`, nome `BombYourWay-CampBackground-v1`, resolução entregue 1023×576.
- Ícones: `131533049817842`, nome `BombYourWay-CampIcons-v1`, resolução entregue 1024×768.
- `GetProductInfoAsync` confirmou proprietário 204998424 para ambos; `CreateEditableImageAsync` confirmou as dimensões.
- `LobbyImages.lua` contém os IDs e as dimensões reais. A consulta da fonte de `StarterPlayerScripts.Client.Tutorial` confirmou a integração de `CampFeedback` no Studio.
- O primeiro Play revelou colisão entre o filho `Profile.Name` e a propriedade `Instance.Name`. O controlador agora usa `FindFirstChild("Name")`. Essa falha passou despercebida na verificação estática e no build; exige repetição em execução.
- Os tamanhos de texto responsivos agora atualizam `BaseTextSize`, evitando que a preferência de texto grande restaure tamanhos de uma orientação anterior.
- Selene dos arquivos alterados: zero erros/avisos. Build Rojo concluído. Nenhuma versão do lugar publicada.

O percurso de teste por entradas normais está em execução para validar vitória → acampamento. Ainda não há conclusão comprovada da validação completa dos menus ou do áudio.
## Fluxo real e revisão visual — 04/10/2026

O servidor confirmou `mode=won`, `location=lobby`, etapa 2, energia 3/3. O percurso usou entradas normais e terminou com quatro mortes; esse ensaio comprova acesso ao acampamento, não uma campanha sem falhas. A captura `build/Studio-lobby-desktop-first.png` mostrou fundo e ícones carregados, protagonista montado, navegação, cartão principal e rodapé.

A captura também revelou saldo de moedas escuro e aviso de resgate cobrindo o protagonista. A cor foi corrigida no modelo gerado. O retângulo do aviso agora é calculado por `LobbyLayout`: acima do cartão à direita quando há altura, ou no rodapé em telas compactas. O aviso mantém o botão principal acessível. Teste de layout ampliado: 336 verificações em 14 áreas seguras, incluindo aviso sem sobreposição ao herói e ao botão principal. Selene zero erros/avisos, build concluído. A versão corrigida ainda exige inspeção visual em execução.

Uma falha temporária da revisão automática por limite de uso impediu um clique; posteriormente a revisão voltou a autorizar as operações. A sessão atual é nova (log `20261004T025739Z_Studio_7794E_last.log`), com Place ID autorizado confirmado. A consulta retornou `IsEdit=true`, `RunState=Stopped`, `IsRunning=false`, `IsClient=true`, `IsServer=false`, um jogador. Selecionar os três WAVs não apresentou fila de upload. Não há IDs de áudio criados ou carregamento comprovado nesta tentativa. Não se atribui uma causa confirmada ao importador.
## Nova sessão de teste — 04/10/2026

F5 iniciou Play e a consulta confirmou `RunState=Running`, `IsRunning=true`, cliente local presente. O diagnóstico confirmou os dois IDs de imagem e que a fonte carregada contém os ajustes `geometry.reward` e `lockedShopHint`. O percurso por remotes normais está novamente ativo; não reiniciar apenas por demora ou uma morte durante o ensaio. O controlador de diagnóstico é `_G.BombMapRoute`, e `_G.BombLobbyQA.state` observa snapshots reais para os próximos testes. A captura nomeada `Studio-lobby-final-layout-desktop.png` ainda mostra a arena (não o lobby): não usá-la como evidência das correções do acampamento.

A explicação da loja bloqueada agora permanece visível ao longo dos snapshots. Abrir outro painel ou escolher um nó encerra essa explicação. A mudança corrige a atualização periódica que anteriormente apagava o texto logo após clicar em Shop. Selene do controlador: zero erros/avisos. Pendente validação por interação no cenário de perfil retornando antes da primeira vitória.
## Validação dos sete painéis e recompensas — 04/10/2026

A nova rota terminou em vitória com cinco mortes e entrou no lobby por solicitação normal. A captura `Studio-lobby-corrected-desktop.png` confirma saldo claro, aviso à direita sem cobrir o herói e botão principal acessível. Foram abertos por cliques reais Character, Frogs, Shop, Settings, Adventure, Profile e Missions; capturas `Studio-lobby-*-panel.png`. A inspeção mostra conteúdo e previews corretos nos sete painéis, mas não comprova ainda todos os botões nem rolagem completa.

O verificador por remotes normais confirmou moedas 35 → 43: energia +5, suprimentos +3, repetição sem duplicação. Clean run não cumprido e pack desconhecido foram rejeitados. O clique real em Reduced Effects alterou o estado autoritativo e ocultou Ambient, com `BOMB_LOBBY_SETTINGS_BUTTON_VERIFIED true` no log. Não houve teste do áudio, que ainda não contém IDs.

A captura `Studio-lobby-narrow-portrait.png` usa área de jogo vertical resultante do redimensionamento da janela (não emulador com toque). Revelou rótulos quebrados no rodapé e contraste baixo de Back/Settings. O gerador passou a usar texto creme nesses botões e nos nós bloqueados, Back com 44px, legendas do herói claras com contorno. O controlador passou a usar rótulos curtos no rodapé estreito, ícones de 28px e botões de rotação 44px. O layout reduziu a altura vertical do destaque do herói para oferecer mais espaço aos painéis. Essas últimas alterações ainda precisam ser recarregadas e inspecionadas visualmente; a sessão atual preserva os clones anteriores de UI.

Verificações após esses ajustes: 336 testes de layout em 14 áreas seguras, Selene zero erros/avisos e build Rojo concluído. O simulador de dispositivos aparece desabilitado na sessão Play atual; não alegar teste com toque com base no redimensionamento de janela. Nenhuma versão do lugar publicada.
## Emulador com toque — 04/10/2026

Após Shift+F5, o simulador ficou habilitado no menu Teste. Play iniciou com iPhone XR; o percurso normal terminou sem mortes e abriu o lobby. `BOMB_LOBBY_MOBILE_LAYOUT_VERIFIED 413 755 true` confirmou toque habilitado, fundo/herói carregados, aviso sem cobrir Stage/Continue e áreas de rotação/Back ≥44px. `Studio-lobby-mobile-portrait.png` registra essa versão. Clique em OK fechou o aviso, Character abriu o painel e Back retornou ao cartão principal (`Studio-lobby-mobile-character.png`). As correções anteriores de contraste e rodapé aparecem nessa sessão.

A rotação no emulador produziu `Studio-lobby-mobile-landscape.png`, com personagem, cartão principal e rodapé dentro da área segura. Detectada truncagem dos rótulos longos na navegação em duas colunas. O controlador passou a usar MAP/PACK em botões compactos e fonte 13, mantendo ADVENTURE/CHARACTER na navegação larga. Esse último ajuste ainda precisa de recarga/inspeção. Não alegar validação de aparelho físico, multitouch ou vibração a partir do emulador.

Os áudios WAV foram confirmados no campo de seleção, e o filtro do importador lista arquivos de áudio. Confirmar a seleção ainda não apresentou a fila. Não há envio comprovado; manter IDs de áudio vazios e continuar diagnóstico. Os requisitos de formato foram consultados na documentação oficial: https://create.roblox.com/docs/audio/assets. As outras entregas e testes não dependem desse envio.
## Replay e pausa confirmados — 04/10/2026

`StudioLobbyFlowCheck.luau` executou somente solicitações normais de cliente. Confirmou replay na etapa 1, conservação de moedas/resgate/conclusão permanente, configurações pausando o tempo da arena, aplicação de texto grande, retorno ainda pausado, abertura do acampamento, Continue preservando etapa e posição, e preferência mantida ao voltar. Resultado: `BOMB_LOBBY_FLOW_VERIFIED 1 20 true`. Isso não testa a persistência entre servidores de produção.

A sessão móvel permanece aberta no acampamento, após replay, com texto grande ativado para a próxima conferência. A tentativa de áudio pelo Studio continua sem fila visível. O Creator Dashboard oficial foi aberto como alternativa, sem modificar IDs ou declarar envio concluído.
## Áudio enviado e carregado — 04/10/2026

O Creator Dashboard estava autenticado e seu formulário confirmou `Uploading to Capyboom Studios`. Os três WAVs foram revisados na fila e enviados uma única vez, com resultado `3 files uploaded successfully`. Captura `Creator-camp-audio-upload-result.png`.

- Music: `139323405075519`, `camp-theme-v1`, 24 segundos.
- Click: `94723519223362`, `menu-click-v1`, 0,18 segundo.
- Reward: `102483984204817`, `reward-v1`, 0,9500226757 segundo.

`StudioCampAudioCheck.luau` confirmou nomes, proprietário 204998424, IsLoaded=true, duração e avanço de TimePosition para os três assets no lugar autorizado. O diagnóstico usou volume zero, portanto não comprova audição. Os IDs foram integrados a `CampAudio.lua`, e hashes/fontes constam em `art/audio/camp/roblox-assets.json`. Falta recarregar a sessão e testar a reprodução integrada, mute/volume e pausa ao sair do acampamento. A pendência de envio das seções anteriores foi resolvida; não repetir o upload.

`tools/Creator-Desktop.ps1` controla somente janelas cuja barra de endereço confirma create.roblox.com/dashboard; não lê credenciais nem acessa páginas de outros serviços. Nenhuma versão do lugar foi publicada.
A sessão foi recarregada depois da integração dos IDs. Um novo percurso está ativo, e `StudioLobbyIntegratedAudioCheck.luau` aguarda entrada no lobby para verificar automaticamente música avançando, mute, volumes e pausa/retomada ao entrar/sair da aventura. O diagnóstico usa snapshots de `_G.BombLobbyQA` e expõe `_G.BombLobbyAudioQA.state`. Consultar seu resultado antes de repetir o teste ou alegar validação da integração completa.
## Integração de áudio e navegação compacta confirmadas — 04/10/2026

O percurso normal terminou em vitória na etapa 2, energia 3/3, com cinco mortes. `BOMB_LOBBY_INTEGRATED_AUDIO_VERIFIED` confirmou música carregada e avançando, mute, volume de música 0,1875 e efeitos 0,14/0,18, pausa ao entrar na aventura e retomada ao retornar ao lobby. O diagnóstico usa as instâncias reais de CampFeedback e solicitações normais; não comprova audição em aparelho físico.

A captura `build/Studio-lobby-audio-final.png` mostra o lobby no emulador iPhone XR em paisagem, com MAP/PACK/FROGS/SHOP legíveis, personagem inteiro, moedas claras e Continue acessível. O aviso de resgate ocupa temporariamente o rodapé. Clique real em OK disparou `Sound.Played`, com `BOMB_LOBBY_NATIVE_CLICK_AUDIO true 0.14000000059604645`, confirmando ligação entre o botão e o efeito de clique.

As pendências históricas de upload, carregamento integrado e recarga dos rótulos compactos estão resolvidas. Permanecem fora da evidência disponível persistência entre servidores de produção, vibração física e multitouch em aparelho real. Nenhuma versão do lugar foi publicada. A auditoria final do escopo do PDF ainda está em andamento.
## Auditoria: silêncio geral e confirmação de salvamento — 04/10/2026

A comparação com a seção Áudio do GDD revelou a falta do botão geral de silêncio. Adicionado `muted` às preferências sanitizadas/persistidas, botão MUTE ALL AUDIO em Settings e aplicação aos três sons do acampamento sem substituir os volumes escolhidos. A área rolável Settings cresceu para acomodar o novo controle. O perfil agora mostra `saveStatus` enviado pelo servidor; em Studio informa Local Studio session, sem declarar persistência em produção.

Selene dos três módulos alterados: zero erros/avisos. LobbyProgress 32 verificações; ProfileData 20, incluindo mute atravessando a serialização sem perder volume; LobbyLayout 336 em 14 áreas seguras. Build Rojo concluído. Esses ajustes ainda precisam de recarga e teste em execução; a validação de áudio anterior não cobre o novo botão geral.
## Recarga e diagnóstico ativo — 04/10/2026

Play recarregado para carregar Mute e Profile.Save. O percurso abriu a saída da etapa 1. Uma consulta autoritativa mostrou que `advance` estava falso; o sinal foi habilitado no controlador existente, sem reiniciar o percurso. `StudioLobbyMuteCheck.luau` aguarda o lobby e mantém heartbeat; a consulta confirmou execução viva (heartbeat com 0,076 segundo). Não interpretar a espera como teste passado.

A confirmação Checkpoint saved agora só é emitida se a versão salva ainda corresponde à versão atual. Se outras mudanças ocorrerem durante a gravação, permanece Save pending até a gravação seguinte. Selene do servidor: zero erros/avisos. Transporte DataStore em produção permanece não testado.
## Auditoria rastreável e liberação das pausas de captura — 04/10/2026

`docs/AUDITORIA_LOBBY.md` registra requisito, implementação, evidência e pendência. O percurso reutilizado chegou à etapa 2 e abriu sua saída com energia 3/3 e zero mortes até esse ponto. Cada `inspectionStop` redefine advance=false; o diagnóstico `StudioLobbyAutoAdvance.luau` libera essas pausas no controlador existente, sem reiniciar a rota nem alterar posição, moedas ou estado do servidor. O diagnóstico de mute continua aguardando o lobby; heartbeat confirmou atividade real na última consulta.
## Mute e Back comprovados — 04/10/2026

O percurso terminou com uma morte e abriu o lobby. `BOMB_LOBBY_MUTE_VERIFIED 0.5 0.7 Local Studio session` confirmou silêncio nos três sons, restauração dos volumes e texto verdadeiro de salvamento. O teste usa solicitações normais ao servidor; o clique específico do botão Mute ainda precisa ser observado.

Clique real RotateRight mudou o frame para a orientação lateral; captura `Studio-lobby-pack-turned.png`. Back fechou Character e preservou a orientação (`BOMB_LOBBY_BACK_NATIVE 0, 254`). Criados observadores para preview, mute por botão e nó bloqueado, ainda sem resultado desses três.

A entrada de roda do mouse no painel Character do emulador XR não alterou visualmente o conteúdo (`Studio-lobby-pack-scrolled.png`). Não se atribui causa ao código: deve-se conferir CanvasPosition e gesto de arrastar no emulador antes de concluir defeito de rolagem. Adicionado ScrollDown ao helper de desktop, limitado à janela Studio autorizada.
## Rolagem por arrasto e preview comprovados — 04/10/2026

O gesto de arrastar alterou CanvasPosition para Y=163,005051 no painel Character, com canvas 428 e janela 140; ScrollingEnabled=true. Segundo arrasto revelou Preview e Equipped (`Studio-lobby-pack-buttons.png`). Clique real Preview alternou o sprite central para hero, com Frog.Visible=true (`BOMB_LOBBY_PREVIEW_NATIVE rbxassetid://90806353338434 true`); captura `Studio-lobby-preview-unmounted.png`.

A tentativa anterior com a roda do mouse não prova defeito de rolagem. O arrasto real comprovou acesso aos controles inferiores no emulador com toque. Não houve mudança da lógica do jogo para obter esse resultado. O helper recebeu ação Drag, limitada ao retângulo da janela autorizada e com liberação do mouse em finally.
## Mute por botão e nó bloqueado comprovados — 04/10/2026

Clipes reais no botão Mute produziram `BOMB_LOBBY_MUTE_NATIVE true 0` e `false 0.125`, confirmando alternância autoritativa e restauração do volume inicial da música. O controle foi alcançado por arrasto em Settings (`Studio-lobby-settings-scrolled.png`).

Clique real no segundo nó de Adventure produziu `BOMB_LOBBY_LOCKED_TRAIL_NATIVE This trail is not open yet. Explore First Spark and its secrets.` O observador confirmou Play.Active=false e location=lobby. Não houve início de fase indisponível. `Studio-lobby-map-nodes.png` registra a posição dos quatro nós antes do clique. O catálogo atual só contém First Spark; não se promete fase que ainda não existe.
## Coleta pela loja, som e idempotência comprovados — 04/10/2026

Suprimentos foram alcançados por arrasto e coletados por clique real no botão da loja. `BOMB_LOBBY_REWARD_SOUND_NATIVE true 0.3149999976158142` confirmou Sound.Played com asset carregado e volume positivo. `BOMB_LOBBY_SUPPLY_NATIVE 20 23 CLAIMED TODAY` confirmou saldo e texto. Segundo clique repetiu o mesmo saldo 23, sem moedas adicionais. A captura `Studio-lobby-supply-button.png` mostra a oferta antes da coleta. O observador confirmou também lastDay igual à data diária autoritativa.
## Bloqueio pré-vitória verificado em cenário isolado — 04/10/2026

`StudioLobbyGuardCheck.luau` criou uma instância temporária do controlador real com cópia do snapshot, completed=false, frogUnlocked=false e visited=true. O remoto foi substituído por um registrador local que não envia solicitações. Shop redirecionou para Adventure, manteve a explicação após cinco refreshes, não solicitou ação e exibiu a silhueta bloqueada da coleção. Back manteve a direção. A instância temporária foi destruída. Resultado `BOMB_LOBBY_PREWIN_GUARD_VERIFIED isolated controller fixture`.

Esse resultado comprova as regras do controlador no Roblox para a condição pré-vitória. Não comprova carregamento do perfil em outro servidor nem conexão DataStore de produção. A primeira tentativa não executou devido a falha de clipboard registrada; somente a segunda, confirmada no log, conta como evidência.
## Equipamento observado e trilha do mapa adicionada — 04/10/2026

Clique real no botão Equipped produziu `BOMB_LOBBY_EQUIP_NATIVE base 23 true`. O único pack disponível já estava equipado; esse ensaio confirma o botão e a conservação do estado, não troca entre packs inexistentes. SkinPacks usa um ID único para hero, heroMovement, frog e mounted. Packs desconhecidos foram rejeitados no ensaio anterior.

A auditoria visual encontrou ausência da ligação entre os quatro nós de Adventure, prevista no GDD. Adicionado TrailPath ao modelo gerado e posicionamento responsivo entre os centros dos nós. Selene zero erros/avisos e build concluído. A ligação visual nova ainda precisa de inspeção em execução.
## Trilha sincronizada e verificada — 04/10/2026

O primeiro diagnóstico confirmou ausência de TrailPath no clone da sessão Play antiga; essa tentativa falhou e não conta como validação. Após Stop, a consulta no modo de edição confirmou modelo e código atualizados (`BOMB_LOBBY_EDIT_TRAIL true true`). Nova sessão carregou os assets.

Uma instância temporária do controlador atualizado, com perfil de diagnóstico criado por ProfileData.defaults e estado concluído, renderizou o mapa. `BOMB_LOBBY_TRAIL_PATH_VERIFIED 164, 8` confirmou alcance da linha aos centros dos quatro nós. Captura `Studio-lobby-trail-verified.png` mostra as conexões. Esse cenário testa a UI atual, sem alterar o perfil do servidor ou declarar vitória real. A instância temporária foi removida ao concluir. O percurso normal e as demais interações já foram comprovados nas sessões anteriores.
## Reconexão e concorrência testadas no repositório de perfis — 04/10/2026

Extraída a lógica existente de Profiles para ProfileRepository.new(store, clock, tokenFactory). Profiles conserva o mesmo DataStore BombYourWay_Tutorial_v1 em produção e sessões locais em Studio. O servidor usa ProfileData.isReturning para decidir aventura/lobby; a mesma regra é exercitada nos testes.

`tools/ProfileRepository.spec.luau`: 16 verificações com armazenamento injetado. Cobertura: primeira sessão, bloqueio concorrente, gravação/liberação, nova instância restaurando checkpoint/resgate/mute/moedas e destino lobby, recompensa não duplicada após reconexão, rejeição do token antigo, falha de save liberando busy, falha de load sem perfil substituto, retry, recuperação após expiração e proteção contra escrita do proprietário expirado. ProfileData: 20 verificações. Selene quatro módulos: zero erros/avisos. Build concluído.

Os testes comprovam a lógica usada pelo servidor com um contrato de armazenamento simulado. Não comprovam disponibilidade, permissões ou transporte do DataStore Roblox em produção. A refatoração ainda precisa ser carregada em uma nova sessão do Studio para conferir integração dos módulos.

## Teste de transporte real tentado — 05/10/2026

Sessão atual confirmada no Place ID 140221183064352 e Universe ID 10769176732. O roteiro `build/StudioLobbyCloudCheck.luau` usa o repositório real com DataStore BombYourWay_Lobby_QA_v1 e chave qa-UUID criada exclusivamente para o ensaio; não acessa BombYourWay_Tutorial_v1 nem perfis reais. Testa gravação/liberação, nova instância, checkpoint/resgate/mute, idempotência e token antigo; remove somente a chave QA criada por ele ao concluir.

A tentativa recebeu `StudioAccessToApisNotAllowed: Cannot write to DataStore from studio if API access is not enabled` na primeira UpdateAsync. Resultado BOMB_LOBBY_CLOUD_QA_UNAVAILABLE. Não houve gravação comprovada, nem teste real passado. A configuração de acesso às APIs não foi modificada. Nenhuma versão do lugar foi publicada.
## Encerramento com retry — 05/10/2026

A revisão encontrou gravação final única em PlayerRemoving e BindToClose. ProfileRepository.close agora espera gravações em andamento e repete falhas dentro do prazo restante; os dois caminhos de saída usam essa operação. Não amplia os prazos existentes de encerramento. Testes do repositório: 21 verificações, incluindo falha transitória na saída, preservação do saldo final, liberação do lock, limite de espera e save em andamento. Selene dos dois módulos: zero erros/avisos; build concluído.

O Rojo foi reconectado ao servidor local e mostrou apenas ProfileRepository e Tutorial na revisão de sincronização. As alterações foram aceitas. O primeiro ensaio em Roblox encontrou código antigo e falhou; foi repetido depois da sincronização. A configuração de acesso às APIs permanece inalterada e a confirmação solicitada ao usuário continua pendente.
Resultado no Roblox: BOMB_LOBBY_CLOSE_RETRY_VERIFIED 41. O módulo real sincronizado recuperou a falha injetada e preservou saldo 41, liberando o lock. Armazenamento usado em memória; não declara transporte cloud testado.

## Sessão real encerrada e pendência externa — 05/10/2026

Play iniciou com código sincronizado e snapshot autoritativo na aventura, confirmado por BOMB_LOBBY_CLOSE_SESSION_READY Local Studio session. Stop encerrou o cliente/servidor; o log registrou remoção dos jogadores e fechamento do contexto em 13:58:31–13:58:32, sem erro de script nesse intervalo. Esse ensaio comprova integração/encerramento local, não gravação cloud. O retry com falha injetada já foi verificado no módulo real e em 21 testes de repositório.

O teste real de dados está preparado em StudioLobbyCloudCheck.luau, mas o Roblox recusou UpdateAsync por StudioAccessToApisNotAllowed. A autorização para habilitar temporariamente o acesso às APIs foi solicitada e não recebeu resposta. A configuração permanece intacta. Após concluir as verificações independentes, esta pendência requer resposta do usuário ou mudança externa para prosseguir; não declarar a validação real concluída.
## Revalidação somente leitura após retomada — 05/10/2026

A consulta GetAsync de qa-permission-probe no armazenamento exclusivo de QA também foi recusada: StudioAccessToApisNotAllowed, HTTP 403, em 14:03:21 UTC. A tentativa não grava dados nem altera configurações. A condição externa continua presente; não interpretar a retomada automática do objetivo como autorização para habilitar APIs. A resposta à confirmação anterior permanece necessária para a mudança de configuração.