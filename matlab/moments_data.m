function [m, names] = moments_data(X, cfg)
%MOMENTS_DATA Compute data moments according to cfg.moments.option.

switch lower(cfg.moments.option)
    case 'var1'
        [A, Sigma] = moments_var1(X);
        vecA = vec(A);
        vechS = vech(Sigma);
        m_full = [vecA; vechS];
        names_full = build_var1_names(size(A,1));
        drop_idx = cfg.moments.var1.drop_idx;
        if ~isempty(drop_idx)
            keep = true(size(m_full));
            keep(drop_idx) = false;
            m = m_full(keep);
            names = names_full(keep);
        else
            m = m_full;
            names = names_full;
        end
    case 'var1_xy_var_r'
        % VAR(1) on (pi, y) only + direct Var(pi), Var(y), Var(r)
        Xxy = X(:, 1:2);
        [A, Sigma] = moments_var1(Xxy);
        vecA = vec(A);
        vechS = vech(Sigma);
        var_pi = var(X(:,1), 1);
        var_y  = var(X(:,2), 1);
        var_r = var(X(:,3), 1);
        m = [vecA; vechS; var_pi; var_y; var_r];

        names = build_var1_names({'pi','y'});
        names{end+1,1} = 'var_pi';
        names{end+1,1} = 'var_y';
        names{end+1,1} = 'var_r';
        if isfield(cfg.moments, 'include_cov_pi_y') && cfg.moments.include_cov_pi_y
            cov_py = cov(X(:,1), X(:,2), 1);
            m = [m; cov_py(1,2)];
            names{end+1,1} = 'cov_pi_y_0';
        end
    case 'var1_plus_scale'
        [A, Sigma] = moments_var1(X);
        vecA = vec(A);
        vechS = vech(Sigma);
        var_pi = var(X(:,1), 1);
        var_y  = var(X(:,2), 1);
        var_r  = var(X(:,3), 1);
        m = [vecA; vechS; var_pi; var_y; var_r];

        names = build_var1_names(size(A,1));
        names{end+1,1} = 'var_pi';
        names{end+1,1} = 'var_y';
        names{end+1,1} = 'var_r';
    otherwise
        error('Unknown moment option: %s', cfg.moments.option);
end

end

function names = build_var1_names(arg)
% Build names for vec(A) and vech(Sigma)
if iscell(arg)
    varnames = arg;
    n = numel(varnames);
else
    n = arg;
    varnames = {'pi','y','r'};
    varnames = varnames(1:n);
end

names = {};
for i = 1:n
    for j = 1:n
        names{end+1,1} = sprintf('A_%s_%s', varnames{i}, varnames{j});
    end
end

for i = 1:n
    for j = 1:i
        names{end+1,1} = sprintf('S_%s_%s', varnames{i}, varnames{j});
    end
end
end
