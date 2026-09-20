# Omarchy RPN Calculator

Uma calculadora RPN local para o Omarchy Shell, operável principalmente pelo
teclado e acessível por um widget na barra.

O painel combina uma pilha ilimitada, entrada numérica direta e uma grade de
funções navegável. A interface visível é em inglês e pode seguir o tema do
Omarchy ou usar um modo clássico inspirado no aspecto de uma HP 48GX.

Consulte [SPEC.md](SPEC.md) para o comportamento do MVP, os atalhos e a
proposta visual.

## Princípios

- entrada RPN rápida, sem exigir cliques;
- pilha numerada como nas calculadoras HP 48;
- erros não destroem operandos;
- nenhum uso de `eval` para calcular expressões;
- funcionamento inteiramente local;
- visual clássico opcional, sem copiar marca, logotipo ou assets da HP.

## Instalação

Requer o Omarchy Shell com suporte a plugins `bar-widget`, `Ui.KeyboardPanel`
e `updateEntryInline`. A integração foi desenvolvida contra o Omarchy
`4.0.0.alpha` e Quickshell `0.3.1` instalados nesta máquina.

Para instalar uma cópia local do repositório em um destino novo:

```bash
omarchy plugin validate .
mkdir -p ~/.config/omarchy/plugins/lpanebr.rpn-calc
cp manifest.json ~/.config/omarchy/plugins/lpanebr.rpn-calc/
cp -R plugin ~/.config/omarchy/plugins/lpanebr.rpn-calc/
omarchy-shell shell rescanPlugins
omarchy plugin enable lpanebr.rpn-calc
```

O widget aparece à direita da barra. Clique no ícone para abrir ou fechar.
O painel também pode ser aberto pelo IPC do Shell:

```bash
omarchy-shell shell summon lpanebr.rpn-calc '{}'
```

## Uso

- Digite `2 Enter 3 +` para obter `5`. `_` troca o sinal.
- `p`/`n` percorrem a pilha; `Enter` copia o nível selecionado para o topo.
- Durante a edição, esquerda/direita movem o cursor. Baixo/cima entram na
  grade de funções; as setas percorrem a grade com wrap e `Enter` executa.
- `Ctrl+c` copia o topo; `Ctrl+v` empilha um número do clipboard e preserva
  qualquer entrada em edição.
- `?` abre a ajuda. `Esc` dispensa ajuda, erro, seleção ou entrada antes de
  fechar o painel.
- O toggle no canto superior direito alterna entre `Omarchy` e `Classic` e
  salva a preferência nas configurações do Shell.

A pilha permanece em memória enquanto o widget existir. Fechar o painel não
a apaga; reiniciar o Shell ou recarregar o plugin pode apagá-la. Os cálculos
usam `Number` do JavaScript, com suas limitações de precisão binária.

## Desenvolvimento

O manifesto na raiz aponta para `plugin/BarWidget.qml`. O motor numérico
independe da interface e não usa `eval`, rede ou processos externos.

```bash
node --test tests/rpn-engine.test.cjs
bash tests/run-qml-tests.sh
bash tests/run-shell-smoke.sh
omarchy plugin validate .
```

Os testes QML usam Qt Quick Test 6 com um tema mínimo de teste. O smoke test
usa os componentes reais do Omarchy Shell em `/usr/share/omarchy/shell` e
uma instância separada do Quickshell na sessão Wayland; abre e fecha brevemente
o painel. Nenhum teste instala o plugin ou altera a configuração da barra.

Licença: GPL-2.0-or-later.
