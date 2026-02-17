function report = moment_report(m_data, m_sim, names, cfg, X_data, X_sim, W)
%MOMENT_REPORT Save a moment-fit report (table + plots) to results/.

root = cfg.project_root;
out_dir = fullfile(root, 'results');
if ~isfolder(out_dir)
    mkdir(out_dir);
end

if numel(m_data) ~= numel(m_sim)
    error('Moment length mismatch in report.');
end

if nargin < 3 || isempty(names)
    names = compose('m_%d', (1:numel(m_data))');
end

if nargin < 5
    X_data = [];
end
if nargin < 6
    X_sim = [];
end
if nargin < 7 || isempty(W)
    W = eye(numel(m_data));
end

names = names(:);
diff = m_sim - m_data;
scale = max(1e-8, abs(m_data));
pct_gap = 100 * diff ./ scale;

% Per-moment loss contribution (sums to total if W is symmetric)
Wd = W * diff;
contrib = diff .* Wd;

report = table(names, m_data, m_sim, diff, pct_gap, contrib, ...
    'VariableNames', {'moment','data','sim','diff','pct_gap','loss_contrib'});

writetable(report, fullfile(out_dir, 'moment_report.csv'));

% Plot percent gaps
fig = figure('Visible', 'off');
bar(pct_gap);
xticks(1:numel(pct_gap));
xticklabels(names);
xtickangle(45);
ylabel('Percent gap (sim - data) / |data|');
title('Moment Fit');
set(gcf, 'Position', [100 100 1200 400]);

saveas(fig, fullfile(out_dir, 'moment_report.png'));
close(fig);

% Series overlay plot (pi, y, r if available)
if ~isempty(X_data) && ~isempty(X_sim)
    T = min(size(X_data, 1), size(X_sim, 1));
    Xd = X_data(end-T+1:end, :);
    Xs = X_sim(end-T+1:end, :);
    labels = {'pi','y','r'};

    fig = figure('Visible', 'off');
    nplot = min(3, size(Xd,2));
    for i = 1:nplot
        subplot(nplot, 1, i);
        plot(Xd(:, i), 'k', 'LineWidth', 1.0); hold on;
        plot(Xs(:, i), 'r--', 'LineWidth', 1.0);
        title(sprintf('Series overlay: %s', labels{i}));
        legend('Data','Sim','Location','best');
    end
    set(gcf, 'Position', [100 100 1200 600]);
    saveas(fig, fullfile(out_dir, 'series_overlay.png'));
    close(fig);

    % ACF plot for pi and y (and r if present)
    max_lag = 12;
    if isfield(cfg.moments, 'acf_lag')
        max_lag = cfg.moments.acf_lag;
    end

    fig = figure('Visible', 'off');
    nplot = min(3, size(Xd,2));
    for i = 1:nplot
        subplot(nplot, 1, i);
        acf_d = simple_acf(Xd(:, i), max_lag);
        acf_s = simple_acf(Xs(:, i), max_lag);
        lags = 0:max_lag;
        plot(lags, acf_d, 'k-o'); hold on;
        plot(lags, acf_s, 'r--o');
        title(sprintf('ACF: %s', labels{i}));
        legend('Data','Sim','Location','best');
        xlabel('Lag');
        ylabel('ACF');
    end
    set(gcf, 'Position', [100 100 1200 600]);
    saveas(fig, fullfile(out_dir, 'acf_plot.png'));
    close(fig);
end

end

function acf = simple_acf(x, max_lag)
x = x(:);
x = x - mean(x, 'omitnan');
den = sum(x.^2);
acf = zeros(max_lag+1, 1);
for k = 0:max_lag
    acf(k+1) = sum(x(1:end-k) .* x(1+k:end)) / den;
end
end
