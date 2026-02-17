function se = standard_errors(theta_hat, cfg, m_data)
%STANDARD_ERRORS Compute standard errors (optional).

switch lower(cfg.se.method)
    case 'none'
        se = [];
        return;
    case 'bootstrap'
        se = bootstrap_se(theta_hat, cfg, m_data);
    case 'sandwich'
        se = sandwich_se(theta_hat, cfg);
    otherwise
        error('Unknown se.method: %s', cfg.se.method);
end

end

function se = bootstrap_se(theta_hat, cfg, m_data)
% Parametric bootstrap: resample shocks, re-estimate.
B = cfg.se.bootstrap_reps;
if B <= 0
    se = [];
    return;
end

[theta0, lb, ub] = pack_params(cfg);

theta_boot = zeros(numel(theta_hat), B);
for b = 1:B
    % Re-run estimation with different random seed
    rng(b);
    [theta_b, ~] = estimate_smm(cfg, m_data, theta0, lb, ub);
    theta_boot(:, b) = theta_b;
end

se = std(theta_boot, 0, 2);
end

function se = sandwich_se(theta_hat, cfg)
% SMM sandwich estimator: V = (D'WD)^-1 D'WSWD (D'WD)^-1

% Jacobian of moments
h = 1e-4;
[m0, ~] = moments_from_theta(theta_hat, cfg);
D = zeros(numel(m0), numel(theta_hat));
for i = 1:numel(theta_hat)
    th_hi = theta_hat; th_lo = theta_hat;
    th_hi(i) = th_hi(i) + h;
    th_lo(i) = th_lo(i) - h;
    m_hi = moments_from_theta(th_hi, cfg);
    m_lo = moments_from_theta(th_lo, cfg);
    D(:, i) = (m_hi - m_lo) / (2 * h);
end

% Estimate moment covariance via block bootstrap of data
[data, ~] = load_data(cfg);
X = data.X;
S = moment_cov_block_bootstrap(X, cfg);

W = cfg.weighting.W;
G = D' * W * D;
V = G \ (D' * W * S * W * D) / G;

se = sqrt(diag(V));
end

function S = moment_cov_block_bootstrap(X, cfg)
B = max(cfg.se.bootstrap_reps, 50);
T = size(X, 1);
block_len = 8;

m = moments_data(X, cfg);
M = zeros(numel(m), B);

for b = 1:B
    Xb = block_bootstrap(X, block_len, T);
    M(:, b) = moments_data(Xb, cfg);
end

S = cov(M');
end

function Xb = block_bootstrap(X, block_len, T)
% Simple moving block bootstrap
n = size(X, 2);
Xb = zeros(T, n);
idx = 1;
while idx <= T
    start = randi([1, T - block_len + 1]);
    block = X(start:start+block_len-1, :);
    take = min(block_len, T - idx + 1);
    Xb(idx:idx+take-1, :) = block(1:take, :);
    idx = idx + take;
end
end
