# Sprites de Bomb Your Way!

Cada skin é um pack completo. A orientação mais recente do usuário substitui o contrato anterior de aparências independentes para protagonista e sapinho.

- `hero/base`: protagonista a pé; `hero-movement-v1.png` complementa a caminhada de costas.
- `frog/base`: sapinho sem cavaleiro, usado também pelo ícone do HUD.
- `mounted/base/mounted-v1.png`: terceiro tipo de sprite; protagonista sentado no sapinho, desenhados juntos.
- `sprite-manifest.json`: recortes medidos, pontos de apoio e sequências.
- `roblox-assets.json`: registro de uploads ao grupo 204998424, Capyboom Studios.
- `preview.html`: prévia local das três formas.

## Contrato de packs

Um único `skinPack` equipado seleciona os atlas `hero`, `heroMovement`, `frog` e `mounted`. O catálogo fica em `game/Shared/SkinPacks.lua`. O perfil salva esse identificador e os packs possuídos; o servidor aceita `equipSkinPack` apenas para packs existentes e possuídos. Apenas o pack base existe atualmente. A loja e a coleção de skins ainda não estão implementadas.

Uma nova aparência precisa entregar as três formas completas, inclusive a caminhada de costas do personagem a pé. Crie uma pasta versionada por pack; preserve a base. Cada atlas deve registrar dimensões, colunas, recortes e animações no catálogo. Não misture personagem de um pack com sapinho ou montaria de outro.

O atlas montado tem quatro colunas e quatro linhas: frente, esquerda, direita e costas. Cada linha fornece quatro poses de caminhada; idle usa a primeira pose, sem alternar pernas parado. A imagem mostra o sapinho reconhecível e o cavaleiro sentado, com pés laterais. A base visual acompanha os pés do sapinho. O cliente exibe uma única imagem montada; não sobrepõe novamente os dois atlas separados.

Os recortes preservam a proporção original e usam escala uniforme de pixels. O ponto de apoio medido compensa as margens transparentes de cada quadro. As skins nunca alteram colisão, velocidade, dano, alcance ou proteção. A aparência equipada não concede a montaria: ela continua dependendo do resgate e pode ser perdida ao receber dano.

## Integração

Os PNGs ficam fora da árvore do Rojo. Rojo sincroniza módulos e vínculos; o importador do Studio envia as imagens. Os quatro atlas foram enviados em 03/10/2026 ao grupo autorizado. Os originais possuem 1254×1254 pixels; o Roblox entrega 1024×1024. O cliente converte os recortes à resolução entregue.

Os atlas antigos mantêm seus recortes e sequências. A antiga linha de poses sentadas do protagonista permanece no catálogo como referência de arte; a renderização montada agora usa o terceiro atlas. O atlas novo contém caminhada e idle nas quatro direções. Ações montadas específicas de dano, vitória, montar e desmontar ainda não foram produzidas; o jogo atual não as solicita.

Para regenerar metadados, execute `tools/Measure-SpriteAtlases.ps1` e `tools/Generate-SpriteCatalog.py`. A geração preserva os PNGs e os IDs enviados. `tools/SkinPacks.spec.luau` valida resolução de frames, suporte visual e persistência do pack; `tools/Preview-Mounted.ps1` gera uma prévia estática.
