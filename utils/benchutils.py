#!/usr/bin/python3
# -*- coding: utf-8 -*-
""" Utilities for the solarhome testbench

Load and data files:

* test data inputs: `load_data`
* simulation results: `load_results`, `save_results`

Misc:

* pretty print simulatio statistics: s`pprint_stats`

Pierre Haessig — May 2017
"""

import numpy as np
import pandas as pd
#import matplotlib.pyplot as plt

from pathlib import Path


def load_data(ndays=30, test=True):
    '''Load input data for the solar home testbench
    
    Parameters
    ----------
    ndays : int, optional
        nb of days to load. default: 30
    test : bool, optional
        True to load test data. False to load training data
    
    Returns
    -------
    params : dict of parameters, with keys
        E_rated:   storage capacity (kWh)
        P_pvp:     size of PV panels (kWp)
    data : pandas DataFrame of time series data, with columns
        P_load_sp: house load set point (kW)
        P_sun_1k:  solar production potential of a 1kWp panel (kW/kWp)
        c_grid:    grid energy price (€/kWh)
        and the index is the time in hours
    '''
    # Testbench parameters
    params = dict(
        E_rated = 8, # kWh
        P_pvp = 4, # kW
    )
    
    # Load data file
    p_dat1112 = Path(__file__).parent.parent / 'data' / 'data_2011-2012.csv'
    assert p_dat1112.exists(), 'data file {} not found!'.format(p_dat1112)
    df = pd.read_csv(p_dat1112,
        index_col=0,
        parse_dates=True)
    
    # Slice test data: ndays starting at 2011-11-29
    df = df['2011-11-29':] # start of test period
    df = df.iloc[:ndays*48, :]
    
    # time vector
    n = len(df)
    assert n==ndays*48
    
    dt = 0.5 # hours
    t = np.arange(n)*dt # hours
    
    # grid energy price
    #  0.10 €/kWh during night: h in [0,6[
    #  0.20 €/kWh during day: h in [6, 24[
    h = t % 24 # in [0, 24[
    night = h < 6
    day = ~night
    c_grid = 0.10*night + 0.20*day
    
    data = pd.DataFrame.from_items([
        ('t', t),
        ('P_load_sp', df.GC.values),
        ('P_sun_1k', df.GG.values/1.04),
        ('c_grid', c_grid),
    ])
    data.set_index('t', inplace=True)
    data.index.name = None
    
    return params, data


def load_results(folder, name):
    '''load solarhome simulation results in `folder` with method `name`
    
    Returns
    -------
    meta : dict
        metadata of the results: method name, parameters
    stats : pandas Series
        statistics over the results (energy kWh/day, cost €/day)
    traj : pandas DataFrame
        time series (trajectories) of all output variables
    '''
    folder = Path(folder)
    meta_fname = folder / f'{name}_meta.csv'
    stat_fname = folder / f'{name}_stat.csv'
    traj_fname = folder / f'{name}_traj.csv'
    
    # Metadata
    assert meta_fname.exists(), 'metadata file {} not found!'.format(meta_fname)
    c = pd.read_csv(meta_fname)
    assert len(c) == 1
    meta = c.iloc[0].to_dict()
    #meta.name = None
    
    # Statistics:
    assert stat_fname.exists(), 'statistics file {} not found!'.format(stat_fname)
    c = pd.read_csv(stat_fname)
    assert len(c) == 1
    stats = c.iloc[0]#.to_dict()
    stats.name = None
    
    # Time series (trajectories)
    assert traj_fname.exists(), 'statistics file {} not found!'.format(traj_fname)
    traj = pd.read_csv(traj_fname, index_col=0)
    
    return meta, stats, traj


def pprint_stats(stats):
    '''pretty print simulations stats
    
    NB : if P_shed is zero, then P_shed and P_load_sp are not displayed
    '''
    from textwrap import dedent
    if stats['P_shed'] > 0:
        s = dedent('''\
        P_load_sp: {P_load_sp:5.2f} kWh/d (data)
        P_shed:    {P_shed:5.2f} kWh/d
        ''')
    else:
        s = ''
    
    s += dedent('''\
    P_load:    {P_load:5.2f} kWh/d
    
    P_sun:     {P_sun:5.2f} kWh/d (data)
    P_curt:    {P_curt:5.2f} kWh/d
    P_pv:      {P_pv:5.2f} kWh/d
    
    P_sto:     {P_sto:5.2} kWh/d
    
    P_grid:    {P_grid:5.2f} kWh/d
    C_grid:    {C_grid:.3f} €/d
    ''')
    s = s.format(**stats)
    
    print(s)
