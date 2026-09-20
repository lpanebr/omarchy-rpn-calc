# Especificação — Omarchy RPN Calculator

## Objetivo

Criar um plugin `bar-widget` para o Omarchy Shell que ofereça uma calculadora
RPN compacta, rápida pelo teclado e utilizável também pelo mouse. O MVP deve
priorizar quatro operações, navegação clara pela pilha, funções matemáticas
básicas e tratamento seguro de erros.

Todo texto mostrado ao usuário deve estar em inglês. A documentação do projeto
pode permanecer em português.

## Modelo RPN

A calculadora usa uma pilha ilimitada, numerada a partir do topo:

```text
4:                       10
3:                       25
2:                        2
1:                       3_
```

O nível `1` é o topo. O painel mostra inicialmente quatro níveis e permite
percorrer os demais. Valores ficam alinhados à direita; números dos níveis e
indicadores ficam à esquerda.

Operações binárias consomem os níveis `1` e `2` e colocam o resultado no nível
`1`. Operações unárias substituem apenas o nível `1`.

## Estados de interação

O painel possui quatro estados internos, sem uma troca explícita de foco pelo
usuário:

- **idle:** pilha visível e nenhuma entrada em andamento;
- **entry:** edição de um número;
- **stack browse:** um nível da pilha está selecionado;
- **function browse:** uma função da grade está selecionada.

O estado ativo deve ser evidente por cursor ou indicador, sem depender apenas
de cor.

## Entrada e operações

- `0`–`9` iniciam ou continuam a entrada numérica.
- `.` insere o separador decimal; a interface sempre usa ponto.
- `_` troca o sinal da entrada ou do nível `1` quando não há entrada.
- Durante a entrada, esquerda/direita movem o cursor; dígitos e ponto são
  inseridos na posição do cursor.
- `Backspace` apaga o caractere anterior ao cursor durante a entrada.
- `Enter` confirma a entrada e a coloca no nível `1`.
- `+`, `-`, `*` e `/` confirmam implicitamente uma entrada pendente e executam
  a operação em seguida.
- `Delete` executa `DROP` quando não há uma entrada em edição.
- `?` abre a ajuda de atalhos.
- `Ctrl+c` copia o valor do nível `1`; `Ctrl+v` cola um valor no nível `1`.
- `Esc` fecha a ajuda quando aberta; fora da ajuda, limpa primeiro uma mensagem
  de erro, se houver. Caso contrário, cancela a seleção ativa, cancela a entrada
  em edição ou, em idle, fecha o painel. Cada pressionamento trata uma camada.

Exemplo: se `2` já estiver na pilha, digitar `3 +` equivale a `3 Enter +` e
produz `5`.

`Backspace` não deve executar `DROP`. Quando não houver entrada, ele não altera
a pilha.

## Navegação pela pilha

- `p` ou `Ctrl+p` seleciona o topo e navega em direção aos níveis mais antigos;
- `n` ou `Ctrl+n` navega em direção ao nível `1`;
- a seleção provoca rolagem automática quando sair dos quatro níveis visíveis;
- `Enter` executa `PICK`: copia o valor selecionado para o novo nível `1`, sem
  remover o original;
- `Esc` cancela a navegação sem modificar a pilha;
- navegar durante uma entrada preserva seu buffer e cursor, sem confirmá-la;
  cancelar a navegação com `Esc` retoma essa edição;
- digitar um número cancela a navegação e inicia uma nova entrada.

Exemplo de `PICK`:

```text
4: 10
3: 25  <
2:  2
1:  3
```

Após `Enter`:

```text
5: 10
4: 25
3:  2
2:  3
1: 25
```

## Grade de funções

Durante a entrada, esquerda/direita movem o cursor e não entram na grade.
As setas para baixo e para cima entram na grade preservando a entrada pendente.
Os destinos iniciais são:

| Seta | Durante a entrada | Sem entrada em andamento |
| --- | --- | --- |
| Baixo | Primeira coluna, primeira linha (`sqrt`) | Primeira coluna, primeira linha (`sqrt`) |
| Cima | Primeira coluna, última linha (`/`) | Primeira coluna, última linha (`/`) |
| Esquerda | Move o cursor para a esquerda | Última coluna, primeira linha (`+/-`) |
| Direita | Move o cursor para a direita | Primeira coluna, primeira linha (`sqrt`) |

Dentro da grade:

- as quatro setas movem a seleção;
- a navegação faz wrap horizontal e vertical;
- `Enter` executa a função selecionada e volta à pilha;
- `Esc` cancela e retoma a entrada pendente, se houver, ou volta à pilha;
- clicar em uma função a executa diretamente.

