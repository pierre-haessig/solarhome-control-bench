function dat = load_data(varargin)
%LOAD_DATA load input data for the solar home testbench
%   DAT = LOAD_DATA() loads 30 days of test data
%
%   DAT = LOAD_DATA(NDAYS) loads NDAYS days of test data
%
%   DAT = LOAD_DATA(NDAYS, 'TRAIN') loads NDAYS days of training data
%   
%   Output: DAT struct with fields:
%     E_rated:   storage capacity (kWh)
%     P_pvp:     size of PV panels (kWp)
%     dt:        data time step (0.5 hours)
%     t:         relative time (column vector, hours)
%     P_load_sp: house load set point (column vector, kW)
%     P_sun_1k:  solar production potential of a 1kWp panel (column vector, kW/kWp)
%     c_grid:    grid energy price (column vector, €/kWh)

if nargin>=1
    ndays = varargin{1};
else
    ndays = 30;
end

% select between test data and training data
test_data = true;
if nargin>=2
    if strcmp(varargin{2}, 'TRAIN') || strcmp(varargin{2}, 'train')
        test_data = false;
    end
end

% Testbench parameters
dat.E_rated = 8; % storage capacity (kWh)
dat.P_pvp = 4; % size of PV panels (kWp)

% Slice data
if not(test_data)
    % training data, starting at 2011-10-30
    if ndays>30
        throw(MException('LOAD_DATA:TooManyDays','Cannot load more than 30 training days.'));
    end
    R1 = 5810 - 1;          % Line 5810: 2011-10-30 00:00:00,0.37,0.0
    R2 = R1 + ndays*48 - 1; % Line 7249: 2011-11-28 23:30:00,0.5,0.0 (for ndays=30)
else
    % test data, starting at 2011-11-29
    R1 = 7250 - 1;          % Line 7250: 2011-11-29 00:00:00,0.52,0.0
    R2 = R1 + ndays*48 - 1; % Line 8689: 2011-12-28 23:30:00,0.35,0.0 (for ndays=30)
end %if

% Load data file
root_folder = fileparts(fileparts(mfilename('fullpath')));
data_filename = fullfile(root_folder, 'data', 'data_2011-2012.csv');
data = csvread(data_filename, R1, 1, [R1 1 R2 2]);

% extract columns
dat.P_load_sp = data(:,1);
dat.P_sun_1k = data(:,2)/1.04;

% time vector
n = length(dat.P_sun_1k);
assert(n==ndays*48);

dat.dt = 0.5; % hours
dat.t = (0:(n-1))'*dat.dt; % in hours

% grid energy price
%  0.10 €/kWh during night: h in [0,6[
%  0.20 €/kWh during day: h in [6, 24[
h = mod(dat.t,24); % in [0, 24[
night = h < 6;
day = ~night;
dat.c_grid = 0.10*night + 0.20*day;

end