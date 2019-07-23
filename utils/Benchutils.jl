"""
    Benchutils

Utilities for the solar home testbench

Features:
* load solar home testbench data: `load_data`
* compute/display statistics of a simulation: `compute_stats`, `pprint_stats`
* save simulation results: `save_results`
* plot simulation trajectories: `plot_traj`

Not implemented yet: `load_results`

Pierre Haessig — July 2019
"""
module  Benchutils

using Printf
using Statistics
using PyPlot
import DelimitedFiles


Base.@kwdef struct SHParams{T<:Real}
    E_rated::T
    P_pvp::T
    P_grid_max::T
end

Base.show(io::IO, p::SHParams) = print(io, "SHParams{", typeof(p.E_rated), "}",
    "(E_rated=", p.E_rated,
    ", P_pvp=", p.P_pvp,
    ", P_grid_max=", p.P_grid_max, ")"
)


"""
    load_data(ndays=30, subset="test", keep_date=false)

Load input data for the solar home testbench

# Arguments

ndays : int, optional
    nb of days to load. default: 30
subset : string, optional
    select the data extract to load: "test" for the test set,
    "train" for the training set.
keep_dat : bool, optional
    keeps the actual date as the index of the pandas DataFrame
    instead of using a numerical time index in hours (default).

# Returns

params : dict of parameters, with keys
    E_rated:    storage capacity (kWh)
    P_pvp:      size of PV panels (kWp)
    P_grid_max: subscribed grid power (kW)
data : dict of time series arrays, with keys
    t:         time (hours)
    P_load_sp: house load set point (kW)
    P_sun_1k:  solar production potential of a 1kWp panel (kW/kWp)
    c_grid:    grid energy price (€/kWh)
"""
function load_data(;ndays=30, subset="test", keep_date=false)
    # Testbench parameters
    params = SHParams(E_rated=8., P_pvp=4., P_grid_max=3.)

    # Load data file
    cdir = dirname(pathof(@__MODULE__))
    p_dat1112 = joinpath(cdir, "..", "data", "data_2011-2012.csv")
    @assert isfile(p_dat1112) "data file $p_dat1112 not found!"

    d, header = DelimitedFiles.readdlm(p_dat1112, ',', header=true)
    # split the datetime column (strings)
    date = d[:,1]
    d = d[:,2:end]
    # Cast data to Float64
    d = Array{Float64}(d)

    if subset == "train"
        # start of training period: 2011-10-29
        i1 = 5762 -1 # Line 5762: 2011-10-29 00:00:00,0.39,0.0
        if ndays > 31
            @warn "ndays > 31 makes training period overlap with test period!" ndays
        end
    elseif subset == "test"
         # start of test period: 2011-11-29
        i1 = 7250 -1 # Line 7250: 2011-11-29 00:00:00,0.52,0.0
    else
        error("`subset` should be either \"test\" of \"train\"")
    end

    # slice ndays starting from i1
    i2 = i1 + ndays*48 - 1
    d = d[i1:i2, :]
    date = date[i1:i2]

    print("loading $subset data (", date[1]," to ", date[end], ")")

    # time vector
    n = size(d)[1]
    @assert n == ndays*48 "length of data file is not ndays*48"

    dt = 0.5  # hours
    t = collect(range(0,length=n)*dt)  # hours

    # grid energy price
    #  0.10 €/kWh during night: h in [0,6[
    #  0.20 €/kWh during day: h in [6, 24[
    h = t .% 24  # in [0, 24[
    night = h .< 6
    day = .~night
    c_grid = 0.10*night + 0.20*day

    if keep_date
        t = date
    end

    data = Dict(
        "t" => t,
        "P_load_sp" => d[:,1],
        "P_sun_1k" => d[:,2]/1.04,
        "c_grid" => c_grid,
    )

    return params, data
end

"""
    save_results(name, params, data, stats, traj)

Save solar home simulation results for later reload with `load_results`

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
function save_results(name, params, data, stats, traj)
    if ~isdir("results")
        mkdir("results")
    end
    meta_fname = joinpath("results", "$(name)_meta.csv")
    stat_fname = joinpath("results", "$(name)_stat.csv")
    traj_fname = joinpath("results", "$(name)_traj.csv")

    f = open(meta_fname, "w")
    println(f, "control method,E_rated,P_pvp,P_grid_max")
    @printf(f, "%s,%.3f,%.3f,%.3f", name, params.E_rated, params.P_pvp, params.P_grid_max)
    close(f)

    f = open(stat_fname, "w")
    stat_order = [
        "P_sto",
        "P_load_sp","P_shed","P_load", # load
        "P_sun","P_curt","P_pv", # sun
        "P_grid","C_grid"]
    stat_header = join(stat_order, ",")
    println(f, stat_header)

    stat_mat = [stats[k] for k in stat_order]
    almost_0 = abs.(stat_mat) .<= 1e-13
    stat_mat[almost_0] .= 0.
    DelimitedFiles.writedlm(f, stat_mat', ',')
    close(f)

    f = open(traj_fname, "w")
    traj_header = "t,E_sto,P_sto,P_load_sp,P_shed,P_load,P_sun,P_curt,P_pv,P_grid,c_grid"
    println(f, traj_header)

    traj_mat = hcat(
        data["t"],
        traj["E_sto"], traj["P_sto"], # storage
        traj["P_load_sp"], traj["P_shed"], traj["P_load"], # load
        traj["P_sun"], traj["P_curt"], traj["P_pv"], # sun
        traj["P_grid"], traj["c_grid"] # grid
    )
    DelimitedFiles.writedlm(f, traj_mat, ',')
    close(f)

    println("result files for method \"$(name)\" written!")
    return nothing
end


"""
    compute_stats(traj)

