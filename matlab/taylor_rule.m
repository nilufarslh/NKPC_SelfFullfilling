function r = taylor_rule(pi, y, e_t, phi_pi, phi_y, params, cfg)
%TAYLOR_RULE Taylor rule with measurement/policy-noise terms.
%   r_t = phi_pi,t * (pi_t + m_t^pi) + phi_y,t * (y_t + m_t^y)

my = 0.0;
mpi = 0.0;
if isfield(cfg, 'policy') && isfield(cfg.policy, 'm_y_index')
    idx = cfg.policy.m_y_index;
    if idx >= 1 && idx <= numel(e_t)
        my = e_t(idx);
    end
end
if isfield(cfg, 'policy') && isfield(cfg.policy, 'm_pi_index')
    idx = cfg.policy.m_pi_index;
    if idx >= 1 && idx <= numel(e_t)
        mpi = e_t(idx);
    end
end

r = phi_pi * (pi + mpi) + phi_y * (y + my);

% Extra policy shock
if isfield(cfg, 'policy') && isfield(cfg.policy, 'shock_index')
    idx = cfg.policy.shock_index;
    if idx >= 1 && idx <= numel(e_t)
        r = r + e_t(idx);
    end
end

end
