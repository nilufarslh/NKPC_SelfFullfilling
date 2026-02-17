function [phi_pi, phi_y, info] = policy_coefficients(k_hat, params, cfg)
%POLICY_COEFFICIENTS Compute policy coefficients from Equation (10).

if isfield(cfg.policy, 'use_unconditional_variances') && cfg.policy.use_unconditional_variances
    Vd = uncond_var(params.sigma_d, params.rho_d);
    Vv = uncond_var(params.sigma_v, params.rho_v);
    Vy = uncond_var(params.sigma_my, params.rho_my);
    Vpi = uncond_var(params.sigma_mpi, params.rho_mpi);
else
    Vd = params.sigma_d^2;
    Vv = params.sigma_v^2;
    Vy = params.sigma_my^2;
    Vpi = params.sigma_mpi^2;
end

% Guard against zero variances
eps_d = 1e-10;
Vd = max(Vd, eps_d);
Vv = max(Vv, eps_d);
Vy = max(Vy, eps_d);
Vpi = max(Vpi, eps_d);

% phi_y = gamma * Vd / Vy
phi_y = params.gamma * Vd / Vy;

% phi_pi(k_hat) from the i.i.d. "simple case"
lam = params.lambda_y;

inner = lam * Vv + (lam + k_hat^2) * Vpi;
inner = adjust_denom(inner, eps_d);

term = params.gamma * Vd / inner;

den = Vv + k_hat * (lam + k_hat^2) * term;
den = adjust_denom(den, eps_d);

phi_pi = (params.kappa * params.gamma * k_hat * (1 + Vd / Vy)) / den;

% Optional bounds to avoid explosive coefficients
if isfield(cfg.policy, 'phi_min')
    phi_pi = max(phi_pi, cfg.policy.phi_min);
    phi_y = max(phi_y, cfg.policy.phi_min);
end
if isfield(cfg.policy, 'phi_max')
    phi_pi = min(phi_pi, cfg.policy.phi_max);
    phi_y = min(phi_y, cfg.policy.phi_max);
end

info = struct('Vd', Vd, 'Vv', Vv, 'Vy', Vy, 'Vpi', Vpi, ...
    'inner', inner, 'den', den);

end

function d = adjust_denom(d, eps_d)
if abs(d) < eps_d
    d = sign(d + eps_d) * eps_d;
end
end

function v = uncond_var(sigma, rho)
rho = max(min(rho, 0.9999), -0.9999);
v = (sigma^2) / (1 - rho^2);
end