Grade inicial proposta:

```text
sqrt   pow    1/x    +/-
arg    drop   swap   clear
```

Uma terceira linha apresenta, nesta ordem, as operações `/`, `*`, `-` e `+`.
Ela integra a navegação por setas e o wrap da grade, além de permitir uso pelo
mouse. Seus atalhos diretos permanecem disponíveis.
Os rótulos e tooltips devem ser em inglês. Símbolos como `√x` e `yˣ` podem ser
usados quando permanecerem legíveis na fonte ativa.

### Semântica das funções

- `sqrt`: substitui o nível `1` por sua raiz quadrada;
- `pow`: calcula nível `2` elevado ao nível `1`;
- `1/x`: substitui o nível `1` por seu inverso;
- `+/-`: troca o sinal da entrada pendente, sem confirmá-la, ou do nível `1`
  quando não há entrada, assim como `_`;
- `arg`: restaura na pilha os operandos da última operação matemática
  bem-sucedida, na ordem original, sem remover o resultado e sem substituir os
  argumentos memorizados. Por exemplo, `2 Enter 3 + ARG` produz `[5, 2, 3]`;
- `drop`: remove o nível `1`;
- `swap`: troca os níveis `1` e `2`;
- `clear`: esvazia a pilha após uma confirmação simples no próprio painel.

Executar uma função por teclado ou mouse confirma implicitamente a entrada
pendente antes de aplicar a função, exceto `+/-`, que atua na própria entrada.
Por exemplo, digitar `9` e executar `sqrt` produz `3`. Cancelar a confirmação
de `clear` preserva tanto a pilha quanto a entrada pendente.

## Erros

Uma operação com erro preserva os operandos na pilha. A confirmação implícita
de uma entrada válida ocorre antes da operação e não é desfeita se ela falhar:
com `2` na pilha, digitar `0 /` deixa `[2, 0]`, com `0` no nível `1` e sem
entrada pendente. Uma entrada inválida não é confirmada nem altera a pilha.
O painel reserva duas linhas acima do nível
`4`, seguindo a organização visual da HP 48:

```text
/ Error:
Infinite Result
4:                       10
3:                       25
2:                        2
1:                        0
```

O MVP deve tratar pelo menos:

- divisão por zero;
- inverso de zero;
- raiz de número negativo;
- operandos insuficientes;
- resultado não finito;
- entrada numérica inválida.

A mensagem permanece até a próxima ação válida ou `Esc`. Os textos concretos
devem ser curtos, em inglês, e testáveis.

## Precisão e formatação

O MVP usa `Number` do JavaScript. Cálculo decimal de precisão arbitrária fica
fora do escopo inicial.

- separador decimal sempre `.`;
- `NaN`, `Infinity` e `-Infinity` nunca entram na pilha;
- zeros finais desnecessários podem ser omitidos;
- números muito grandes ou pequenos podem usar notação científica;
- a largura do display determina truncamento visual, nunca truncamento do valor
  armazenado;
- alinhamento numérico sempre à direita.

## Ajuda

`?` abre uma camada de ajuda sobre o painel contendo:

- atalhos de entrada e operações;
- navegação pela pilha e comportamento de `PICK`;
- navegação com wrap pela grade;
- descrição breve das funções;
- indicação do modo visual ativo;
- atalhos de copiar e colar valores.

`Esc`, `?` ou clique fora fecha a ajuda e retorna ao estado anterior.

## Visual

O plugin oferece dois modos de aparência.

Um toggle retangular no canto superior direito do painel alterna entre
`Omarchy` e `Classic`. A preferência é persistida entre reinícios do Shell.

### Omarchy

Modo alternativo, usando cores, tipografia, espaçamento, bordas e componentes
do tema ativo do Omarchy Shell. Deve parecer parte nativa do sistema.

### Classic

Modo padrão inspirado na experiência visual da HP 48GX:

- corpo em grafite escuro;
- display LCD em verde acinzentado, com contraste moderado;
- números monoespaçados e alinhados à direita;
- teclas retangulares compactas, com relevo discreto;
- acentos azul/ciano e âmbar para hierarquia e seleção;
- borda e espaçamento que sugiram um dispositivo físico sem tentar reproduzi-lo
  fielmente.

O modo não deve usar logotipo, nome de modelo, layout completo de teclado,
texturas ou assets copiados da HP. Trata-se de uma referência estética, não de
uma reprodução. O nome do modo exibido na interface é `Classic`.

