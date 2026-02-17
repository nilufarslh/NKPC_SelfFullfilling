function cfg = config()
%CONFIG Configuration for SMM estimation with learning NK model.
%   Adjust values in this file to match your model and data choices.

cfg = struct();

% ----------------------------
% Sample and data settings
% ----------------------------
cfg.sample.frequency = 'quarterly';
cfg.sample.annualize = true;       % if data are quarterly rates in log points
cfg.sample.demean = true;          % demean series if model has zero means
cfg.sample.moment_lag = 1;         % lag L for autocorr/cov moments
cfg.sample.burn_in = 200;          % burn-in for simulation
cfg.sample.T = [];                 % if empty, use data length

% Data file (set in main.m; this is a placeholder relative path)
cfg.data.path = fullfile('data', 'targets.csv');

% ----------------------------
% Moment selection
% ----------------------------
% Options: 'var1' | 'var1_plus_scale' | 'var1_xy_var_r'
cfg.moments.option = 'var1_xy_var_r';

% VAR(1) moments configuration (used only if option = 'var1')
cfg.moments.var1.drop_idx = [14 15];  % drop two entries to keep 13 moments

% Extra direct moments when option = 'var1_xy_var_r'
cfg.moments.include_cov_pi_y = true;
cfg.moments.acf_lag = 12;

% ----------------------------
% Weighting matrix
% ----------------------------
% Start with identity; you can replace with optimal W later.
cfg.weighting.W = [];  % if empty, set to identity at runtime

% ----------------------------
% Parameter partition
% ----------------------------
% Fixed (calibrated) parameters
cfg.params.fixed = struct();
cfg.params.fixed.beta = 0.99;
cfg.params.fixed.gamma = 1.00;
cfg.params.fixed.lambda_y = 0.50;
cfg.params.fixed.theta_y = 1.00;
cfg.params.fixed.rho_my = 0.00;
cfg.params.fixed.rho_mpi = 0.00;

% Estimated parameters (edit to match your model)
cfg.params.estimated.names = {
    'kappa', 'theta_r', ...
    'rho_d', 'rho_v', ...
    'sigma_d', 'sigma_v', 'sigma_my', 'sigma_mpi'
};

cfg.params.estimated.theta0 = [
    0.10; 0.50; ...
    0.80; 0.80; ...
    0.50; 0.50; 0.25; 0.25
];

cfg.params.estimated.lb = [
    0.01; 0.00; ...
    0.00; 0.00; ...
    0.01; 0.01; 0.01; 0.01
];

cfg.params.estimated.ub = [
    1.00; 2.00; ...
    0.99; 0.99; ...
    8.00; 8.00; 5.00; 8.00
];

% ----------------------------
% Policy rule and learning
% ----------------------------
% Intervention switch: true = phi uses current k_hat; false = fixed phi.
cfg.policy.intervention = true;

% Policy mapping and expectations
cfg.policy.map = @policy_map_default;
cfg.expectations.rule = @expectation_default;
cfg.policy.use_unconditional_variances = true;
cfg.policy.phi_min = 0.10;
cfg.policy.phi_max = 5.00;
cfg.policy.m_y_index = 3;
cfg.policy.m_pi_index = 4;

cfg.learning.use = true;
cfg.learning.constant_gain = true;   % false -> decreasing gain 1/t
cfg.learning.gain = 0.05;
cfg.learning.k0 = 0.00;              % fixed in baseline (not estimated)
cfg.learning.R0 = 1.00;
cfg.learning.k_bounds = [-5.0, 5.0];

% ----------------------------
% Reduced form mapping
% ----------------------------
% Uses the row-by-row formulas from Equation (11).
cfg.reduced_form.fn = @reduced_form_default;

% ----------------------------
% Shock specification
% ----------------------------
% Order: d_t, v_t, m_t^y, m_t^pi
cfg.shocks.names = {'d', 'v', 'm_y', 'm_pi'};

% Persistence and std dev are in theta by default; placeholders here
cfg.shocks.rho_names = {'rho_d', 'rho_v', 'rho_my', 'rho_mpi'};
cfg.shocks.sigma_names = {'sigma_d', 'sigma_v', 'sigma_my', 'sigma_mpi'};

% ----------------------------
% Simulation settings
% ----------------------------
% Common random numbers for a smooth objective
cfg.sim.fix_rng = true;
cfg.sim.rng_seed = 123;

% ----------------------------
% Optimization settings
% ----------------------------
cfg.optim.display = 'iter';

% Penalty weight if bounds are enforced without fmincon
cfg.optim.bound_penalty = 1e4;

% ----------------------------
% Standard errors
% ----------------------------
% Set cfg.se.method = 'none' | 'bootstrap' | 'sandwich'
cfg.se.method = 'none';
cfg.se.bootstrap_reps = 50;

end
