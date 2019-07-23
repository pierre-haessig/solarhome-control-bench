# TODOs for the solar home bench

July 2019

## Control

Consolidation of results:
* update the determistic optim Julia notebook to use the new `Benchutils` module
* investigate why optimized rule-based control gives a rather superior performance
  than SDP (from which is was inspired): control discretization step too big?

New:
* finish the draft MPC Julia notebook (after updating determistic optim Julia first)
* create a Stochastic MPC Julia notebook
* evaluate performance uncertainty with bootstrapped inputs

## Comparison
* update the Comparison Python notebook to latest `benchutils` functions

## Sizing

New sizing criterion: minimize grid energy cost **+ subscription cost**?
(because reducing subcription cost is one justification the use a battery)