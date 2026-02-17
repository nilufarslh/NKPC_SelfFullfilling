function params = unpack_params(theta, cfg)
%UNPACK_PARAMS Merge fixed and estimated parameters into a struct.

params = cfg.params.fixed;

names = cfg.params.estimated.names;
for i = 1:numel(names)
    params.(names{i}) = theta(i);
end

end
