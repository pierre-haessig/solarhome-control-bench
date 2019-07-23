% HOWTO load solar home testbench data in Matlab (tested with R2017b)
% Pierre Haessig, January 2018
% TODO 2019-07: clarify the status of this script agains the one utils
% (which do not include the plot) → remove it?

%% Main data file

% select only the 7 test days:
r_first = 7250; % 2011-11-29 00:00:00,0.52,0.0
r_last = 7585; % 2011-12-05 23:30:00,0.424,0.0
data = csvread('../data_2011-2012.csv', r_first-1, 1, [r_first-1 1 r_last-1 2]);

P_load_sp = data(:,1);
P_sun = data(:,2);

clearvars r_first r_last data;
n = length(P_sun); % should be 336

t = (0:(n-1))*0.5;% in hours
t = t/24; % in days

% Quick plot
figure 
subplot(211)
plot(t, P_load_sp)
ylabel('P_{load}* (kW)')
grid on
title('Test week 2011-11-29')

subplot(212)
plot(t, P_sun, 'Color', [0.85 0.325 0.098])
grid on
ylabel('P_{sun} (kW)')
xlabel('time (days)')

%% Daily pattern file
% contains in particular the mean for each hour of the day,
% which can be useful in MPC

% Consumption pattern
cons_dpat = csvread('../daily_pattern_cons_M-1-2011-11-28.csv', 1);

hod = cons_dpat(:,1);
cons_dmean = cons_dpat(:,2);
cons_dmin = cons_dpat(:,3);
cons_dmax = cons_dpat(:,end);
cons_dq = cons_dpat(:,4:end-1); % 19 quantiles, from 5% to 95 %

% Production pattern
prod_dpat = csvread('../daily_pattern_prod_M-1-2011-11-28.csv', 1);

prod_dmean = prod_dpat(:,2);
prod_dmin = prod_dpat(:,3);
prod_dmax = prod_dpat(:,end);
prod_dq = prod_dpat(:,4:end-1); % 19 quantiles, from 5% to 95 %

% Plot the daily pattern
figure
subplot(211)
plot(hod, cons_dmean, 'LineWidth', 3)
hold on
plot(hod, cons_dmin, 'LineWidth', 2)
plot(hod, cons_dmax, 'LineWidth', 2)
plot(hod, cons_dq, 'Color',  [0.7 0.7 0.7])

xlim([0 24])
ylim([0 3])
legend('mean', 'min', 'max', 'quantiles', 'Location', 'northwest')
ylabel('P_{load}* (kW)')
title('Daily pattern the month before 2011-11-28')

subplot(212)
plot(hod, prod_dmean, 'LineWidth', 3)
hold on
plot(hod, prod_dmin, 'LineWidth', 2)
plot(hod, prod_dmax, 'LineWidth', 2)
plot(hod, prod_dq, 'Color',  [0.7 0.7 0.7])

xlim([0 24])
legend('mean', 'min', 'max', 'quantiles', 'Location', 'northwest')
ylabel('P_{sun} (kW)')
xlabel('time (days)')
