# Auditoria do lobby — GDD 2.0

Esta auditoria distingue o lobby solicitado da produção futura da campanha. O jogo atual possui First Spark com Garden Gate e Rescue Courtyard. Criar as outras onze fases, mundos, produtos pagos e cosméticos adicionais depende de conteúdo e decisões posteriores; o lobby não anuncia esses itens como jogáveis ou compráveis.

| Requisito do lobby | Implementação / evidência | Situação |
|---|---|---|
| Acampamento próprio com imagens no estilo atual | LobbyImages, fundo 91547200008356 e ícones 131533049817842; capturas desktop e iPhone XR | Verificado em execução |
| Personagem e sapinho centrais, idle, giro e preview | LobbyController, SpriteCatalog, SkinPacks; sprite montado dedicado e packs completos conforme instrução do usuário | Render, giro, Preview e Back verificados por interação; arrasto revelou controles inferiores |
| Painéis preservam o personagem | LobbyLayout, sete painéis; 336 verificações e capturas dos sete painéis | Verificado no escopo das telas capturadas |
| Topo: moedas, perfil, configurações | Capturas e cliques dos painéis; moedas com contraste corrigido | Verificado |
| Ação principal retoma checkpoint | StudioLobbyFlowCheck: replay, pausa e Continue preservando etapa/posição | Verificado na sessão local |
| Estados PLAY / CONTINUE / seleção ao fim do conteúdo | LobbyProgress e testes; fase atual e suas etapas | Implementado para o conteúdo disponível |
| NEXT PHASE / NEW WORLD | Nenhuma fase seguinte ou mundo seguinte disponível no catálogo atual | Não criar destino fictício; requer catálogo quando houver conteúdo |
| Primeira sessão na aventura; retorno no camp | Servidor usa visited/completed; migração ProfileData | Primeira sessão observada; retorno pela mesma regra de servidor testado com armazenamento injetado; transporte em produção não testado |
| Mapa, medalhas, segredo e replay | Adventure, quatro nós; somente First Spark liberado; requisitos honestos nos nós fechados | Painel, replay e clique bloqueado verificados; nó fechado mantém lobby e Play inativo |
| Coleção e packs equipados | Base contém hero/frog/mounted; coleção mostra origem e silhueta bloqueada | Painéis, Preview e botão Equipped do único pack disponível verificados |
| Loja depois da vitória | Servidor e controlador; Original Pack INCLUDED; sem produtos pagos configurados | Pós-vitória observado; bloqueio pré-vitória comprovado no controlador real com fixture isolada |
| Missões e trilha sem dias consecutivos | LobbyProgress, claim servidor, 7 dias não consecutivos; moedas de propostas recomendadas | Idempotência por remotes e botão real da loja; trilha em testes de dados |
| Configurações imediatas | Fluxo/Reduced Effects/large text observados; áudio com volumes reais | Mute geral verificado também por botão real, nos dois sentidos |
| Música calma e feedback de clique/recompensa | WAVs próprios enviados ao grupo; IDs manifestados; música integrada e clique real | Música, clique e recompensa por botão real verificados |
| Confirmação do salvamento | Profile.Save mostra estado real; versão pendente não é declarada salva | Texto Local Studio session verificado; produção não testada |
| Celular e desktop | Capturas desktop/iPhone XR portrait/landscape, toque habilitado, controles >=44px | Emulador verificado; Android físico/multitouch/vibração não testados |

Não foi publicada uma versão do lugar. O repositório continua sendo a fonte de verdade via Rojo. Capturas são evidência visual das versões indicadas; não provam todas as interações nem persistência em produção.