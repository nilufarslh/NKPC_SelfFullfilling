function sim = simulate_model(theta, cfg)
%SIMULATE_MODEL Simulate model given parameter vector.

params = unpack_params(theta, cfg);

T = cfg.sample.T;
burn_in = cfg.sample.burn_in;
TT = T + burn_in;

% Pre-allocate
pi_t = zeros(TT, 1);
y_t = zeros(TT, 1);
r_t = zeros(TT, 1);

k_hat = cfg.learning.k0;
R = cfg.learning.R0;

% Fixed policy if no intervention
if ~cfg.policy.intervention
    [phi_pi_fix, phi_y_fix] = cfg.policy.map(k_hat, params, cfg);
else
    phi_pi_fix = NaN; phi_y_fix = NaN; %#ok<NASGU>
end

% Shocks
E = simulate_shocks(TT, params, cfg);

for t = 1:TT
    % Clamp k_hat to avoid unstable policy coefficients
    if isfield(cfg.learning, 'k_bounds') && ~isempty(cfg.learning.k_bounds)
        k_hat = min(max(k_hat, cfg.learning.k_bounds(1)), cfg.learning.k_bounds(2));
    end

    e_t = E(t, :).';

    % 1. Policy step
    if cfg.policy.intervention
        [phi_pi, phi_y] = cfg.policy.map(k_hat, params, cfg);
    else
        phi_pi = phi_pi_fix; %#ok<*NASGU>
        phi_y = phi_y_fix;
    end

    % 2. Economy generates (y, pi) from reduced form
    [y_now, pi_now] = cfg.reduced_form.fn(k_hat, e_t, params, cfg);

    % 3. Taylor rule
    r_now = taylor_rule(pi_now, y_now, e_t, phi_pi, phi_y, params, cfg);

    % 4. Learning update
    if cfg.learning.use
        if cfg.learning.constant_gain
            gamma = cfg.learning.gain;
        else
            gamma = 1 / max(t, 1);
        end

        d_t = e_t(1); % convention: first shock is d_t

        pi_exp = cfg.expectations.rule(pi_t, t, cfg);
        denom = max(R, 1e-8);

        R = R + gamma * (d_t * y_now - R);
        k_hat = k_hat + gamma * (1 / denom) * d_t * (pi_now - params.beta * pi_exp - y_now * k_hat);
        if isfield(cfg.learning, 'k_bounds') && ~isempty(cfg.learning.k_bounds)
            k_hat = min(max(k_hat, cfg.learning.k_bounds(1)), cfg.learning.k_bounds(2));
        end
    end

    % Save
    y_t(t) = y_now;
    pi_t(t) = pi_now;
    r_t(t) = r_now;
end

% Drop burn-in
idx = (burn_in + 1):TT;

sim = struct();
sim.X = [pi_t(idx), y_t(idx), r_t(idx)];
sim.pi = pi_t(idx);
sim.y = y_t(idx);
sim.r = r_t(idx);

end
