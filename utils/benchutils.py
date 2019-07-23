#!/usr/bin/python3
# -*- coding: utf-8 -*-
""" Utilities for the solar home testbench

Features:
* load solar home testbench data: `load_data`
* compute/display statistics of a simulation: `compute_stats`, `pprint_stats`
* save/reload simulation results: `load_results`, `save_results`
* plot simulation trajectories: `plot_traj`

Pierre Haessig — July 2019
"""

import numpy as np
import pandas as pd
from warnings import warn
from pathlib import Path


def load_data(ndays=30, subset='test', keep_date=False):
    '''Load input data for the solar home testbench

    Parameters
    ----------
    ndays : int, optional
        nb of days to load. default: 30
    subset : string, optional
        select the data extract to load: 'test' for the test set,
        'train' for the training set.
    keep_dat : bool, optional
        keeps the actual date as the index of the pandas DataFrame
        instead of using a numerical time index in hours (default).

    Returns
    -------
    params : dict of parameters, with keys
        E_rated:    storage capacity (kWh)
        P_pvp:      size of PV panels (kWp)
        P_grid_max: subscribed grid power (kW)
    data : pandas DataFrame of time series data, with columns
        P_load_sp: house load set point (kW)
        P_sun_1k:  solar production potential of a 1kWp panel (kW/kWp)
        c_grid:    grid energy price (€/kWh)
        and the index is the time in hours
    '''
    # Testbench parameters
    params = dict(
        E_rated = 8.,  # kWh
        P_pvp = 4.,  # kW
        P_grid_max = 3. # kW
    )

    # Load data file
    p_dat1112 = Path(__file__).parent.parent / 'data' / 'data_2011-2012.csv'
    assert p_dat1112.exists(), 'data file {} not found!'.format(p_dat1112)
    df = pd.read_csv(p_dat1112,
                     index_col=0,
                     parse_dates=True)

    if subset == 'train':
        day1 = '2011-10-29'  # start of training period
        if ndays > 31:
            warn('ndays > 31 makes training period overlap with test period!')
    elif subset == 'test':  # test period
        day1 = '2011-11-29'  # start of test period
    else:
        raise ValueError("`subset` should be either 'test' of 'train'")

    # slice ndays starting from day1
    df = df[day1:]
    df = df.iloc[:ndays*48, :]

    # time vector
    n = len(df)
    assert n == ndays*48

    dt = 0.5  # hours
    t = np.arange(n)*dt  # hours

    # grid energy price
    #  0.10 €/kWh during night: h in [0,6[
    #  0.20 €/kWh during day: h in [6, 24[
    h = t % 24  # in [0, 24[
    night = h < 6
    day = ~night
    c_grid = 0.10*night + 0.20*day

    if keep_date:
        t = df.index

    data = pd.DataFrame.from_dict({
        't': t,
        'P_load_sp': df.GC.values,
        'P_sun_1k': df.GG.values/1.04,
        'c_grid': c_grid,
    })
    data.set_index('t', inplace=True)
    data.index.name = None

    return params, data


def load_results(folder, name):
    """load solarhome simulation results in `folder` with method `name`

    Returns
    -------
    meta : dict
        metadata of the results: method name, parameters
    stats : pandas Series
        statistics over the results (energy kWh/day, cost €/day)
    traj : pandas DataFrame
        time series (trajectories) of all output variables
    """
    folder = Path(folder)
    meta_fname = folder / f'{name}_meta.csv'
    stat_fname = folder / f'{name}_stat.csv'
    traj_fname = folder / f'{name}_traj.csv'

    # Metadata
    assert meta_fname.exists(), 'metadata file {} not found!'.format(meta_fname)
    c = pd.read_csv(meta_fname)
    assert len(c) == 1
    meta = c.iloc[0].to_dict()
    # meta.name = None

    # Statistics:
    assert stat_fname.exists(), 'statistics file {} not found!'.format(stat_fname)
    c = pd.read_csv(stat_fname)
    assert len(c) == 1
    stats = c.iloc[0]  # .to_dict()
    stats.name = None

    # Time series (trajectories)
    assert traj_fname.exists(), 'statistics file {} not found!'.format(traj_fname)
    traj = pd.read_csv(traj_fname, index_col=0)

    return meta, stats, traj


