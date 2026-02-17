function v = vech(S)
%VECH Half-vectorization (lower triangular, including diagonal).
[n, m] = size(S);
if n ~= m
    error('vech expects a square matrix.');
end
idx = tril(true(n));
v = S(idx);
end
