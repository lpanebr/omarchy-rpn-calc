# Omarchy RPN Calculator

Uma calculadora RPN local para o Omarchy Shell, operável principalmente pelo
teclado e acessível por um widget na barra.

O painel combina uma pilha ilimitada, entrada numérica direta e uma grade de
funções navegável. A interface visível é em inglês e pode seguir o tema do
Omarchy ou usar um modo clássico inspirado no aspecto de uma HP 48GX.

O projeto está na fase de especificação. Consulte [SPEC.md](SPEC.md) para o
comportamento do MVP, os atalhos e a proposta visual.

## Princípios

- entrada RPN rápida, sem exigir cliques;
- pilha numerada como nas calculadoras HP 48;
- erros não destroem operandos;
- nenhum uso de `eval` para calcular expressões;
- funcionamento inteiramente local;
- visual clássico opcional, sem copiar marca, logotipo ou assets da HP.

## Estado

Ainda não há implementação. O primeiro marco está descrito no issue inicial do
repositório.

Licença: GPL-2.0-or-later.

