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