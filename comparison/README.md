# Analysis of benchmark results

This folder contains several studies of the benchmark results.

## 1. Comparison of the energy management methods

Notebook [Comparison.ipynb](Comparison.ipynb)

Comparison of the different energy management methods implemented in the
[../methods](../methods) folder. This comparison is the core objective
of the solar home benchmark.

* Plots of trajetories on the first test days for each method:
  [Trajectory plots](Trajectory%20plots) folder

## 2. Sensitivity of benchmark results

Notebook [Benchmark_Sensitivity.ipynb](Benchmark_Sensitivity.ipynb)

### 2a. Solar home sizing

Sensitivity to the **sizing** of the solar home (battery capacity, PV power)

* This is where the sizing (4 kWp, 8 kWh) is determined
* Heatmap plots of the $(P_{PVp}, E_{rated})$ plane in the
[Sizing plots](Sizing%20plots) folder

![Animation of the total cost, function of P_PVp and E_rated, as the grid price increases](Sizing%20plots/total%20cost%20anim/Total_cost_map_anim.gif)

### 2b. Input variability

Sensitivity to the **variability** of the input data (load and sun power),
using the bootstrapped samples generated in the [data_variability_bootstrap.ipynb](../data/data_variability_bootstrap.ipynb) notebook.
