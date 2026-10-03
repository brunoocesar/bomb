# Instruções do projeto — Bomb Your Way!

## Leitura obrigatória

Antes de qualquer tarefa, leia integralmente [Plano_Profissional_Bomb_Your_Way (1).pdf](<Plano_Profissional_Bomb_Your_Way (1).pdf>), inclusive antes de planejar ou alterar arquivos. Releia o PDF a cada nova tarefa: ele é a referência de visão, escopo e produção. Considere também as instruções mais recentes do usuário. Se não conseguir ler o documento, informe a limitação e não invente requisitos.

Este é o GDD versão 2.0, com 40 páginas no arquivo atual. Ele substitui integralmente o PDF anterior; não use a versão antiga como referência. Preserve as distinções do documento: APROVADO é direção definida, RECOMENDADO é proposta sujeita a teste e FUTURO está fora do lançamento. Exemplos de textos em português no PDF devem ser adaptados para inglês no jogo.

## Idioma e projeto

Converse com o usuário em português. Apenas o jogo em si deve estar em inglês: textos exibidos, menus, dicas, controles, nomes apresentados e resultados. A documentação pode estar em português. Preserve nomes externos e caminhos quando necessário.

Esta pasta pertence exclusivamente a **Bomb Your Way!**. Fire and Water, Bomb Your Friends! e outros jogos não definem requisitos para este projeto. Não reutilize seus personagens, regras, fases ou contratos de assets como requisitos atuais.

## Base do PDF

- Aventura 2D com sprites e objetos em ScreenGui, campanha solo e prioridade para celular.
- Movimento em quatro direções e botão principal de bomba; explosões seguem linhas da grade e param em paredes resistentes.
- Destruir todas as caixas de energia abre a saída. Eliminar todos os inimigos só é obrigatório em arenas específicas.
- Protagonista laranja em forma de feijão, barriga creme e pavio expressivo; sapinho verde-água resgatável como montaria.
- Quatro fases por mundo, divididas em etapas; portas são checkpoints salvos e morrer reinicia a etapa.
- Primeira sessão entra diretamente na aventura; lobby e loja aparecem depois da primeira vitória.
- Campanha, medalhas, segredos, cosméticos e desafios; monetização cosmética sem poder permanente no lançamento.
- Primeiro marco: protótipo de movimento, grade, bombas, explosão, dano e controles móveis. Depois: fatia vertical de três etapas.

Exemplos e quantidades sugeridas não substituem decisões pendentes. Mundos, inimigos iniciais, power-ups, história e antagonista ainda precisam ser definidos. Não implemente toda a campanha sem solicitação.

## Rojo e Studio

O repositório é a fonte de verdade. Use Rojo para sincronizar mudanças; scripts editados apenas no Studio não substituem os arquivos locais.

A configuração usa 127.0.0.1:34873 e servePlaceIds: [140221183064352]. Em 03/10/2026, o usuário confirmou o lugar **Bomb Your Way!**, Place ID **140221183064352**, Universe ID **10769176732**, do grupo **204998424**, e autorizou sincronizar o jogo e enviar as imagens. Só altere novamente o destino após confirmação do usuário. Não publique versões do lugar automaticamente nem sincronize com lugares de outros projetos.

Quando houver acesso ao Studio, verifique a sessão, o Place ID e a hierarquia antes de alterações. Builds, prévias e verificações estáticas não comprovam comportamento no Roblox.

## Qualidade

Valide controles, legibilidade, sobreposição e desempenho em desktop e celular nas mudanças relevantes. Priorize resposta dos controles, clareza das explosões, objetivos e salvamento confiável conforme o PDF. Registre limitações e resultados reais sem afirmar testes que não foram executados.
