function [stats,traj] = home_sim_rb(dat)
%HOME_SIM_RB Simulate the solar home with rule-based control
%   Input: input data structure, from load_data
%   Outputs: stats and trajectories, as struct

% extract input data and parameters:
dt = dat.t(2) - dat.t(1);
E_rated = dat.E_rated;
P_pvp = dat.P_pvp;
P_load = dat.P_load_sp;
P_sun = P_pvp * dat.P_sun_1k;
c_grid = dat.c_grid;

n = length(P_load);
P_sto = zeros(n,1);
E_sto = zeros(n+1,1);
P_grid = zeros(n,1);
P_curt = zeros(n,1);
P_shed = zeros(n,1);

E_sto(1)= E_rated/2;

function [P_sto_k, P_grid_k, P_curt_k] = control_rb(P_load_k, P_sun_k, E_sto_k)
    P_nl_k = P_load_k - P_sun_k;
    % control outputs:
    P_sto_k = 0; %#ok<NASGU>
    P_grid_k = 0;
    P_curt_k = 0;

    E_next = E_sto_k - P_nl_k*dt;

    if P_nl_k>0 % (load > sun)
        if E_next<0
            E_next = 0;
        end %if storage underflow
        P_sto_k = (E_next - E_sto_k)/dt; % <0
        P_grid_k = P_nl_k + P_sto_k;
    else
        if  E_next>E_rated
            E_next = E_rated;
        end % if storage overflow
        P_sto_k = (E_next - E_sto_k)/dt; % >0
        P_curt_k = -P_nl_k - P_sto_k;
    end % if
end % control function

for k=1:n
    [P_sto_k, P_grid_k, P_curt_k] = control_rb(P_load(k), P_sun(k), E_sto(k));
    P_sto(k) = P_sto_k;
    P_grid(k) = P_grid_k;
    P_curt(k) = P_curt_k;
    E_sto(k+1) = E_sto(k) + P_sto(k)*dt;
end

% extra outputs
E_sto = E_sto(1:end-1);
P_pv = P_sun - P_curt;
C_grid = P_grid .* c_grid * dt;


% output stats: cumulated energy in kWh/day
% (and cost in €/day)
stats.P_sto   = mean(P_sto)*24;
stats.P_load_sp = mean(P_load)*24;
stats.P_shed = mean(P_shed)*24;
stats.P_load = mean(P_load)*24;
stats.P_sun  = mean(P_sun)*24;
stats.P_curt = mean(P_curt)*24;
stats.P_pv   = mean(P_pv)*24;
stats.P_grid = mean(P_grid)*24;
stats.C_grid = mean(C_grid)*24;

% trajectories of all output variables
traj.E_sto  = E_sto; % state
traj.P_sto  = P_sto; % out

%traj.P_load_sp = P_load; % in
traj.P_shed = P_shed; % out
traj.P_load = P_load; % out

%traj.P_sun  = P_sun; % in
traj.P_curt = P_curt; % out
traj.P_pv   = P_pv; % out

traj.P_grid = P_grid; % out

end