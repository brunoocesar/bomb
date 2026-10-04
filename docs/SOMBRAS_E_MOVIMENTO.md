# Sombras e movimento — 03/10/2026

GDD 2.0, 40 páginas, relido integralmente antes da implementação. O pedido atual é adicionar sombras e deixar o movimento do player mais livre, como o do monstro. A comparação foi aplicada ao deslocamento contínuo entre casas, preservando as quatro direções e a grade de bombas/colisões.

## Mudanças

Os dois modelos GUI recebem cinco sombras discretas: uma do jogador/montaria e quatro dos inimigos. São formas arredondadas sem assets novos ou objetos físicos. Seguem o mesmo ponto de apoio interpolado usado pelos sprites, abaixo do ator na ordem de desenho. A sombra do jogador fica mais larga quando montado; desaparece na morte. Sombras dos inimigos desaparecem na derrota. A montaria compartilha a sombra do conjunto sentado, evitando duplicá-la no chão.

O movimento do player usava duração de 75% do intervalo entre passos: chegava cedo e esperava o restante. Agora usa o intervalo completo, como o patrulheiro. O ritmo entre casas foi mantido. A animação de andar acompanha a trajetória ativa mesmo depois de soltar o botão, em vez de mudar para idle antes de chegar ao apoio final. Curvas continuam guiadas pelas casas; não foi adicionado movimento diagonal nem atravessamento de obstáculos.

O controlador de teste passa a esperar a chegada visual em cada passo planejado. Antes, planejava a próxima ação a partir do destino lógico ainda não alcançado na tela. Isso corrige o controlador, sem teleportar nem alterar estado do servidor.

## Verificações

- Movimento: 330 verificações, incluindo deslocamento no quarto final do intervalo e parada nas paredes.
- Tutorial: 69; explosões: 398; feedback: 185; dois modelos GUI em 14 áreas seguras aprovados.
- Rota simulada: 13 ações, 44,6 segundos, nenhuma morte, segredo e sapinho obtidos.
- Selene sem erros/avisos; StyLua, diff e build Rojo aprovados.
- Studio confirmado: Place `140221183064352`; modelos sincronizados pelo Rojo. Captura `build/Studio-shadows-desktop.png` mostra sombras sob player e monstro.
- Observer em Play confirmou deslocamento aos 0,20 segundos de uma trajetória de 0,24 segundo, camadas corretas e sombra ampliada da montaria.
- Rota real: `BOMB_MAP_ROUTE_RESULT won 2 3 3 0 true`, duas etapas concluídas sem mortes e sapinho resgatado.
- Simulador iPhone XR: sombras verificadas em retrato e paisagem. `BOMB_MOBILE_SHADOWS_OK` confirmou visibilidade, tamanho não nulo e desenho abaixo dos atores. O direcional móvel moveu o player; a captura em paisagem mostra a posição nova e as sombras.

As verificações móveis foram no simulador do Studio, não em telefone físico. As sessões de Play foram encerradas.

Não houve alteração das imagens originais nem publicação do lugar.
