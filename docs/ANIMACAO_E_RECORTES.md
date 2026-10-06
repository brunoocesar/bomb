# Animação e recortes — 05/10/2026

As imagens originais e os frames extraídos do vídeo foram examinados antes das alterações. O vídeo mostra a montagem anterior, com personagem e sapinho separados; a implementação atual usa o atlas montado único. Nenhum PNG original nem ID de imagem foi alterado.

## Causas confirmadas e correções

| Problema | Evidência | Correção |
| --- | --- | --- |
| Olhos fechando repetidamente no repouso | O ciclo idle frontal incluía frames abertos e fechados, reproduzidos continuamente. | Idle mantém o frame aberto. SpriteAnimation seleciona piscadas com intervalo variável de 3–6 s e duração de 0,1–0,2 s. Cada visual possui um único proprietário de seleção; o renderizador existente aplica o resultado. |
| Duas marcas abaixo do sapinho | O recorte antigo de frog_r4_c3 alcançava y=784 e incluía os olhos de frog_r5_c3, que começam em y=780. Outros recortes uniformes incluíam pés da linha anterior ou cortavam cabeça/pernas. | Recortes explícitos em frog/frame-crops.json, medidos por componentes da imagem original. A cabeça e os pés do salto foram preservados. A linha de efeitos recebeu limites próprios para excluir os olhos da celebração seguinte. |
| Escala variando | O lobby ajustava cada frame pela sua área opaca individual. | Uma escala comum de pixels usa o envelope completo do atlas; hero e heroMovement compartilham o envelope para mudanças de direção. A arena mantém sua escala comum por forma. |
| Salto achatado pelo alinhamento | Alinhar todos os frames pelos pés individuais eliminaria a elevação desenhada. | A sequência de salto usa plano de apoio comum em y=916 no atlas, enquanto os pés podem subir. Celebração usa y=1216. |
| Faixa arredondada sob os atores | PlayerShadow e sombras do lobby eram Frames com UICorner, formando cápsulas. | Sombras separadas dos sprites, com geometria oval e dimensões proporcionais. O sapinho separado no lobby tem sua própria sombra. |

## Pendências reais de arte

- hero_r3_c0 tem área opaca de 105×146 pixels; hero_r3_c2 tem 108×146. frog_r4_c0 tem 118×107; frog_r4_c2 tem 120×103. Essas diferenças permanecem na imagem original. Para volume perfeitamente constante na piscada, o artista precisa revisar os frames fechados hero_r3_c2 e frog_r4_c2 usando os abertos como referência. O código não deforma os frames para esconder isso.
- hero_r6_c5 contém uma sombra cinza desenhada abaixo dos pés. A inspeção isolada está em build/hero-r6-c5-inspection.png. Esse frame não participa da caminhada atual, que usa heroMovement para costas. Remover a sombra embutida exige editar a arte se essa pose vier a ser utilizada.
- A piscada frontal usa arte existente. Faltam poses de olhos fechados em repouso para hero esquerda/direita, frog esquerda/direita e mounted frente/esquerda/direita. Costas não mostra olhos. Não se improvisaram essas poses deformando imagens abertas.

## Verificações realizadas

Os relatórios estáticos hero-frame-inspection.png e frog-frame-inspection.png mostram os frames congelados com recorte e apoio. O novo art/sprites/frame-inspector.html inicia parado e oferece seleção de frame, sequência, piscada, limite antigo do sapinho e apoio. Não substitui preview.html. A página HTML não teve validação de execução em navegador nesta tarefa; a visualização equivalente foi executada no Roblox.

No Place 140221183064352, com Rojo conectado, foram examinados os sprites carregados pelo Roblox: repouso aberto, piscada fechada e salto completo com cabeça e pés, usando limites azuis e apoio rosa. A sequência temporária de 10,50 s registrou piscadas de 0,154 e 0,172 s, e todos os oito frames de salto. O teste de seleção executado no Studio passou 2384 verificações antes da última ampliação de cobertura.

Uma observação posterior da arena real coletou 721 amostras em 12 s: piscadas de aproximadamente 0,181 e 0,192 s, com retorno ao frame aberto. O lobby foi validado em uma fixture isolada do controlador real, nas quatro direções, com sapinho separado e sombras ovais; não foi uma nova vitória nem alteração de perfil salvo. Capturas: Studio-sprite-frames-frozen.png, Studio-sprite-blink-frozen.png e Studio-sprite-lobby-integration.png.

Validação final local: SpriteAnimation 2385, VisualMotion 330, SkinPacks 211; contrato de UI em 14 viewports com área segura; Selene sem erros/avisos; build Rojo concluído. Não houve medição de FPS nem teste em aparelho físico. As visualizações temporárias não integram o cliente normal. Nenhuma versão do lugar foi publicada.

Para reproduzir os metadados: Measure-FrogComponents.ps1, Annotate-FrogCrops.py, Measure-SpriteAtlases.ps1 e Generate-SpriteCatalog.py. Os dois primeiros trabalham sobre a imagem limpa existente; a cadeia preserva os PNGs.
