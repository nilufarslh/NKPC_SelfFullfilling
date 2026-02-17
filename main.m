% MAIN  Run SMM estimation with learning NK simulation

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'matlab'));

cfg = config();

% Resolve paths relative to project root
cfg.project_root = root;
if ~isfile(cfg.data.path)
    cfg.data.path = fullfile(root, cfg.data.path);
end

% Step 1: Build data series (targets)
[data, data_info] = load_data(cfg);
if isempty(cfg.sample.T)
    cfg.sample.T = data_info.T;
end

% Step 2: Choose moments to match
[data_moments, moment_names] = moments_data(data.X, cfg);

% Step 3: Define parameter partition
[theta0, lb, ub, param_names] = pack_params(cfg);

% Weighting matrix
if isempty(cfg.weighting.W)
    cfg.weighting.W = eye(numel(data_moments));
end

% Step 4-6: Estimate via SMM
[theta_hat, fval, exitflag, output] = estimate_smm(cfg, data_moments, theta0, lb, ub);

% Step 5: Simulated moments at theta_hat
[sim_moments, sim_info] = moments_from_theta(theta_hat, cfg);

% Moment-fit report (table + plots)
report = moment_report(data_moments, sim_moments, moment_names, cfg, data.X, sim_info.X, cfg.weighting.W);

% Step 7: Standard errors (optional)
se = standard_errors(theta_hat, cfg, data_moments);

% Save results
results = struct();
results.theta_hat = theta_hat;
results.param_names = param_names;
results.fval = fval;
results.exitflag = exitflag;
results.output = output;
results.data_moments = data_moments;
results.sim_moments = sim_moments;
results.moment_names = moment_names;
results.sim_info = sim_info;
results.data_info = data_info;
results.se = se;
results.moment_report = report;

save(fullfile(root, 'results', 'smm_results.mat'), 'results');

% Report
fprintf('\nSMM finished. Objective value: %.6f\n', fval);
for i = 1:numel(param_names)
    if i <= numel(theta_hat)
        fprintf('%-12s = %9.4f\n', param_names{i}, theta_hat(i));
    end
end
