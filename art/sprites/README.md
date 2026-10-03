# Sprites de Bomb Your Way!

## Organização

- `hero/base`: protagonista sem roupas, separado da montaria.
- `frog/base`: sapinho sem cavaleiro desenhado junto.
- `hero/skins` e `frog/skins`: futuras aparências independentes.
- `generation-prompts.md`: prompts usados com a ferramenta integrada de geração de imagens.
- `sprite-manifest.json`: dimensões reais, recortes e sequências de animação.
- `preview.html`: prévia animada local; abra no navegador, sem servidor ou instalação.

O atlas principal do protagonista tem sete linhas. A caminhada de costas fica na quarta linha do atlas complementar `hero-movement-v1.png`. O manifesto seleciona apenas os quadros necessários desse complemento; não presume uma grade de oito linhas no protagonista. O atlas selecionado do sapinho é `frog-clean-v1.png`; `frog-v1.png` preserva a primeira geração como referência.

Os PNGs são arquivos de arte com transparência, fora da árvore sincronizada pelo Rojo. Em 03/10/2026, os três atlas selecionados foram enviados pelo importador do Studio ao grupo **204998424 — Capyboom Studios**. Seus IDs estão em `game/Shared/SpriteImages.lua` e no registro `roblox-assets.json`. O Roblox entregou imagens de 1024×1024; os originais têm 1254×1254. O cliente converte os recortes para a resolução entregue sem alterar os PNGs locais. Rojo sincroniza os vínculos, não faz upload de imagens.

## Contrato para skins

Cada skin completa substitui apenas o atlas da sua entidade. Ela deve preservar a ordem dos quadros, as direções, a anatomia, a proporção e o ponto de apoio. Não desenhe o protagonista dentro da imagem do sapinho: a composição montada usa duas imagens independentes.

Crie uma pasta por aparência, por exemplo `hero/skins/astronaut` ou `frog/skins/pond`. Guarde nela o PNG e seu manifesto. Não sobrescreva a base. Caso mude a resolução, registre novos recortes em pixels; mantenha o mesmo espaço lógico e pontos de apoio.

Roupas e acessórios combináveis devem ser overlays transparentes por quadro, alinhados ao corpo base, com camadas separadas para cabeça, rosto e roupa. O pavio deve permanecer visível. Os arquivos atuais são corpos base completos; as camadas de roupas serão produzidas quando houver uma aparência definida.

As skins são cosméticas: não alteram colisão, velocidade, alcance, proteção ou demais regras do jogo. A futura implementação deve manter a simulação independente da imagem e usar o mesmo quadro para corpo e overlays.

## Animações e uso

As linhas de caminhada têm oito quadros para cada direção. A ordem é frente (`down`), esquerda (`left`), direita (`right`) e costas (`up`). O manifesto descreve as demais poses sem presumir que toda ação tenha uma sequência lateral própria.

Os recortes usam as dimensões reais do PNG, que podem diferir da resolução solicitada ao gerador. Não suponha células de 256 pixels. Os pontos de apoio são derivados dos limites visíveis de cada quadro para facilitar o alinhamento inicial. A composição com roupas e cavaleiro ainda precisa de ajuste visual na integração.

As poses de ação são keyframes para sequências curtas; não são animação esquelética. A suavidade, o tempo de cada quadro, a leitura em tela pequena e a composição montada precisam de teste real no Roblox. A conferência dos PNGs não substitui esse teste.
