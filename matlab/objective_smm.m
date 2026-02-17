function Q = objective_smm(theta, cfg, m_data)
%OBJECTIVE_SMM SMM objective function.

penalty = 1e12;
try
    if isfield(cfg, 'sim') && isfield(cfg.sim, 'fix_rng') && cfg.sim.fix_rng
        rng_state = rng;
        rng(cfg.sim.rng_seed, 'twister');
        [m_sim, ~] = moments_from_theta(theta, cfg);
        rng(rng_state);
    else
        [m_sim, ~] = moments_from_theta(theta, cfg);
    end
catch
    Q = penalty;
    return;
end

if any(~isfinite(m_sim))
    Q = penalty;
    return;
end

if numel(m_sim) ~= numel(m_data)
    error('Moment vector length mismatch (sim vs data).');
end

W = cfg.weighting.W;
diff = m_sim - m_data;
Q = diff' * W * diff;

end
