# Bomb Your Way!

Aventura 2D de campanha solo para Roblox, com sprites e objetos em ScreenGui. Bombas abrem caminhos e destroem caixas de energia para avançar entre etapas com inimigos, segredos e sapinhos resgatáveis.

Leia [Plano_Profissional_Bomb_Your_Way (1).pdf](<Plano_Profissional_Bomb_Your_Way (1).pdf>) antes de cada tarefa e siga [AGENTS.md](AGENTS.md). O arquivo atual é o GDD versão 2.0, com 40 páginas, e substitui integralmente o plano anterior. Respeite as categorias APROVADO, RECOMENDADO e FUTURO do documento. Conversas e documentação podem ser em português; o jogo deve estar em inglês.

## Estado atual

A primeira fase do tutorial, **First Spark**, está implementada em duas etapas: Garden Gate e Rescue Courtyard. Inclui movimento, bombas, explosões em cadeia, caixas de energia, portas, inimigos, melhorias, segredo, sapinho e resultados. Veja [como testar e as limitações atuais](docs/TUTORIAL.md).

O tutorial está sincronizado pelo Rojo no lugar **Bomb Your Way!**, Place ID **140221183064352**, confirmado pelo usuário. Pressione **Play** no Studio. Use WASD/setas e Espaço, ou os controles de toque. P abre a pausa. O tutorial começa diretamente.

Os [sprites do protagonista e do sapinho](art/sprites/README.md) estão separados para futuras skins. Os três atlas foram enviados ao grupo Capyboom Studios e vinculados ao jogo. O Play real confirmou os recortes do personagem, movimento por teclado, bomba, fuga e destruição do primeiro obstáculo. A composição montada e aparelhos reais ainda precisam de validação.

Os [mapas do tutorial](art/maps/README.md) usam fundos cartunescos e sprites próprios para paredes, caixas, energia, itens, inimigos, bombas e explosões. A saída possui imagens distintas para cadeado fechado e portal aberto, com contador e brilho. Os três assets de cenário também estão enviados e vinculados ao mesmo grupo.

## Rojo

Rojo 7.7.0 está fixado em rokit.toml e aftman.toml. Execute a tarefa **Rojo: Serve** no VS Code ou:

```powershell
rojo serve default.project.json --address 127.0.0.1
```

No lugar confirmado **140221183064352**, conecte o plugin Rojo a localhost:34873. A configuração aceita apenas esse Place ID. Só altere novamente o destino após confirmação do usuário. Não publique versões do lugar automaticamente.

Execute a tarefa **Rojo: Build** ou:

```powershell
rojo build default.project.json --output build/Bomb-Your-Way.rbxlx
```

O build contém o tutorial. No Studio, o progresso é mantido somente durante a sessão de Play; nada foi publicado.

| Diretório | Destino |
| --- | --- |
| game/Shared | ReplicatedStorage.Shared |
| game/Assets | ReplicatedStorage.Assets |
| game/Server | ServerScriptService.Server |
| game/Client | StarterPlayer.StarterPlayerScripts.Client |
