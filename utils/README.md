# Utilities for Solar home control bench

Useful functions are provided to work with the solar home testbench,
in particular to load the test data, compute performance statistics,
save simulation results in common CSV file format…

Utilities are available in the following languages:

* Julia: [Benchutils.jl](Benchutils.jl) module
* Python: [benchutils.py](benchutils.py) module
* Matlab: functions are in dedicated files
  * [load_data.m](load_data.m)
    (remark: it should work with Octave by adjusting the call to `csvread`)
  * [save_results.m](save_results.m)

To learn how to use these utilities, look at an example [control methods](../methods)
with the language of your choice.
In particular, rule-based control examples (in Julia/Matlab/Python)
are the simplest to start with.
