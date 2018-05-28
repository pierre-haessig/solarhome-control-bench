% Simulation of the solar home using a simple rule-based control.
% Pierre Haessig, April 2018

path(path, '../../utils') % access to load_data and save_results

%% Load test data: P_load, P_sun

dat = load_data();
t = dat.t;
td = t/24; % hours -> days

% plot a small extract:
P_sun = dat.P_sun_1k*dat.P_pvp;
plot(td(1:48*3), dat.P_load_sp(1:48*3), td(1:48*3), P_sun(1:48*3))
legend('P_{load}*', 'P_{sun}')
title('Extract of load and sun power (kW)')

%% Simulate solar home

[stats,traj] = home_sim_rb(dat);

disp(stats)

%% Plot trajectory extract

d1 = 0; % start plot day
d2 = 5; % end plot day

subplot(211)
P_nl = dat.P_load_sp - P_sun; % net load
P_gc = traj.P_grid - traj.P_curt;
plot(td(d1*48+1:d2*48), P_nl(d1*48+1:d2*48))
hold on
plot(td(d1*48+1:d2*48), P_gc(d1*48+1:d2*48))

legend('net load', 'grid - curt', 'Orientation','horizontal')
ylabel('kW')
title('rule-based control of solar home')

subplot(212)
plot(td(d1*48+1:d2*48), traj.E_sto(d1*48+1:d2*48))

xlabel('time (days)')
ylabel('E_{sto} kWh')

%% Save results

name = 'rule-based'; % name of the control method
save_results(name,dat,stats,traj)