O widget da barra permanece integrado ao tema do Omarchy nos dois modos. A
preferência visual afeta apenas o painel da calculadora.

## Widget da barra

O widget usa um ícone simples e abre ou fecha o painel com clique esquerdo. O
tooltip deve ser `RPN Calculator`.

O MVP pode mostrar apenas o ícone. Mostrar o nível `1` na barra fica para uma
configuração futura, pois pode ocupar espaço e expor valores.

## Arquitetura proposta

```text
manifest.json
plugin/
  BarWidget.qml
  Panel.qml
  RpnEngine.js
tests/
```

- `RpnEngine.js` contém pilha, buffer de entrada, operações e erros;
- `Panel.qml` contém apresentação, teclado, mouse e modos visuais;
- `BarWidget.qml` integra o painel à barra;
- nenhuma operação usa `eval` ou executa comandos externos;
- pilha e entrada permanecem apenas em memória no MVP; a preferência visual é
  persistida.

A implementação deve confirmar o manifesto e os componentes disponíveis na
versão instalada do Omarchy. Arquivos sob `/usr/share/omarchy` servem somente
como referência e não devem ser modificados.

O manifesto fica na raiz do repositório, conforme o contrato do instalador
de plugins, e aponta para `plugin/BarWidget.qml`.

## Persistência e clipboard

Persistência da pilha não pertence ao MVP. Fechar apenas o painel preserva a
pilha durante a sessão do Omarchy Shell; reiniciar o Shell pode limpá-la.

Copiar e colar fazem parte do MVP:

- `Ctrl+c` copia o valor do nível `1`, sem truncamento visual, usando ponto
  decimal; não copia a entrada pendente nem o nível selecionado na navegação;
- `Ctrl+v` interpreta o texto do clipboard como um único número finito e o
  empilha como novo nível `1`, deslocando os anteriores; uma entrada em edição
  mantém seu buffer e cursor, sem ser confirmada ou substituída;
- texto inválido ou valor não finito produz erro sem alterar a pilha;
- a preferência visual é persistida independentemente da pilha.

## Critérios de aceite do MVP

- `2 Enter 3 Enter +` e `2 Enter 3 Enter + 4 Enter *` produzem os resultados
  esperados;
- `2 Enter 3 +` e `2 Enter 3 + 4 *` também funcionam com confirmação implícita;
- `_` troca o sinal sem conflitar com subtração;
- `p`/`n` e `Ctrl+p`/`Ctrl+n` percorrem uma pilha com mais de quatro níveis;
- `Enter` em stack browse executa `PICK` exatamente como especificado;
- esquerda/direita movem o cursor durante a entrada;
- as setas entram na grade nos destinos definidos e, dentro dela, a navegação
  faz wrap nos dois eixos;
- `Enter` executa a função selecionada e `Esc` volta à pilha;
- mouse executa funções sem exigir navegação pelo teclado;
- divisão por zero e operandos insuficientes preservam a pilha;
- `2 Enter 0 /` preserva `[2, 0]`, com o zero confirmado no nível `1`;
- navegar pela pilha durante a edição e cancelar retoma o buffer e o cursor;
- `9` seguido de `sqrt` produz `3`; `+/-` durante a edição não confirma a entrada;
- `2 Enter 3 + ARG` deixa `[5, 2, 3]` na pilha;
- os quatro botões `/`, `*`, `-` e `+` aparecem abaixo da grade e funcionam
  com o mouse;
- `Esc` limpa um erro antes de cancelar a entrada ou fechar o painel;
- `Ctrl+c` copia o nível `1` sem truncamento e `Ctrl+v` cola um número finito;
- valores aparecem alinhados à direita com ponto decimal;
- `?` apresenta todos os atalhos do MVP;
- os modos `Omarchy` e `Classic` são legíveis, `Classic` é o padrão e não usa assets
  ou marcas da HP;
- o toggle retangular no canto superior direito alterna a aparência e a escolha
  sobrevive ao reinício do Shell;
- abrir, usar e fechar o painel não gera erros QML nos logs do Omarchy Shell.

## Fora do escopo inicial

- precisão decimal arbitrária;
- números complexos;
- unidades e conversões;
- variáveis, fórmulas ou linguagem de programação;
- gráficos;
- histórico persistente;
- sincronização;
- reprodução completa de uma HP 48GX;
- execução de expressões por `eval`.

## Questões para depois do MVP

- persistir a pilha entre reinícios;
- histórico de operações e undo;
- funções trigonométricas e logarítmicas;
- formatos inteiro, hexadecimal e científico;
- memória nomeada;
- configuração da função inicialmente selecionada por cada seta.
