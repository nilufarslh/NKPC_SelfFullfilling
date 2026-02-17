function [data, info] = load_data(cfg)
%LOAD_DATA Load and transform target data series.
%   Expected CSV format: date, pi, y, r (headers required).

if ~isfile(cfg.data.path)
    error('Data file not found: %s', cfg.data.path);
end

T = readtable(cfg.data.path);
required = {'pi', 'y', 'r'};
for i = 1:numel(required)
    if ~ismember(required{i}, T.Properties.VariableNames)
        error('Missing column "%s" in data file.', required{i});
    end
end

pi = T.pi;
y = T.y;
r = T.r;

% Annualize (quarterly rate * 4)
if cfg.sample.annualize
    pi = 4 * pi;
    r = 4 * r;
end

% Demean 
if cfg.sample.demean
    pi = pi - mean(pi, 'omitnan');
    y = y - mean(y, 'omitnan');
    r = r - mean(r, 'omitnan');
end

X = [pi(:), y(:), r(:)];

% Drop rows with NaNs
valid = all(~isnan(X), 2);
X = X(valid, :);

info = struct();
info.n = size(X, 2);
info.T = size(X, 1);
info.names = {'pi','y','r'};

data = struct();
data.X = X;

end
