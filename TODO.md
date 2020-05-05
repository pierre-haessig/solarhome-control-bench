# TODOs for the solar home bench

July 2019

## Control

Consolidation of results:
* investigate why optimized rule-based control gives a rather superior performance
  than SDP (from which is was inspired): control discretization step too big?

New:
* create a Stochastic (tree-based) MPC Julia notebook
* evaluate performance uncertainty with bootstrapped inputs

## Comparison
* update the Comparison Python notebook to latest `benchutils` functions

## Sizing

New sizing criterion: minimize grid energy cost **+ subscription cost**?
(because reducing subcription cost is one justification the use a battery)
