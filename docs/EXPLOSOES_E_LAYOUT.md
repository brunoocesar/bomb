# Explosões e layout — 03/10/2026

Continuação das correções visuais. GDD atual 2.0, 40 páginas, relido; escopo restrito aos dois ajustes solicitados. As regras de alcance, bloqueio, destruição, dano e reação em cadeia permanecem as existentes.

## Explosões

Causas confirmadas no código/arte: os recortes de `blastHorizontal` e `blastVertical` contêm pontas arredondadas e transparência; eram desenhados com `ScaleType = Fit` dentro de cada célula quadrada. Isso deixa espaços ao repetir os segmentos. O cliente também não distinguia pontas de intermediários e inferia a forma pela proximidade de qualquer célula em chamas.

Agora a simulação registra apenas metadados visuais: centro de cada detonação e conexões efetivamente percorridas pelos raios, com vencimento. `BlastVisual.lua` seleciona centro, conectores e pontas usando esses dados e as mesmas células perigosas da simulação. Raios próximos que não se conectam não criam curvas ou centros falsos.

Cada célula tem um contêiner de fogo reutilizado, com quatro meios segmentos e um centro. Os conectores alcançam as bordas da célula; há pequena sobreposição **interna** entre as metades. O contêiner recorta todo desenho ao limite da célula perigosa. A camada fica acima dos atores e abaixo do HUD para manter o perigo legível. As pontas só aparecem no fim da linha; paredes não recebem fogo, caixas atingidas recebem a ponta e a linha não continua atrás delas.

Os seis recortes adicionais em `MapCatalog.lua`/`map-manifest.json` usam o atlas já enviado. Não houve mudança de PNG, paleta ou IDs de imagens. `Measure-MapArt.ps1` conserva os recortes derivados quando os metadados são regenerados.

## Layout

O computador usava o layout que reserva espaço inferior para controles; a escolha do layout lateral era limitada a alturas menores que 550 px. Agora todas as telas com proporção acima de 1,4 usam controles nas laterais. A dica fica na faixa esquerda, fora da arena e acima do direcional. O header e o rodapé deixam mais altura disponível para o tabuleiro. Em retrato, os controles continuam embaixo, com margens ajustadas.

`UIAspectRatioConstraint` continua em 13/9; logo as 13×9 células ficam quadradas e os sprites mantêm a proporção. Os botões mantêm área de pelo menos 44×44 px e não cobrem tabuleiro, HUD ou dicas nas dimensões verificadas. Toda a geometria usa a área segura do ScreenGui, não a tela física inteira.

| Área segura | Largura anterior | Largura nova | Ganho |
| --- | ---: | ---: | ---: |
| Desktop 1280×680 | 606,7 px | 866,7 px | 42,9% |
| Celular horizontal 812×330 | 317,8 px | 361,1 px | 13,6% |
| Celular horizontal 568×280 | 245,6 px | 288,9 px | 17,6% |
| Retrato 320×426 | 239,8 px | 268,7 px | 12,0% |
| Retrato 375×600 | 351,0 px | 351,0 px | já limitado pela largura |

Em telas muito largas, a altura disponível continua limitando a largura de uma grade 13×9 quadrada. O ajuste aproveita essa altura melhor; não estica células nem corta o mapa para preencher toda a largura.

## Verificações executadas

- `BlastVisual.spec.luau`: 398 verificações de cobertura das células perigosas, centro, intermediários, quatro pontas, paredes, caixas, cadeia, raios paralelos, vencimento e reinício.
- `BlastArtwork.spec.ps1`: 68 verificações de alpha/cor dos conectores e encaixes das pontas no PNG de origem. O núcleo luminoso não contém frestas nesses recortes.
- `TutorialUI.spec.py`: dois layouts, 14 áreas seguras (desktop, ultrawide, retrato, paisagem e limites da troca de layout); células quadradas, ausência de sobreposição, botões mínimos e nenhuma redução da arena em relação ao layout anterior.
- Regressões: 69 verificações do tutorial, 327 de movimento/apoio e rota completa das duas etapas em 13 ações / 41,7 segundos simulados, sem mortes, com segredo e sapinho.
- Selene: zero erros/avisos. StyLua e `git diff --check` aprovados. Build Rojo atualizado: `build/Bomb-Your-Way-visual-fixes.rbxlx`.

## Prévias reproduzíveis

São renders offline dos atlas e da geometria autorada, **não capturas do Roblox**. O roteiro de exportação usa a simulação e o seletor de peças de produção; as cenas abertas, com bloqueios e com cadeia são fixtures de teste, não mudanças nas etapas do jogo.

```powershell
build/tools/luau/luau.exe tools/Export-BlastPreview.luau | Set-Content -Encoding UTF8 build/video-analysis/blast-preview-data.json
powershell -ExecutionPolicy Bypass -File tools/Preview-Arena.ps1
```

- `build/video-analysis/blast-preview.png`: cruz aberta, bloqueios, cadeia e detalhe ampliado.
- `build/video-analysis/layout-1280-680.png`: desktop.
- `build/video-analysis/layout-812-330.png`: celular horizontal.
- `build/video-analysis/layout-375-600.png`: retrato.
- `build/video-analysis/layout-measurements.json`: medidas das 14 áreas verificadas.

Não havia processo Roblox Studio aberto nesta tarefa. Nada foi publicado ou sincronizado com uma sessão. O destino Rojo permanece o lugar confirmado `140221183064352`, porta `34873`. Pendentes: conferir recortes na resolução de 1024×1024 entregue pelo Roblox, filtragem nas emendas, clareza dos atores sob o fogo, rotação da tela, toque e FPS/memória em aparelho real. Os cinco sprites por contêiner são reutilizados e ficam ocultos quando inativos, mas isso não substitui medição de desempenho no celular.
