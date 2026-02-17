function E = simulate_shocks(T, params, cfg)
%SIMULATE_SHOCKS Simulate AR(1) shocks.

n = numel(cfg.shocks.names);
E = zeros(T, n);

rho = zeros(n,1);
sigma = zeros(n,1);
for i = 1:n
    rho(i) = params.(cfg.shocks.rho_names{i});
    sigma(i) = params.(cfg.shocks.sigma_names{i});
end

for t = 2:T
    E(t,:) = (rho'.* E(t-1,:)) + (sigma'.* randn(1,n));
end

end
