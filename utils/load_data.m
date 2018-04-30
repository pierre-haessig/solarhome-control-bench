function dat = load_data(varargin)
%LOAD_DATA load input data for the solar home testbench
%   DAT = LOAD_DATA() loads 30 days of test data
%
%   DAT = LOAD_DATA(NDAYS) loads NDAYS days of test data
%   
%   Output: DAT struct with fields:
%     E_rated:   storage capacity (kWh)
%     P_pvp:     size of PV panels (kWp)
%     t:         data time, with a step of 0.5 (column vector, hours)
%     P_load_sp: house load set point (column vector, kW)
%     P_sun_1k:  solar production potential of a 1kWp panel (column vector, kW/kWp)
%     c_grid:    grid energy price (column vector, €/kWh)

if nargin>=1
    ndays = varargin{1};
else
    ndays = 30;
end

% Testbench parameters
dat.E_rated = 8; % storage capacity (kWh)
dat.P_pvp = 4; % size of PV panels (kWp)

% slice test data, starting at 2011-11-29
R1 = 7250  -1;       % Line 7250: 2011-11-29 00:00:00,0.52,0.0
R2 = R1 + ndays*48 - 1; % Line 8689: 2011-12-28 23:30:00,0.35,0.0

data = csvread('../../data/data_2011-2012.csv', R1, 1, [R1 1 R2 2]);

dat.P_load_sp = data(:,1);
dat.P_sun_1k = data(:,2)/1.04;

% time vector
n = length(dat.P_sun_1k);
assert(n==ndays*48);

dt = 0.5; % hours
dat.t = (0:(n-1))'*dt; % in hours

% grid energy price
%  0.10 €/kWh during night: h in [0,6[
%  0.20 €/kWh during day: h in [6, 24[
h = mod(dat.t,24); % in [0, 24[
night = h < 6;
day = ~night;
dat.c_grid = 0.10*night + 0.20*day;

end
