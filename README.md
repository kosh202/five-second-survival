# Five Second Survival

Protótipo inicial de um survival de hordas 2D feito no **Godot 4.7.2** (renderer **Compatibility / GL Compatibility**), pensado para rodar no navegador no futuro (CrazyGames). Esta pasta contém só a primeira versão jogável: mover, ser perseguido, tomar dano e reiniciar.

A premissa: uma comida caiu no chão e precisa sobreviver à invasão de germes durante os “cinco segundos” da regra dos cinco segundos. No mundo microscópico, esses segundos viram vários minutos de caos.

## Como abrir o projeto

1. Instale o **Godot 4.x Standard** (este repositório foi criado com **4.7.2.stable**).
2. Abra o Godot e escolha **Import** / **Importar**.
3. Selecione o arquivo `project.godot` desta pasta.
4. Confirme a importação e abra o projeto.

## Como executar

- **F5** executa o jogo. A cena principal já está configurada: `res://scenes/main.tscn`.
- **F6** executa a cena atualmente aberta no editor. Abra `scenes/main.tscn` se quiser testar só essa cena.

Resolução lógica: **1280 × 720**.

Opções de stretch (em Projeto → Display):

- `window/stretch/mode = canvas_items`: o conteúdo 2D é redimensionado com a janela, o que é adequado para um jogo 2D.
- `window/stretch/aspect = keep`: a proporção 16:9 é preservada. Se a janela tiver outro formato, aparecem faixas nas bordas em vez de distorcer a arena e a HUD.

Ainda **não** há preset de exportação Web nem templates testados. Não considere a versão de navegador pronta.

## Controles

| Ação | Teclas |
| --- | --- |
| Mover | **W A S D** ou **setas** |
| Reiniciar após o Game Over | **R** ou o botão **Reiniciar** |

As ações estão no **Input Map** do projeto: `move_left`, `move_right`, `move_up`, `move_down` e `restart`.

## Estrutura de pastas

```text
FiveSecondSurvival/
├── project.godot
├── README.md
├── scenes/
│   ├── main.tscn
│   ├── player/player.tscn
│   ├── enemies/bacteria.tscn
│   └── ui/hud.tscn
├── scripts/
│   ├── main.gd
│   ├── player/player.gd
│   ├── enemies/bacteria.gd
│   └── ui/hud.gd
└── assets/          (sprites, audio e fonts vazios por enquanto)
```

## Papel de cada cena e script

- **Main** (`scenes/main.tscn` + `scripts/main.gd`): cena raiz. Contém a arena (chão, paredes), instancia o jogador, uma bactéria e a HUD. Atualiza o cronômetro e recarrega a cena ao reiniciar.
- **Player** (`scenes/player/player.tscn` + `scripts/player/player.gd`): pizza provisória (`CharacterBody2D`). Lê o Input Map, move com `move_and_slide()`, tem vida e invulnerabilidade curta após o dano. A `Camera2D` segue o personagem e respeita os limites da arena.
- **Bacteria** (`scenes/enemies/bacteria.tscn` + `scripts/enemies/bacteria.gd`): inimigo verde que persegue o grupo `"player"`. Um `Area2D` (Hitbox) detecta o contato e aplica dano.
- **HUD** (`scenes/ui/hud.tscn` + `scripts/ui/hud.gd`): camada de interface (`CanvasLayer`) com vida, tempo e overlay de Game Over.

Personagens e chão são formas e cores desenhadas no próprio Godot (`_draw()` e `Polygon2D`). Não há sprites neste protótipo.

## Como a jogabilidade funciona

**Movimentação.** Em `_physics_process`, o jogador usa `Input.get_vector(...)` e multiplica pela velocidade. O movimento usa `delta` internamente via `move_and_slide()` no loop de física, então a velocidade em pixels por segundo não depende da taxa de quadros.

**Colisão.** Camadas 2D:

| Camada | Nome | Quem usa |
| --- | --- | --- |
| 1 | player | jogador |
| 2 | enemies | bactéria |
| 3 | world | paredes da arena |

O jogador colide com inimigos e paredes. A bactéria colide com o jogador e as paredes. A Hitbox da bactéria só “enxerga” a camada do jogador (não empurra, só detecta dano).

**Perseguição.** A cada frame de física a bactéria aponta para a posição global do jogador e caminha nessa direção.

**Vida e dano.** O jogador começa com 5 de vida. Enquanto a Hitbox sobrepõe o corpo do jogador, a bactéria tenta aplicar 1 de dano. Depois de um hit, o jogador fica cerca de 0,75 s invulnerável (fica semi-transparente) para não perder a vida inteira em um único encosto.

**Game Over.** Vida 0 emite o sinal `died`. A Main para o cronômetro, mostra a mensagem e permite reiniciar com `get_tree().reload_current_scene()`.

## O que já está implementado

- Projeto Godot 4.7 com renderer Compatibility
- Arena 2D limitada por paredes
- Jogador controlável (formas geométricas)
- Câmera que acompanha o jogador
- Uma bactéria que spawna na arena e persegue
- Vida, colisão, dano com i-frames
- HUD com vida e tempo de sobrevivência
- Game Over e reinício

## O que ainda falta (propositalmente)

Não entram nesta etapa: XP, níveis, escolha de upgrades, vários tipos de inimigo, chefes, ataques automáticos, outras comidas jogáveis, deterioração visual avançada, áudio, animações finais, nem integração/exportação CrazyGames.

## Testes e validação

O executável do editor Steam foi usado neste ambiente:

`D:\games steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe` — **Godot 4.7.2.stable**

Verificações realmente feitas:

1. Importação do projeto com `--import --headless` (classes globais `Player` e `HUD` registradas).
2. Execução da cena principal com `--headless --quit-after 60`. Código de saída **0**, sem `SCRIPT ERROR` no log. Isso confirma que a cena sobe; **não** substitui um teste jogável com teclado.

O jogo **não** foi controlado em uma janela visível neste ambiente. Depois de abrir no editor, confira manualmente:

1. F5 inicia `Main`.
2. WASD e setas movem a pizza.
3. A câmera segue o personagem e as paredes impedem sair da arena.
4. A bactéria verde se aproxima e causa dano (a HUD baixa a vida; há um intervalo sem dano extra).
5. Em vida 0 aparece Game Over; **R** ou o botão reinicia o tempo e a vida.

Se o Godot não abrir o projeto, use a mesma família **4.7.x Standard** (não é necessário o Godot .NET, a menos que você queira C#).
