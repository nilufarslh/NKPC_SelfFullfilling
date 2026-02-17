function [y, pi] = reduced_form_default(k_hat, e_t, params, cfg)
%REDUCED_FORM_DEFAULT Reduced form mapping (Eq. 11, row-by-row form).
%   e_t = [d_t; v_t; m_t^y; m_t^pi]

if numel(e_t) < 4
    error('Expected 4 shocks in e_t: [d, v, m_y, m_pi].');
end

[phi_pi, phi_y] = policy_coefficients(k_hat, params, cfg);

% Theta(k_hat)
Theta = (1 - params.kappa * params.theta_r * phi_pi) * (params.gamma + phi_y) + ...
    phi_pi * params.kappa * (params.theta_y + params.theta_r * phi_y);

Theta = adjust_denom(Theta, 1e-10);

d = e_t(1);
v = e_t(2);
my = e_t(3);
mpi = e_t(4);

% y_t
y = (1 / Theta) * ( ...
    params.gamma * (1 - params.kappa * params.theta_r * phi_pi) * d - ...
    phi_pi * v - ...
    phi_y * my - ...
    phi_pi * mpi );

% pi_t
pi = (1 / Theta) * ( ...
    params.gamma * params.kappa * (params.theta_y + params.theta_r * phi_y) * d + ...
    (params.gamma + phi_y) * v + ...
    phi_y * params.kappa * (params.gamma * params.theta_r - params.theta_y) * my + ...
    phi_pi * params.kappa * (params.gamma * params.theta_r - params.theta_y) * mpi );

end

function d = adjust_denom(d, eps_d)
if abs(d) < eps_d
    d = sign(d + eps_d) * eps_d;
end
end
