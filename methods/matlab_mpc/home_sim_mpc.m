function [stats,traj] = home_sim_mpc(dat,horiz,anticip_var)
%**************************************************************************
%% HOME_SIM_MPC Simulate the solar home with MPC control
%
%   Inputs: 
%            dat: Data structure, from load_data;
%            horiz : Prediction Horizon in hours 
%            anticip_var : Set this variable to 1 in order to use the  real
%            data or 0 to use the mean data for the prediction
%   Outputs: stats and trajectories, as struct
% 
%
% Author Jesse - James PRINCE A. || May 2018 
%  ************************************************************************

dt = dat.t(2) - dat.t(1);
E_rated = dat.E_rated;
P_pvp = dat.P_pvp;
P_load = dat.P_load_sp;
P_sun = P_pvp * dat.P_sun_1k;
c_grid = dat.c_grid;

horiz = horiz*2; %opt horizon in hour
nb_days = length(P_load)/48; %nb_days = 30; %nb of day of simulation
nb_hr = 48*nb_days; % Simulation time in 2*hour 
P_shed = zeros(1,nb_hr);
P_grid_max = 3; %kw
P_grid_min = 0; %kw
val_bound = 10e2; % bound limit

% Consumption pattern
cons_dmean = dat.cons_dmean;

% Production pattern
prod_dmean = dat.prod_dmean;

% Loop P_sun  and P_load on themselves in order to simulate full 30 days
% with horizon = 48 hours
P_sun = [P_sun;P_sun];
P_load =[P_load;P_load];

% If nbr of input <3 set the first input to 0 its default value.
if nargin < 3
    anticip_var = 0;
end

% By default use the mean data, unless the user choose otherwise by giving 1 as
% third input of the function
if (anticip_var == 0)
    P_sun_fcst = repmat(prod_dmean,nb_days+1,1);
    P_load_fcst = repmat(cons_dmean,nb_days+1,1);
elseif (anticip_var == 1)
    P_sun_fcst = P_sun;
    P_load_fcst = P_load;
else
   %throw an error message,choose which data to use for the prediction horizon
   % 0 for the average datas and 1 for the 
end


%Battery energy
E_sto_min = 0;
E_sto_max = E_rated;
E_sto(1,1) = E_sto_max/2; %half full charge starting

% Set Equality (left hand) constraints
Aeq = kron(eye(horiz),[1 -1 -1]);

% Set Inequality (left hand)constraints
Aineq_Pcurt_p = kron(eye(horiz),[0 0 1]);
Aineq_Pcurt_n = -Aineq_Pcurt_p;
Aineq_Psto_p = kron(tril(ones(horiz)),[0 dt 0]);
Aineq_Psto_n = -Aineq_Psto_p;
Aineq = Help_consAorBineq(horiz,Aineq_Pcurt_p,Aineq_Pcurt_n,Aineq_Psto_p,Aineq_Psto_n);

% Set Inequality (right hand) constraint
Bineq2 = zeros(horiz,1);

%repeat c_grid
c_grid = [c_grid;c_grid];

% Linprog calling options;
options = optimoptions('linprog');
options.Display = 'off';
%%

for i=1:nb_hr
    
    varr = c_grid(i:i+horiz-1);
    flin = Help_consAorBineq(horiz,ones(horiz,1).*varr,zeros(horiz,1),...
        zeros(horiz,1))';
    
    % Set data that will be used in the optimisation
    P_load_hor = P_load_fcst(i:i+horiz-1,:);
    P_sun_hor = P_sun_fcst(i:i+horiz-1,:);
    
    % Replace the first element of the  frcst data by the actual real data
    % at the current time.
    P_load_hor(1,1) = P_load(i,1);
    P_sun_hor(1,1) = P_sun(i,1);
    
    Bineq1 = P_sun_hor;
    
    %Set Inequality (right hand) constraints
    Bineq3 = (E_sto_max - E_sto(i,1))*ones(horiz,1);
    Bineq4 = (-E_sto_min + E_sto(i,1))*ones(horiz,1);
    Bineq(:,i) = Help_consAorBineq(horiz,Bineq1,Bineq2,Bineq3,Bineq4);
    
    % Set equality (right hand side) constraints
    Beq(:,i) = P_load_hor - P_sun_hor;
    
    % Set lower and upper bound constraints
    lb = repmat([P_grid_min;-val_bound;-val_bound],[horiz,1]);
    ub = repmat([P_grid_max;val_bound;val_bound],[horiz,1]);
    
    % Resolve optimisation problem and store result
    [U(:,i),~,flg(i)] = linprog(flin,Aineq,Bineq(:,i),Aeq,Beq(:,i),lb,ub,options);
    
    P_grid(i)= U(1,i);
    P_sto(i) = U(2,i);
    P_curt(i) =U(3,i);
    E_sto(i+1,1)= E_sto(i,1) + P_sto(i)*dt;
end
%%
P_pv = P_sun(1:nb_hr)' - P_curt;
C_grid = P_grid.*c_grid(1:nb_hr)'*dt;

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
traj.E_sto  = E_sto(1:end-1); % state
traj.P_sto  = P_sto'; % out

%traj.P_load_sp = P_load; % in
traj.P_shed = P_shed'; % out
traj.P_load = P_load(1:nb_hr); % out

%traj.P_sun  = P_sun; % in
traj.P_curt = P_curt'; % out
traj.P_pv   = P_pv'; % out
traj.P_grid = P_grid'; % out

