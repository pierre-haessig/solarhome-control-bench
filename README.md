# Solar home control bench

This repository contains an open testbench for control and optimization methods for the energy management of a simple solar home.

Pierre Haessig, IETR (AUTomatic Control team), CentraleSupélec

## Solar home model

![solar home power flow model](images/solar_home.png)

## Control methods

This repository contains several examples for the energy management of the solar home,
with a different method or in a different language (Python, Julia, Matlab).

Each method lives in dedicated subdirectory of the [methods](methods) folder.
It includes:
* Rule-based control (Julia, Matlab and Python)
* Model Predictive Control (MPC)
* Stochastic Dynamic Programming
* …

## Comparison of control methods

In the [comparison](comparison) folder.

## Solar and load data

Solar production (from PV panels) and home consumption data is taken from the
[Solar home electricity dataset](http://www.ausgrid.com.au/Common/About-us/Corporate-information/Data-to-share/Solar-home-electricity-data.aspx)
by Ausgrid (distribution grid operator in the region near Sydney).

A dataset extract used for this testbench is placed in the [data](data) subfolder.
A description of this data extract is provided in [data/README.md](data/README.md). In particular, the 30 days starting at 2011-11-29 should be used for final testing:

![2011-11-29 week plot](data/data_week_2011-11-29.png)

In addition the dedicated [ausgrid-solar-data](https://github.com/pierre-haessig/ausgrid-solar-data)
repository contains much Python code to analyze the entire Ausgrid dataset. However, it should not be needed for this benchmark.
