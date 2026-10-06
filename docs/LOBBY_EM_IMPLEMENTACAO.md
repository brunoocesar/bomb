# Lobby — estado atual

Implementação do acampamento do GDD 2.0 para o conteúdo existente de Bomb Your Way!: First Spark, Garden Gate e Rescue Courtyard. Interface do jogo em inglês; navegação por mouse, teclado e toque. O usuário substituiu cosméticos independentes por packs completos de personagem, sapinho e sprite montado.

## Entrega

- Fundo próprio de clareira cartoon, tendas, caixas, caminho e ícones ilustrados. Personagem central animado, giro e preview montado/em pé; painéis preservam seu espaço.
- Adventure com quatro nós conectados, medalhas, segredo, checkpoint e replay. Somente a fase existente está disponível; os demais nós explicam que a trilha não está aberta.
- Character e Frogs com Original Pack completo, origem do resgate e silhueta bloqueada. Loja após a primeira vitória, preview honesto do pack incluído e suprimentos gratuitos; nenhum produto pago fictício.
- Moedas, perfil e configurações no topo. Missões e próxima recompensa no rodapé. Trilha de sete coletas em dias não consecutivos, sem reinício por ausência; recompensas recomendadas sujeitas a balanceamento.
- Configurações de música, efeitos sonoros, silêncio geral, vibração, redução de efeitos, lado/opacidade dos controles e texto grande. Inglês disponível. Preferências sanitizadas e salvas com o perfil.
- Primeira sessão na aventura; perfil retornando abre o lobby. Continue preserva a etapa/posição na sessão; replay conserva conquistas e inicia nova tentativa.
- Música calma, clique e recompensa próprios enviados ao grupo autorizado. Salvamento autoritativo com bloqueio de sessão, migração, retry e recompensas idempotentes. Perfil mostra o estado real de salvamento.

## Assets

Fundo 91547200008356; atlas de ícones 131533049817842. Música 139323405075519; clique 94723519223362; recompensa 102483984204817. Proprietário confirmado: grupo 204998424. Fontes/prompts em art/lobby e art/audio/camp; manifestos registram IDs e fontes. Place ID autorizado: 140221183064352, Universe ID 10769176732. Rojo em 127.0.0.1:34873.

## Evidência

Desktop e emulador iPhone XR em portrait/landscape: imagens carregadas, sete painéis, contraste, áreas seguras, controles de giro/Back >=44px, arrasto com acesso aos controles inferiores. Interações reais confirmadas: giro, Back preservando direção, preview, Equipped, mute nos dois sentidos, nó bloqueado e coleta de suprimentos. Coleta 20→23 moedas, segundo clique conservando 23, som carregado e texto CLAIMED TODAY.

Fluxo por entradas normais: vitória→lobby, replay, configurações pausando tempo da arena e Continue preservando posição/etapa. Áudio integrado: música avançando, mute, volumes, pausa na aventura e retomada no camp. Trilha visual atual confirmada após recarga dos assets; não se usa o clone antigo como evidência.

A última recarga confirmou BOMB_LOBBY_PROFILE_WRAPPER_VERIFIED e BOMB_LOBBY_PROFILE_INTEGRATION_VERIFIED: módulos reais de perfil carregados, sessão inicial na aventura, configurações pausando, mute aplicado, retorno pausado e retomada normal. Testes de repositório: 21 verificações de reconexão, bloqueio, expiração, falha/retry e rejeição de token antigo. ProfileData: 20; LobbyProgress: 32; LobbyLayout: 336 em 14 áreas seguras. Selene dos módulos alterados sem erros/avisos; build Rojo concluído.

## Limites e conteúdo posterior

Studio usa perfil local e não grava no DataStore de produção. Reconexão, persistência, idempotência e token antigo foram também verificados com DataStore real em ensaio isolado no Studio. Dois servidores publicados de produção não foram testados. Android físico, multitouch, vibração física e desempenho em celular fraco também não foram testados. Esses limites não devem ser apresentados como testes executados.

O projeto ainda não contém fases seguintes, outros mundos, packs adicionais ou produtos pagos. NEXT PHASE/NEW WORLD dependem desse catálogo; o lobby atual apresenta seleção/replay ao fim do conteúdo disponível. Não foram criados destinos, preços ou compras fictícios, nem implementada a campanha completa sem solicitação.

Nenhuma versão do lugar foi publicada. Repositório e assets autorais são a fonte de verdade. A auditoria por requisito está em AUDITORIA_LOBBY.md; o registro cronológico das tentativas e correções foi preservado em HISTORICO_VALIDACAO_LOBBY.md.

## Validação real concluída — 05/10/2026

Após autorização explícita do usuário, o acesso do Studio às APIs foi habilitado temporariamente. No Place ID 140221183064352 / Universe ID 10769176732, o repositório real gravou e reabriu uma chave qa-UUID no armazenamento exclusivo BombYourWay_Lobby_QA_v1. Checkpoint na etapa 2, sapinho resgatado, mute e saldo de 3 moedas foram preservados; a coleta repetida foi recusada e o token da sessão antiga não pôde sobrescrever a nova sessão.

Evidência no log: BOMB_LOBBY_CLOUD_QA_VERIFIED 2 3 true em 14:17:20 UTC; BOMB_LOBBY_CLOUD_QA_CLEANED true em 14:17:21 UTC. Somente a chave criada pelo ensaio foi removida. O armazenamento BombYourWay_Tutorial_v1 e perfis reais não foram acessados.

O acesso às APIs foi desabilitado novamente e a configuração foi salva. Uma consulta somente leitura em 14:19:00 UTC recebeu StudioAccessToApisNotAllowed / HTTP 403, confirmando a restauração. Nenhuma versão do lugar foi publicada por esta operação. O teste comprova transporte real com duas instâncias do repositório no Studio; não simula dois servidores publicados.

Encerramento: ProfileRepository.close espera gravações em andamento e repete falhas dentro do prazo restante em PlayerRemoving e BindToClose. Foram aprovadas 21 verificações do repositório e BOMB_LOBBY_CLOSE_RETRY_VERIFIED 41 no módulo sincronizado, com falha transitória injetada.
