# Arena maior e resposta de movimento — 03/10/2026

GDD atual 2.0, 40 páginas, relido integralmente. Escopo solicitado: ampliar a apresentação da arena e reduzir atraso na troca rápida de direção, preservando células quadradas, sprites proporcionais e bloqueios.

## Arena

`ArenaLayout.lua` calcula a geometria dentro da área segura do ScreenGui. Escolhe a maior célula que cabe na largura e altura reservadas: `min(largura/13, altura/9)`. O mapa inteiro permanece visível. Em paisagem, Stage/Energy/Bombs/Range ficam no espaço lateral já reservado ao direcional; o botão de pausa fica no lado direito. Isso libera a antiga faixa superior para a arena. Os controles acompanham suas bordas, com oito pixels de distância. Em retrato, HUD e direcional mantêm a organização superior/inferior, com margens menores.

Ganhos contra o layout imediatamente anterior, nas mesmas áreas seguras:

| Tela | Arena anterior → atual | Ganho no lado da célula |
| --- | --- | --- |
| 1052×430 | 505,6 → 569,1 px | 12,6% |
| 812×330 | 361,1 → 424,7 px | 17,6% |
| 667×280 | 288,9 → 352,4 px | 22,0% |
| 1280×680 | 866,7 → 930,2 px | 7,3% |
| 320×426 | 268,7 → 300,4 px | 11,8% |
| 375×600 | 351 → 359 px | 2,3% |

Nas duas áreas em que a largura já limitava o tabuleiro, não houve crescimento nem redução. O aspecto 13:9 ainda limita quanto da largura de uma tela muito larga pode ser preenchido; ocupar toda ela exigiria cortar o mapa, deformar células ou mudar sua forma. Essas alterações não foram feitas.

## Input

Causa confirmada: a simulação aguardava `nextMove` por até 0,24 segundo, inclusive depois de tentar mover contra uma parede. Agora `Simulation:steer` permite uma direção nova após bloqueio e inverte a trajetória ativa no mesmo corredor. A origem da inversão é a posição interpolada atual; a duração restante acompanha a distância, mantendo a velocidade. Entradas opostas sucessivas não teleportam nem atravessam sólidos. Uma inversão sem distância cancela a trajetória sem criar duração zero.

O servidor aplica `steer` ao receber o input válido e envia o snapshot imediatamente, em vez de aguardar o próximo tick para aceitar a direção. Nesta primeira revisão, as curvas perpendiculares esperavam o centro do corredor. A revisão posterior em [CURVAS_E_PACK_MONTADO.md](CURVAS_E_PACK_MONTADO.md) substituiu essa restrição por trajetórias com segmentos em um eixo e curvas imediatas em corredores livres. Não foi implementada predição local; a latência de rede continua existindo.

Bombas e coleta usam a célula sob o apoio visual, não o destino ainda pendente. A própria bomba permite retornar enquanto o jogador não deixou sua célula; torna-se sólida quando ele sai. A entrada no portal usa a mesma célula ocupada. Dano já usa esse mesmo apoio.

## Evidência

- 112 verificações de input: parede seguida de direção oposta, inversão antes do fim do passo, posição contínua, segunda inversão rápida, canto sólido, bomba no apoio atual, retorno à própria bomba antes de sair e bloqueio após sair, cancelamento sem duração zero.
- 14 áreas seguras: maior tamanho disponível, mapa inteiro, células quadradas, HUD separado e botões de pelo menos 44 pixels sem sobreposição.
- Regressões: tutorial 69; movimento 330; explosões 398; feedback 185. Rota simulada completa: 13 ações / 44,9 segundos, nenhuma morte, segredo e sapinho obtidos.
- Selene, StyLua, contrato dos modelos GUI, diff e build Rojo aprovados.
- Studio: Place `140221183064352`, Universe `10769176732` e grupo `204998424` confirmados. Os novos módulos e o servidor foram verificados em edição depois da sincronização pelo Rojo.
- Play: troca após direção bloqueada em 49–50 ms; inversão no meio do passo em 49–52 ms, medidas no cliente local. O teste de inversão móvel confirmou deslocamento em sentido contrário, sem teleporte. Essas medidas não garantem latência igual em servidores remotos.
- Geometria real: desktop, área segura 984,8×362, arena 407,3 → 470 px; móvel em paisagem, 801×334, arena 366,9 → 430 px; retrato, 412×754, arena 388 → 395,8 px. Limites reais dos textos e proporção das células aprovados.
- Rotas reais completaram duas etapas e resgataram o sapinho: desktop com uma morte; simulador móvel com duas mortes. Não constituem comprovação de rota real sem mortes. As causas dessas mortes não foram confirmadas.

Capturas: `build/Studio-arena-expanded-desktop.png`, `build/Studio-arena-expanded-mobile-landscape.png`, `build/Studio-arena-expanded-mobile-portrait.png`. Verificação móvel no simulador do Studio; nenhum teste em aparelho físico ou medição de FPS/memória foi realizado. Não houve publicação do lugar.