def save_results(name, params, stats, traj):
    """Save solar home simulation results for later reload with `load_results`

    Three CSV files are stored in `results` directory:
    * `name`_meta.csv: metadata
    * `name`_stat.csv: performance statistics
    * `name`_traj.csv: trajectories

    Parameters
    ----------
    name : str
        name of the control method. used as base name for saved files
    stats : dict or pandas Series
        statistics over the results (energy kWh/day, cost €/day)
    traj : pandas DataFrame
        time series (trajectories) of all output variables
    """
    import csv

    folder = Path('results')
    if not folder.is_dir():
        folder.mkdir()

    meta_fname = folder / f'{name}_meta.csv'
    stat_fname = folder / f'{name}_stat.csv'
    traj_fname = folder / f'{name}_traj.csv'

    # 1. Write metadata
    with open(meta_fname, 'w') as f:
        f.write('control method,E_rated,P_pvp,P_grid_max\n')
        f.write('{},{:.3f},{:.3f},{:.3f}\n'.format(
                name, params['E_rated'], params['P_pvp'], params['P_grid_max']))

    # 2. Write statistics
    with open(stat_fname, 'w', newline='\n') as f:
        fcsv = csv.writer(f, delimiter=',')
        stat_header = [
            'P_sto',
            'P_load_sp', 'P_shed', 'P_load',  # load
            'P_sun', 'P_curt', 'P_pv',  # sun
            'P_grid', 'C_grid'  # grid
        ]
        fcsv.writerow(stat_header)

        stat_mat = np.array([stats[k] for k in stat_header])
        # round almost zero values
        np.where(np.abs(stat_mat) <= 1e-13, 0, stat_mat)
        fcsv.writerow(stat_mat)

    # 3. Write trajectories
    with open(traj_fname, 'w') as f:
        traj_header = [
            't',
            'E_sto', 'P_sto',  # storage
            'P_load_sp', 'P_shed', 'P_load',  # load
            'P_sun', 'P_curt', 'P_pv',  # sun
            'P_grid', 'c_grid'  # grid
        ]
        # Check columns of `traj` DataFrame
        for h1, h2 in zip(traj_header[1:], traj):
            assert h1 == h2, '{} != {}'.format(h1, h2)
        traj.to_csv(f, sep=',', header=True, index=True)

    print('result files for method \'{}\' written!'.format(name))


def compute_stats(traj):
    """Computes performance statistics on trajectories in `traj`

    Parameters
    ----------
    traj : pandas DataFrame
        time series (trajectories) of all solarhome simulation variables

    Returns
    -------
    stats: dict
    """
    s = {
        'P_sto'    : np.mean(traj['P_sto'])*24,
        'P_load_sp': np.mean(traj['P_load_sp'])*24,
        'P_shed'   : np.mean(traj['P_shed'])*24,
        'P_load'   : np.mean(traj['P_load'])*24,
        'P_sun'    : np.mean(traj['P_sun'])*24,
        'P_curt'   : np.mean(traj['P_curt'])*24,
        'P_pv'     : np.mean(traj['P_pv'])*24,
        'P_grid'   : np.mean(traj['P_grid'])*24,
        'C_grid'   : np.mean(traj['P_grid'] * traj['c_grid'])*24,
    }
    return s


def pprint_stats(stats):
    """Pretty prints simulations statistics

    Parameters
    ----------
    stats: dict
        output of `traj_stats`

    Note: if P_shed is zero, then P_shed and P_load_sp are not displayed
    """
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

    P_sto:     {P_sto:5.2f} kWh/d

    P_grid:    {P_grid:5.2f} kWh/d
    C_grid:    {C_grid:.3f} €/d
    ''')
    s = s.format(**stats)

    print(s)


def plot_traj(traj, E_rated, show_P_sto=False):
    """plot time trajectory of the solar home variables

    The figure is composed of two vertically stack subplots
    1. power flows, shown with 'compact' variables:
      * net load (load - sun potential)
      * grid - solar curtailment
      * periods of low electricity price are highlighted in light blue
    2. Energy stored in the battery

    Parameters
    ----------
    traj : pandas DataFrame
        time series (trajectories) of all solarhome simulation variables
    E_rated : float
        Rated capacity of the energy storage (kWh)

    Returns
    -------
    fig : Matplotlib's Figure
    ax : array of AxesSubplot objects
    """
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(2, 1, figsize=(6, 3.5), sharex=True)

    P_nl = traj.P_load_sp - traj.P_sun
    P_gc = traj.P_grid-traj.P_curt

    dt = 0.5  # hours
    t = np.arange(len(P_nl))*dt
    td = t/24

    ax[0].plot(td, P_nl, label='load − sun',
               color=(0.5, 0.5, 0.5))
    if show_P_sto:
        ax[0].plot(td, -traj.P_sto, label='sto (gen)',
                   color='tab:green', ls='-')
    ax[0].plot(td, P_gc, label='grid − curt',
               color='tab:red')

    # highlight positive and negative areas
    ax[0].fill_between(td, P_gc, where=P_gc >= 0,
                       color='tab:red', alpha=0.25, lw=0)
    ax[0].fill_between(td, P_gc, where=P_gc <= 0,
                       color=(1, 1, 0), alpha=0.25, lw=0)

    # highlight low price periods
    c_low = traj.c_grid < 0.15
    y1, y2 = ax[0].get_ylim()
    ax[0].fill_between(td, y1, y2, where=c_low,
                       color=(0.9, 0.9, 0.9), lw=0, zorder=-10)

    ax[0].legend(ncol=4)
    ax[0].set(
        ylabel='Power (kW)',
        ylim=(y1, y2)
    )
    ax[0].grid(True)

    ax[1].plot(td, traj.E_sto, label='$E_{sto}$',
               color='tab:green')
    ax[1].axhline(0, color='tab:green', lw=0.5)
    ax[1].axhline(E_rated, color='tab:green', lw=0.5)

    # highlight low price periods
    y1, y2 = -.05*E_rated, 1.05*E_rated
    ax[1].fill_between(td, y1, y2, where=c_low,
                       color=(0.9, 0.9, 0.9), lw=0, zorder=-10)

    ax[1].legend()
    ax[1].set(
        xlim=(td[0], td[-1]),
        xlabel='time (days)',
        ylabel='Energy (kWh)',
        ylim=(y1, y2)
    )
    ax[1].grid(True)

    fig.tight_layout()
    return fig, ax
