function [phi_pi, phi_y] = policy_map_default(k_hat, params, cfg)
%POLICY_MAP_DEFAULT Map k_hat to Taylor rule coefficients (Eq. 10).

[phi_pi, phi_y] = policy_coefficients(k_hat, params, cfg);

end
