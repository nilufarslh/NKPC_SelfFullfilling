function pi_exp = expectation_default(pi_history, t, cfg)
%EXPECTATION_DEFAULT Simple expectation rule for pi_{t+1}.
%   Uses last observed inflation if available, otherwise zero.

if t <= 1
    pi_exp = 0.0;
else
    pi_exp = pi_history(t-1);
end

end
