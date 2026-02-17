function fetch_fred_data()
%FETCH_FRED_DATA Download FRED series and build data/targets.csv.
%   Series used (defaults):
%     CPIAUCSL (monthly CPI), GDPC1 (quarterly real GDP),
%     GDPPOT (quarterly potential GDP), FEDFUNDS (monthly policy rate).
%
%   Output columns: date, pi, y, r
%   - pi: quarterly inflation (annualized, percent)
%   - y: output gap (percent)
%   - r: quarterly average federal funds rate (percent, annual rate)

root = fileparts(fileparts(mfilename('fullpath')));
out_file = fullfile(root, 'data', 'targets.csv');

cfg = struct();

% Series IDs
cfg.series.cpi = 'CPIAUCSL';
cfg.series.gdp = 'GDPC1';
cfg.series.pot = 'GDPPOT';
cfg.series.ffr = 'FEDFUNDS';

% Sample window 
cfg.start_date = '1984-01-01';
cfg.end_date = '';

% Quarterly aggregation for monthly series
cfg.cpi_quarter_method = 'mean';
cfg.rate_quarter_method = 'mean';

% Inflation definition: 'log_diff_annualized' or 'pct_change_annualized'
cfg.inflation_method = 'log_diff_annualized';

% Output gap definition: 'log_diff' or 'percent_gap'
cfg.gap_method = 'log_diff';

% ----------------------------
% Download data
% ----------------------------

cpi_m = fred_download_series(cfg.series.cpi, cfg.start_date, cfg.end_date);
ffr_m = fred_download_series(cfg.series.ffr, cfg.start_date, cfg.end_date);
gdp_q = fred_download_series(cfg.series.gdp, cfg.start_date, cfg.end_date);
pot_q = fred_download_series(cfg.series.pot, cfg.start_date, cfg.end_date);

% ----------------------------
% Convert to quarterly
% ----------------------------

cpi_q = to_quarterly(cpi_m, cfg.cpi_quarter_method);
ffr_q = to_quarterly(ffr_m, cfg.rate_quarter_method);
gdp_q = to_quarterly(gdp_q, 'as_is');
pot_q = to_quarterly(pot_q, 'as_is');

% ----------------------------
% Construct targets
% ----------------------------

% Inflation (pi)
pi_tbl = inflation_from_cpi(cpi_q, cfg.inflation_method);

% Output gap (y)
[gdp_pot, gap] = output_gap(gdp_q, pot_q, cfg.gap_method);
gap_tbl = gdp_pot;
gap_tbl.y = gap;

% Policy rate (r)
ffr_tbl = ffr_q(:, {'year','quarter','value'});
ffr_tbl.Properties.VariableNames{'value'} = 'r';

% Merge
T = outerjoin(pi_tbl, gap_tbl(:, {'year','quarter','y'}), 'Keys', {'year','quarter'}, 'MergeKeys', true);
T = outerjoin(T, ffr_tbl, 'Keys', {'year','quarter'}, 'MergeKeys', true);

% Build date label (YYYYQn)
T.date = compose('%dQ%d', T.year, T.quarter);

% Final table
out = T(:, {'date','pi','y','r'});

% Drop rows with missing values
valid = all(~ismissing(out), 2);
out = out(valid, :);

% Write
writetable(out, out_file);

fprintf('Saved %d rows to %s\n', height(out), out_file);

end

function T = fred_download_series(series_id, start_date, end_date)
% Download a FRED series via fredgraph CSV (no API key required)

base = 'https://fred.stlouisfed.org/graph/fredgraph.csv';
url = sprintf('%s?id=%s', base, series_id);
if ~isempty(start_date)
    url = sprintf('%s&cosd=%s', url, start_date);
end
if ~isempty(end_date)
    url = sprintf('%s&coed=%s', url, end_date);
end

opts = detectImportOptions(url, 'Delimiter', ',', 'TreatAsMissing', '.');
Traw = readtable(url, opts);

if width(Traw) < 2
    error('Unexpected FRED response for series %s.', series_id);
end

date = Traw{:,1};
value = Traw{:,2};

if ~isdatetime(date)
    date = datetime(date, 'InputFormat', 'yyyy-MM-dd');
end

if iscell(value) || isstring(value)
    value = str2double(value);
end

T = table(date, value, 'VariableNames', {'date','value'});
T = sortrows(T, 'date');
end

function Q = to_quarterly(T, method)
% Convert a series to quarterly frequency

y = year(T.date);
q = quarter(T.date);
key = [y, q];

[uniq, ~, g] = unique(key, 'rows', 'stable');

switch lower(method)
    case 'mean'
        v = splitapply(@(x) mean(x, 'omitnan'), T.value, g);
    case 'eop'
        v = splitapply(@(x) x(end), T.value, g);
    case 'as_is'
        v = splitapply(@(x) mean(x, 'omitnan'), T.value, g);
    otherwise
        error('Unknown quarterly method: %s', method);
end

Q = table(uniq(:,1), uniq(:,2), v, 'VariableNames', {'year','quarter','value'});

% Friendly date (first month of quarter)
Q.date = datetime(Q.year, (Q.quarter - 1) * 3 + 1, 1);

% Rename for clarity downstream
if strcmpi(method, 'as_is')
    % No change
end

end

function pi_tbl = inflation_from_cpi(cpi_q, method)
% Compute quarterly inflation from CPI index

cpi = cpi_q.value;

switch lower(method)
    case 'log_diff_annualized'
        pi = 400 * diff(log(cpi));
    case 'pct_change_annualized'
        pi = 400 * diff(cpi) ./ cpi(1:end-1);
    otherwise
        error('Unknown inflation method: %s', method);
end

pi_tbl = table(cpi_q.year(2:end), cpi_q.quarter(2:end), pi, ...
    'VariableNames', {'year','quarter','pi'});
end

function [gdp_pot, gap] = output_gap(gdp_q, pot_q, method)
% Compute output gap from real GDP and potential GDP

G = outerjoin(gdp_q, pot_q, 'Keys', {'year','quarter'}, 'MergeKeys', true, ...
    'LeftVariables', {'year','quarter','value'}, 'RightVariables', {'value'});

if width(G) < 4
    error('Unable to merge GDP and potential GDP series.');
end

G.Properties.VariableNames = {'year','quarter','gdp','pot'};

switch lower(method)
    case 'log_diff'
        gap = 100 * (log(G.gdp) - log(G.pot));
    case 'percent_gap'
        gap = 100 * (G.gdp ./ G.pot - 1);
    otherwise
        error('Unknown output gap method: %s', method);
end

gdp_pot = G;
end
