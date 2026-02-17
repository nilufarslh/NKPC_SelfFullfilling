function [theta0, lb, ub, names] = pack_params(cfg)
%PACK_PARAMS Extract estimated parameter vector and bounds.

names = cfg.params.estimated.names(:);
theta0 = cfg.params.estimated.theta0(:);
lb = cfg.params.estimated.lb(:);
ub = cfg.params.estimated.ub(:);

if numel(theta0) ~= numel(names)
    error('theta0 length does not match number of estimated names.');
end
if numel(lb) ~= numel(names) || numel(ub) ~= numel(names)
    error('Bounds length does not match number of estimated names.');
end

end