Computes performance statistics on trajectories in `traj`

# Arguments

traj : Dict
    time series (trajectories) of all solarhome simulation variables

# Returns

stats: Dict
"""
function compute_stats(traj)
    s = Dict(
        "P_sto"     => mean(traj["P_sto"])*24,
        "P_load_sp" => mean(traj["P_load_sp"])*24,
        "P_shed"    => mean(traj["P_shed"])*24,
        "P_load"    => mean(traj["P_load"])*24,
        "P_sun"     => mean(traj["P_sun"])*24,
        "P_curt"    => mean(traj["P_curt"])*24,
        "P_pv"      => mean(traj["P_pv"])*24,
        "P_grid"    => mean(traj["P_grid"])*24,
        "C_grid"    => mean(traj["P_grid"] .* traj["c_grid"])*24,
    )
    return s
end

"""
    pprint_stats(stats)

Pretty prints simulations statistics

# Arguments
stats: Dict
    output of `traj_stats`

Note: the case P_shed != 0 is not implemented
"""
function pprint_stats(stats)
    @printf("P_load:    %5.2f kWh/d\n\n", stats["P_load"])
    @printf("P_sun:     %5.2f kWh/d (data)\n", stats["P_sun"])
    @printf("P_curt:    %5.2f kWh/d\n", stats["P_curt"])
    @printf("P_pv:      %5.2f kWh/d\n\n", stats["P_pv"])
    @printf("P_sto:     %5.2f kWh/d\n\n", stats["P_sto"])
    @printf("P_grid:    %5.2f kWh/d\n", stats["P_grid"])
    @printf("C_grid:    %.3f €/d\n", stats["C_grid"])

    return nothing
end


"""
    plot_traj(traj, E_rated; show_P_sto=false)

Plots time trajectory of the solar home variables

The figure is composed of two vertically stack subplots
1. power flows, shown with 'compact' variables:
  * net load (load - sun potential)
  * grid - solar curtailment
  * periods of low electricity price are highlighted in light blue
2. Energy stored in the battery

# Arguments

traj : Dict
    time series (trajectories) of all solarhome simulation variables
E_rated : float
    Rated capacity of the energy storage (kWh)

# Returns

fig : Matplotlib's Figure
ax : array of AxesSubplot objects
"""
function plot_traj(traj, E_rated; show_P_sto=false)
    fig, ax = plt.subplots(2, 1, figsize=(6, 3.5), sharex=true)

    P_nl = traj["P_load_sp"] - traj["P_sun"]
    P_gc = traj["P_grid"] - traj["P_curt"]

    dt = 0.5  # hours
    n = length(P_nl)
    t = range(0,length=n)*dt
    td = t/24

    ax[1].plot(td, P_nl, label="load − sun",
               color=(0.5, 0.5, 0.5))
    if show_P_sto
        ax[1].plot(td, -traj["P_sto"], label="sto (gen)",
                   color="tab:green", ls="-")
    end
    ax[1].plot(td, P_gc, label="grid − curt",
               color="tab:red")


    # highlight positive and negative areas
    ax[1].fill_between(td, P_gc, where=P_gc .>= 0,
                       color="tab:red", alpha=0.25, lw=0)
    ax[1].fill_between(td, P_gc, where=P_gc .<= 0,
                       color=(1, 1, 0), alpha=0.25, lw=0)

    # highlight low price periods
    c_low = traj["c_grid"] .< 0.15
    y1, y2 = ax[1].get_ylim()
    ax[1].fill_between(td, y1, y2, where=c_low,
                       color=(0.9, 0.9, 0.9), lw=0, zorder=-10)

    ax[1].legend(ncol=4)
    ax[1].set(
        ylabel="Power (kW)",
        ylim=(y1, y2)
    )
    ax[1].grid(true)

    ax[2].plot(td, traj["E_sto"], label="\$E_{sto}\$",
               color="tab:green")
    ax[2].axhline(0, color="tab:green", lw=0.5)
    ax[2].axhline(E_rated, color="tab:green", lw=0.5)

    # highlight low price periods
    y1, y2 = -0.05*E_rated, 1.05*E_rated
    ax[2].fill_between(td, y1, y2, where=c_low,
                       color=(0.9, 0.9, 0.9), lw=0, zorder=-10)

    ax[2].legend()
    ax[2].set(
        xlim=(td[1], td[end-1]),
        xlabel="time (days)",
        ylabel="Energy (kWh)",
        ylim=(y1, y2)
    )
    ax[2].grid(true)

    fig.tight_layout()
    return fig, ax
end

end  # module Benchutils
