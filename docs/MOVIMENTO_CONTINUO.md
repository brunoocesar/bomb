# Movimento contínuo e HUD — 05/10/2026

O GDD v2.0 foi relido e os frames extraídos do vídeo anexado foram examinados antes da edição. O vídeo mostra deslocamento aparente por etapas; a causa foi confirmada no código, sem atribuir o problema à arte.

## Causa e implementação

Tutorial.client.lua lia WASD, setas, botões e analógico, escolhendo uma direção. Tutorial.server.lua encaminhava essa direção e atualizava a simulação em blocos de 0,05 segundo. Simulation:steer criava caminhos com destinos arredondados aos centros, ActorMotion.beginPath executava o trecho e nextMove controlava a próxima partida. A soltura não cancelava o trecho iniciado. Essa arquitetura ainda obrigava parte das mudanças de direção a alcançar uma interseção.

Agora steer altera apenas o vetor de entrada. Simulation:step integra a posição fracionária pelo tempo decorrido, com a mesma velocidade definida por moveInterval. Não há destino de célula nem encaixe automático. O servidor usa o dt de Heartbeat, subdividido em intervalos de até 0,025 s para colisões e perigos. A frequência de mensagens permanece próxima de 20 Hz, separada da física.

PlayerMovement resolve o contato varrido por eixo, permitindo deslizar quando um eixo está bloqueado. Usa a base visual anterior nas pedras internas; caixas, bombas, portão e bordas também bloqueiam o contato. A restrição de ocupação abaixo das pedras mantém o ponto lógico fora da célula sólida. Não é colisão por contorno de pixels. O passe inicial pela bomba recém-colocada termina quando o contato inteiro sai dela, evitando tornar o objeto sólido enquanto o jogador ainda o sobrepõe; depois não permite reentrada.

O cliente combina teclas/botões dos dois eixos e preserva a magnitude do analógico. Vetores diagonais são limitados a comprimento 1. O analógico tem zona morta radial e envio limitado, preservando a resposta local. Os sprites continuam com quatro orientações; não foi criada arte diagonal.

PlayerPrediction integra uma posição visual contínua entre mensagens, usando a mesma colisão. Cada mudança recebe uma sequência, confirmada pelo servidor. A soltura congela a previsão imediatamente; o servidor confirma a posição final. Checkpoints, pausa, morte e divergências grandes corrigem a previsão. O servidor continua responsável por posição válida, bombas, dano e objetivos. A verificação de teclado registrou correção final de aproximadamente 0,015 célula, inferior a um pixel na prévia utilizada; não se afirma ausência de correções de rede em qualquer conexão.

ActorMotion.cell continua escolhendo a célula mais próxima para bombas, itens e perigos. Esse arredondamento não escreve na posição do jogador. Fusão, alcance, dano, mapas e objetivos foram preservados.

## HUD

ScreenGuis continuam com DeviceSafeInsets conforme a solicitação do usuário. Como essa modalidade não reserva espaço para a interface do Roblox, Tutorial.client calcula a diferença para CoreUISafeInsets com GuiService:GetInsetArea. ArenaLayout reserva esse espaço e adapta o layout em janelas muito baixas. Mantém células quadradas e controles separados da arena.

Referência oficial: [ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets) e [GuiService:GetInsetArea](https://create.roblox.com/docs/reference/engine/classes/GuiService#GetInsetArea).

## Arquivos desta correção

- game/Shared/PlayerMovement.lua: vetor, deslocamento e colisão contínuos.
- game/Shared/PlayerPrediction.lua: apresentação contínua e confirmação das entradas.
- game/Shared/Simulation.lua: integração do jogador, ocupação e saída da própria bomba.
- game/Server/Tutorial.server.lua: validação de vetores/sequências e física por dt.
- game/Client/Tutorial.client.lua: combinação de controles, previsão e área segura da HUD.
- game/Shared/ArenaLayout.lua: reserva superior e layout compacto.
- tools/ContinuousMovement.spec.luau, PlayerPrediction.spec.luau, InputResponse.spec.luau, ObstacleCollision.spec.luau, VisualMotion.spec.luau, Tutorial.spec.luau, TutorialRoute.spec.luau e ArenaLayout.spec.luau: testes atualizados para deslocamento fracionário. O controlador da rota anda por durações explícitas e solta a entrada; não teleporta o jogador.
- tools/Studio-Desktop.ps1: suporte a teclas simultâneas com duração limitada para QA nativo.

## Evidência de validação

Place confirmado: 140221183064352, Universe 10769176732, Rojo conectado. No servidor final em execução, entradas normais mantiveram direção por três segundos; mudanças sem stop intermediário chegaram a x=2,7605/y=3,0643. A diagonal registrada tinha componentes 0,7071. O contato com a parede parou x em 4,28, enquanto y avançou de 3,5467 para 4,2380 durante o deslizamento. A soltura manteve a posição fracionária. Uma bomba em x=4,28/y=4,3323 apareceu em 4:4, com coordenadas inteiras 4/4.

Teclado real no viewport: direção mantida, combinação W+D e liberação. O observador final coletou 1081 frames e 368 estados em 18 s; a apresentação avançou entre mensagens e parou antes da confirmação de soltura. Os botões Down e Right também foram mantidos e soltos no iPhone XR emulado: paradas em y=3,4551 e x=3,5361, sem finalizar uma célula.

HUD conferida em janela ampla e estreita e no iPhone XR em landscape. Stage, Energy e Stats tinham TextFits=true e apareceram abaixo dos botões do Roblox. Capturas finais em build/Studio-continuous-desktop-final.png, Studio-continuous-narrow-final.png e Studio-continuous-mobile.png.

Os módulos sincronizados passaram no Roblox 69 verificações de movimento e 1193 de previsão. Incluem intervalos equivalentes a 5, 10, 15, 20, 30, 60, 120 e 144 atualizações por segundo, distância mantida e diagonal, liberação fracionária, obstáculos e bombas. A previsão cobre mensagens atrasadas em várias frequências. Esses intervalos foram controlados nos testes; o limite gráfico do computador não foi alternado. A sessão de teclado observou aproximadamente 60 frames por segundo. Não houve teste em celular físico nem controle físico de console.

Regressões locais: entrada 246, pedras 821, tutorial 69, apresentação 329, skins 211 e animação 2385; rota completa de 14 ações/45,6 s simulados, sem mortes, com segredo e sapinho. Contrato de UI em 14 proporções e testes adicionais com reservas superiores de 36/58/64 pixels. Selene e build Rojo aprovados. Nenhuma versão do lugar foi publicada.
