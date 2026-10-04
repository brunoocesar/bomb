# Curvas responsivas e pack montado — 03/10/2026

Revisão solicitada após a melhoria de inversões esquerda/direita. O GDD 2.0 de 40 páginas foi relido integralmente. A nova orientação do usuário define skins como packs completos, substituindo a escolha independente de aparência de personagem e sapinho.

## Diagnóstico confirmado

`Simulation:steer` rejeitava toda mudança perpendicular enquanto havia um movimento ativo. Apenas inversões no mesmo eixo eram aceitas. O cliente já enviava a direção recém-pressionada imediatamente; a restrição estava na simulação.

A montaria ainda era composta por dois `ImageLabel`s. Os frames sentados antigos continham somente o cavaleiro, sem composição desenhada para preservar a cabeça e a silhueta do sapo. O novo asset foi produzido especificamente para os dois juntos; os atlas anteriores foram preservados.

## Movimento

`ActorMotion` passou a suportar trajetórias formadas por segmentos em um único eixo, com velocidade constante por distância percorrida. Posição apresentada, célula de colisão, coleta, colocação de bomba e dano usam a mesma trajetória. O destino final permanece no centro de uma célula inteira.

Em corredor aberto, uma troca entre eixos começa pelo eixo solicitado na posição visual atual, sem salto nem trecho diagonal. Ao chegar ao novo corredor, um pequeno segmento alinha o apoio ao centro da grade. O servidor verifica as duas faixas de células sob um apoio descentralizado, incluindo pedras, caixas, bombas sólidas e saída fechada.

Perto de um canto sólido, o movimento busca o cruzamento acessível mais próximo antes de executar a curva. Esse alinhamento geométrico pode levar parte de um passo; não há promessa de atravessar uma pedra imediatamente. Uma direção impossível não cria um novo cooldown sobre a trajetória que já estava ativa. Retornar à direção anterior atualiza a orientação imediatamente.

O servidor continua autoritativo e envia o snapshot quando recebe a entrada. Não há predição local: latência de rede e a frequência do servidor ainda afetam a resposta.

## Montaria e skins

- Asset: `art/sprites/mounted/base/mounted-v1.png`, produzido com a ferramenta integrada imagegen, referências dos dois atlas existentes e fundo transparente.
- Atlas: 16 poses, quatro direções com quatro frames de caminhada; idle usa a primeira pose da direção.
- Roblox: `91298046318312`, proprietário conferido como grupo 204998424; tamanho entregue 1024×1024, original 1254×1254.
- Recortes medidos em quatro faixas, com limites verticais 0, 311, 614, 917 e 1254. Dividir em quartos iguais cortava a chama das costas e incluía esse pedaço na linha de direita, deslocando seu apoio. Os recortes corrigidos têm margens transparentes em todos os lados.
- Escala uniforme de pixels: 0,0032 célula por pixel original. O ponto de apoio medido de cada frame coincide com (0,5; 0,82) da célula, sob os pés do sapo. Não há deformação por direção.
- O cliente usa somente `Hero.Sprite` com o atlas montado e esconde a entidade `Frog` da arena. O HUD continua usando o sapinho separado do mesmo pack.
- O pré-carregamento dos atlas do pack acontece em segundo plano para reduzir o aparecimento vazio na primeira montagem; controles não esperam esse carregamento.

`SkinPacks.lua` resolve as três formas pelo mesmo ID. `skinPack` e `ownedSkinPacks` são preservados no perfil/checkpoint. `equipSkinPack` é validado no servidor: pack desconhecido ou não possuído é rejeitado. Reinício, replay e perda da montaria mantêm o cosmético equipado; aparência não concede resgate nem proteção.

Apenas o pack base existe. O contrato está pronto para novas aparências completas, mas não foi criada loja ou coleção nesta revisão. Dano, vitória, montar e desmontar com arte montada específica continuam sem atlas próprio; o jogo atual não solicita essas animações.

## Verificações executadas

Testes Luau: entrada 2524 verificações; packs 225; movimento visual 330; tutorial 69; explosões 398; feedback 185. Rota completa na simulação: 13 ações, 44,9 segundos simulados, sem mortes, segredo e sapinho resgatados. Contrato de UI validado em 14 áreas seguras. Selene sem erros ou avisos; build Rojo concluído.

Studio conectado ao Place ID 140221183064352 / Universe ID 10769176732. Nenhuma versão do lugar foi publicada. Foram usados os remotes normais do jogo; não houve teleporte nem alteração de posição do servidor para os percursos.

- Computador: as oito trocas entre eixos confirmadas em 50–52 ms locais, com verificação do início do segmento no eixo solicitado. A montaria foi resgatada e o atlas carregado. Frente, esquerda, direita e costas mantiveram apoio visual a menos de 1,5 pixel do esperado, sem duplicar sapo nem esticar a imagem.
- Simulador iPhone XR, toque habilitado: as oito trocas passaram novamente na versão final, 50–52 ms locais. A montaria foi resgatada pelo percurso normal e inspecionada nas orientações horizontal e vertical. As quatro direções foram verificadas com o mesmo teste de apoio e proporção.
- Os últimos percursos de resgate no desktop e celular chegaram à montaria com zero mortes. Um percurso preliminar teve uma morte; a causa não foi investigada nesta revisão. Não foi executada uma campanha completa real como garantia de ausência de mortes.
- A primeira conferência, logo após upload, tentou afirmar carregamento depois de 0,3 segundo e falhou. Mais tarde `ImageLabel.IsLoaded` confirmou a imagem; o verificador agora espera até dez segundos. Houve também retorno `Failure` em uma chamada diagnóstica isolada de PreloadAsync com a imagem já visível. O estado visual carregado e a inspeção real fundamentam a validação; não se afirma que todo preload terminou com sucesso.

Capturas: `build/Studio-mounted-desktop.png`, `build/Studio-mounted-mobile-landscape.png` e `build/Studio-mounted-mobile-portrait.png`. Prévia dos recortes: `build/video-analysis/mounted-preview.png`. Prompt completo: `art/sprites/mounted/generation-prompt.md`.

Limites: celular físico, condições reais de rede, FPS/memória prolongados e persistência em DataStore de produção não foram testados. Os testes de entrada automatizados enviaram os remotes normais; não representam gestos simultâneos de dois dedos em aparelho físico.
