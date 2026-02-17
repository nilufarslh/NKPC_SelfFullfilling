function [theta_hat, fval, exitflag, output] = estimate_smm(cfg, m_data, theta0, lb, ub)
%ESTIMATE_SMM Run numerical optimization for SMM.

obj = @(theta) objective_smm(theta, cfg, m_data);

has_fmincon = license('test', 'Optimization_Toolbox') && exist('fmincon', 'file') == 2;

if has_fmincon
    opts = optimoptions('fmincon', 'Display', cfg.optim.display, ...
        'Algorithm', 'interior-point', 'MaxIterations', 2000, ...
        'MaxFunctionEvaluations', 1e5);
    [theta_hat, fval, exitflag, output] = fmincon(obj, theta0, [], [], [], [], lb, ub, [], opts);
else
    warning('Optimization Toolbox not available. Using fminsearch with bounds penalty.');
    penalty = @(theta) bound_penalty(theta, lb, ub, cfg.optim.bound_penalty);
    obj_pen = @(theta) obj(theta) + penalty(theta);
    opts = optimset('Display', cfg.optim.display, 'MaxIter', 2000, 'MaxFunEvals', 1e5);
    [theta_hat, fval, exitflag, output] = fminsearch(obj_pen, theta0, opts);
end

end

function p = bound_penalty(theta, lb, ub, weight)
viol_low = max(lb - theta, 0);
viol_high = max(theta - ub, 0);
p = weight * sum(viol_low.^2 + viol_high.^2);
end
