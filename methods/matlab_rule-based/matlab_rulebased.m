% Simulation of the solar home using a simple rule-based control.
% Pierre Haessig, April 2018

% Testbench parameters
E_rated = 8; % Storage capacity (kWh)
P_pvp = 4; % PV panels size (kWp)

%% Load test data: P_load, P_sun

[t,P_load_sp,P_sun] = load_data(P_pvp);
dt = t(2) - t(1); % 0.5 hours
td = t/24; % hours -> days

% plot a small extract:
plot(td(1:48*3), P_load_sp(1:48*3), td(1:48*3), P_sun(1:48*3))

%% Simulate solar home




%% Write results

