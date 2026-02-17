function [A, Sigma] = moments_var1(X)
%MOMENTS_VAR1 Estimate VAR(1): X_t = A * X_{t-1} + eps_t

Y = X(2:end, :);
Xlag = X(1:end-1, :);

% OLS: Y = Xlag * B, where B = A'
B = Xlag \ Y;
A = B';

resid = Y - Xlag * B;
Sigma = (resid' * resid) / size(resid, 1);
end
