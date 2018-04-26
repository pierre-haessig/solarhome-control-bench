function [t,P_load_sp,P_sun] = load_data(P_pvp)
%LOAD_DATA load input data for the solar home testbench
%   times series have a time step of 0.5
%   Input: 
%      P_pvp: size of PV panels in (kW_peak)
%   
%   Outputs (column vectors):
%     time vector t (hours),
%     house load set point P_load_sp (kW)
%     solar production potential P_sun (kW)

% test data: 30 days (+extras)
% select only the 7 test days:
R1 = 7250  -1;       % Line 7250: 2011-11-29 00:00:00,0.52,0.0
R2 = R1 + 30*48 - 1; % Line 8689: 2011-12-28 23:30:00,0.35,0.0

data = csvread('../../data/data_2011-2012.csv', R1, 1, [R1 1 R2 2]);

P_load_sp = data(:,1);
P_sun = data(:,2)/1.04 * P_pvp;

n = length(P_sun); 
assert(n==48*30);

t = (0:(n-1))'*0.5;% in hours
end

