# Estilos do app (temas) — como funciona

Versão: novembro/2026. Só o frontend (Flutter) mudou.

## O que a usuária vê

No **Início**, o botão de paleta (ícone 🎨, ao lado do atualizar) abre a lista de
estilos. Tocou num estilo, o app inteiro muda de cor na hora. A escolha fica salva
**no aparelho** (o PC e o celular podem ter estilos diferentes).

Estilos: **Rosé** (o original, idêntico ao de antes), **Lavanda**, **Oceano**,
**Esmeralda**, **Champanhe** e **Claro** (fundo branco).

Depois de trocar, o app volta para a tela Início (explicado abaixo).

## A ideia em 4 peças

```
app_palette.dart   →  "cardápio" de estilos (cada estilo = um conjunto de cores)
app_colors.dart    →  AppColors.rose, AppColors.card... devolvem a cor do estilo ATIVO
theme_provider.dart → guarda qual estilo está ativo e salva no aparelho
main.dart          →  quando o estilo muda, redesenha o app inteiro
```

### 1. Paleta (`lib/core/theme/app_palette.dart`)
Uma classe com todas as cores de um estilo. Os nomes são os mesmos que o app já
usava (`rose`, `lavender`, `card`...), então **as telas não precisaram ser
reescritas**. Leia `rose` como "cor principal" e `lavender` como "cor secundária".

### 2. AppColors virou "janela" para a paleta (`lib/core/constants/app_colors.dart`)
Antes: `static const Color rose = Color(0xFFE8527A);` — cor fixa.
Agora: `static Color get rose => _palette.rose;` — pergunta para a paleta ativa.

### 3. Por que tantos `const` sumiram
Em Dart, `const` é calculado **quando o app é compilado** e nunca muda. Uma cor
que depende da escolha da usuária só existe com o app rodando, então ela não pode
ficar dentro de um `const`. Exemplo:

```dart
// antes (não compila mais, porque AppColors.text não é constante)
const Text('Oi', style: TextStyle(color: AppColors.text))
// depois
Text('Oi', style: TextStyle(color: AppColors.text))
```

Foram 269 trocas desse tipo, feitas por script com um analisador de código
(tree-sitter) para não errar nenhuma, e conferidas depois: nenhum `const` ficou
prendendo cor. As regras de estilo `prefer_const_constructors` e
`prefer_const_literals_to_create_immutables` foram desligadas em
`analysis_options.yaml` para a análise não encher de avisos (é só sugestão de
desempenho, a diferença é mínima).

Cuidado parecido com `static final`: ele também é calculado **uma vez só**. Duas
listas de cores das Estatísticas viraram `get` para acompanhar o estilo.

### 4. Redesenhar o app (`lib/main.dart`)
O `MaterialApp` recebe `key: ValueKey(palette.id)`. Quando o estilo muda, a chave
muda e o Flutter monta o app de novo do zero, então toda tela relê as cores.
É simples e garante que nada fique com a cor antiga. O efeito colateral é voltar
para o Início; os dados (cache, login) não se perdem porque ficam fora do
MaterialApp (no ProviderScope).

## Como criar um estilo novo

1. Em `app_palette.dart`, copie um estilo (ex.: `oceanoPalette`), mude `id`
   (único, sem espaço), `name`, `description` e as cores.
2. Coloque o novo estilo na lista `AppPalette.all`.
3. Rode `flutter test`: o teste `test/theme_test.dart` confere se o texto fica
   legível (contraste) em todos os estilos novos.

Dica de contraste: o texto branco dos botões precisa de contraste ≥ 3 com a cor
principal; texto normal ≥ 4,5 com o fundo dos cartões. Cores muito claras
(amarelo, verde-limão, azul-céu) costumam reprovar como fundo de botão.

## Arquivos

| Arquivo | O que mudou |
| --- | --- |
| `lib/core/theme/app_palette.dart` | Novo: os 6 estilos |
| `lib/core/constants/app_colors.dart` | Cores viraram `get` da paleta ativa |
| `lib/core/theme/app_theme.dart` | `AppTheme.current`: tema do Material montado da paleta (claro/escuro) |
| `lib/providers/theme_provider.dart` | Novo: estilo ativo + salvar/carregar no aparelho |
| `lib/presentation/widgets/theme_picker_sheet.dart` | Novo: lista de estilos com miniatura |
| `lib/main.dart` | Observa o estilo e redesenha o app |
| `lib/presentation/screens/home/home_screen.dart` | Botão de paleta no Início |
| Telas e widgets | Só remoção de `const` onde havia cor |
| `analysis_options.yaml` | Desliga 2 avisos de "prefira const" |
| `test/theme_test.dart` | Novo: testes dos estilos, contraste e salvamento |
