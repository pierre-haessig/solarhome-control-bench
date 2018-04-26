% Simulation of the solar home using a simple rule-based control.
% Pierre Haessig, April 2018

%% Load test data: P_load, P_sun

dat = load_data();
t = dat.t;
td = t/24; % hours -> days

% plot a small extract:
plot(td(1:48*3), dat.P_load_sp(1:48*3), td(1:48*3), dat.P_sun_1k(1:48*3)*dat.P_pvp)
title('Extract of load and sun power (kW)')

%% Simulate solar home

[stats,traj] = home_sim_rb(dat);

disp(stats)

%% Plot trajectory extract

d1 = 0; % start plot day
d2 = 7; % end plot day

subplot(211)
P_nl = dat.P_load_sp - dat.P_sun; % net load
plot(td(d1*48+1:d2*48), P_nl(d1*48+1:d2*48))
hold on
plot(td(d1*48+1:d2*48), traj.P_curt(d1*48+1:d2*48))
plot(td(d1*48+1:d2*48), traj.P_grid(d1*48+1:d2*48))

legend('net load', 'curt', 'grid', 'Orientation','horizontal')
ylabel('kW')
title('rule-based control of solar home')

subplot(212)
plot(td(d1*48+1:d2*48), traj.E_sto(d1*48+1:d2*48))

xlabel('time (days)')
ylabel('E_{sto} kWh')

%% Save results

name = 'rule-based'; % name of the control method
save_results(name,dat,stats,traj)