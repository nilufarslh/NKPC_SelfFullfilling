function [m, sim] = moments_from_theta(theta, cfg)
%MOMENTS_FROM_THETA Simulate model and compute moments.

sim = simulate_model(theta, cfg);
[m, ~] = moments_data(sim.X, cfg);

end
