function save_results(name, dat, stats, traj)
%SAVE_RESULTS Save results of the solar home simulation in files.
%
%   Results are saved in three CSV files:
%     metadata:     NAME_meta.csv
%     statistics:   NAME_stats.csv
%     trajectories: NAME_traj.csv
%
%   Inputs:
%     name:  name of the control method. basename for the files
%     dat:   benchmark data struct (from load_data)
%     stats: simulation statistics struct
%     traj:  trajectories of simulated variables
%
%   TODO: make traj optional

meta_fname = sprintf('results/%s_meta.csv', name);
stat_fname = sprintf('results/%s_stat.csv', name);
traj_fname = sprintf('results/%s_traj.csv', name);

% Metadata
f = fopen(meta_fname, 'w');
assert(f>=3, 'unable to create output file. check that "results" directory exists')
fprintf(f, 'control method,E_rated,P_pvp\n');
fprintf(f, '%s,%.6g,%.6g\n', name, dat.E_rated, dat.P_pvp);
fclose(f);

% Statistics
f = fopen(stat_fname, 'w');
assert(f>=3)
stat_header = 'P_sto,P_load_sp,P_shed,P_load,P_sun,P_curt,P_pv,P_grid,C_grid\n';
fprintf(f, stat_header);
fclose(f);

stat_mat = [stats.P_sto... % storage
    stats.P_load_sp stats.P_shed stats.P_load... % load
    stats.P_sun stats.P_curt stats.P_pv... % sun
    stats.P_grid stats.C_grid]; % grid

dlmwrite(stat_fname, stat_mat, '-append', 'delimiter',',','precision','%.9g')

% Trajectories
f = fopen(traj_fname, 'w');
assert(f>=3)
traj_header = ',E_sto,P_sto,P_load_sp,P_shed,P_load,P_sun,P_curt,P_pv,P_grid,c_grid\n';
fprintf(f, traj_header);
fclose(f);

res = [dat.t...
      traj.E_sto traj.P_sto... % storage
      traj.P_load_sp traj.P_shed traj.P_load... % load
      traj.P_sun traj.P_curt traj.P_pv... % sun
      traj.P_grid dat.c_grid]; % grid

almost_0 = abs(res)<1e-15;
res(almost_0) = 0;
dlmwrite(traj_fname, res, '-append', 'delimiter',',','precision','%.9g')

fprintf('result files for method "%s" written!\n', name)
end