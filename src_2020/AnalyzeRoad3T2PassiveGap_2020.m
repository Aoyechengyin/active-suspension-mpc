function report = AnalyzeRoad3T2PassiveGap_2020(passive_csv, active_csvs, output_markdown, settings)
%ANALYZEROAD3T2PASSIVEGAP_2020 T2 pilot active-vs-passive diagnostics.
%
% This report is scoped to Road-3 T2 50 mm pilot tuning. It compares each
% active case against a passive baseline and highlights low-frequency body
% response, pitch, heave, jounce travel, phase timing, and band-split RMS.

if nargin < 1 || isempty(passive_csv)
    error('Provide a passive CSV file.');
end
if nargin < 2 || isempty(active_csvs)
    error('Provide at least one active CSV file.');
end
if nargin < 3
    output_markdown = '';
end
if nargin < 4 || isempty(settings)
    settings = local_default_settings();
else
    settings = local_merge_settings(local_default_settings(), settings);
end

passive_csv = char(passive_csv);
assert(exist(passive_csv, 'file') > 0, 'Passive CSV file not found: %s', passive_csv);
active_files = local_normalize_files(active_csvs);

passive = local_analyze_one(passive_csv, settings);
comparisons = repmat(local_empty_comparison(), numel(active_files), 1);
for i = 1:numel(active_files)
    active = local_analyze_one(active_files{i}, settings);
    comparisons(i) = local_compare(passive, active);
end

if isempty(output_markdown)
    [folder, ~] = fileparts(active_files{1});
    if isempty(folder)
        folder = pwd;
    end
    output_markdown = fullfile(folder, 'road3_t2_passive_gap.md');
end

local_write_markdown(output_markdown, passive, comparisons, settings);

report = struct();
report.passive = passive;
report.comparisons = comparisons;
report.settings = settings;
report.output_markdown = output_markdown;

fprintf('Road-3 T2 passive-gap report written: %s\n', output_markdown);
end

function settings = local_default_settings()
settings = struct();
settings.g = 9.81;
settings.event_threshold_abs_m = 1e-6;
settings.event_threshold_fraction = 0.05;
settings.event_pre_s = 0.5;
settings.event_post_s = 3.0;
end

function settings = local_merge_settings(defaults, override)
settings = defaults;
names = fieldnames(override);
for i = 1:numel(names)
    settings.(names{i}) = override.(names{i});
end
end

function files = local_normalize_files(csv_files)
if ischar(csv_files)
    files = {csv_files};
elseif isstring(csv_files)
    files = cellstr(csv_files(:));
elseif iscell(csv_files)
    files = csv_files(:)';
else
    error('active_csvs must be a char, string, or cell array.');
end
for i = 1:numel(files)
    files{i} = char(files{i});
    assert(exist(files{i}, 'file') > 0, 'Active CSV file not found: %s', files{i});
end
end

function c = local_analyze_one(csv_file, settings)
opts = detectImportOptions(csv_file, 'VariableNamingRule', 'preserve');
T = readtable(csv_file, opts);
time = local_column(T, 'Time');
time = time(:);
valid = isfinite(time);
assert(any(valid), 'CSV has no finite Time values: %s', csv_file);

event = local_event_window(T, time, valid, settings);
mask = valid & time >= event.window_start_s & time <= event.window_end_s;
if ~any(mask)
    mask = valid;
end

[~, name, ext] = fileparts(csv_file);
c = struct();
c.file = csv_file;
c.name = [name ext];
c.event = event;
c.metrics = local_summary_metrics(T, time, mask, settings);
c.band = local_band_metrics(T, time, mask, settings);
c.phase = local_phase_metrics(T, time, mask, settings);
end

function metrics = local_summary_metrics(T, time, mask, settings) %#ok<INUSD>
metrics = struct();
az = local_column_or_nan(T, 'Az_SM') * settings.g;
aa_p = local_column_or_nan(T, 'AA_P');
pitch = local_column_or_nan(T, 'Pitch');

metrics.Az_event_rms = local_rms(az(mask));
metrics.Az_0_4_rms = local_band_rms(az(mask), time(mask), 0, 4);
metrics.Az_0_15_rms = local_band_rms(az(mask), time(mask), 0, 15);
metrics.AA_P_0_15_rms = local_band_rms(aa_p(mask), time(mask), 0, 15);
metrics.Zcg_SM_heave_peak = local_heave_peak(T, mask);
metrics.Pitch_peak = local_peak_abs(pitch(mask));
metrics.front_jnc_min = min([local_min(local_column_or_nan(T, 'Jnc_L1', mask)), local_min(local_column_or_nan(T, 'Jnc_R1', mask))]);
metrics.rear_jnc_min = min([local_min(local_column_or_nan(T, 'Jnc_L2', mask)), local_min(local_column_or_nan(T, 'Jnc_R2', mask))]);
end

function band = local_band_metrics(T, time, mask, settings)
band = struct();
band.Az_SM_m_s2 = local_band_item(local_column_or_nan(T, 'Az_SM', mask) * settings.g, time(mask));
band.AA_P = local_band_item(local_column_or_nan(T, 'AA_P', mask), time(mask));
end

function item = local_band_item(values, time)
item = struct();
item.event_rms = local_rms(values);
item.rms_0_2 = local_band_rms(values, time, 0, 2);
item.rms_2_4 = local_band_rms(values, time, 2, 4);
item.rms_4_8 = local_band_rms(values, time, 4, 8);
item.rms_8_15 = local_band_rms(values, time, 8, 15);
item.rms_0_4 = local_band_rms(values, time, 0, 4);
item.rms_0_15 = local_band_rms(values, time, 0, 15);
end

function phase = local_phase_metrics(T, time, mask, settings)
phase = struct();
phase.Az_SM = local_peak_time(time(mask), local_column_or_nan(T, 'Az_SM', mask) * settings.g);
phase.AA_P = local_peak_time(time(mask), local_column_or_nan(T, 'AA_P', mask));
phase.FsExt_L1 = local_peak_time(time(mask), local_column_or_nan(T, 'FsExt_L1', mask));
phase.FsExt_L2 = local_peak_time(time(mask), local_column_or_nan(T, 'FsExt_L2', mask));
phase.FsExt_L1_lag_vs_Az_s = phase.FsExt_L1.time_s - phase.Az_SM.time_s;
phase.FsExt_L2_lag_vs_Az_s = phase.FsExt_L2.time_s - phase.Az_SM.time_s;
end

function cmp = local_compare(passive, active)
cmp = local_empty_comparison();
cmp.active = active;
cmp.name = active.name;
cmp.gap = struct();
names = {'Az_event_rms','Az_0_4_rms','Az_0_15_rms','AA_P_0_15_rms', ...
    'Zcg_SM_heave_peak','Pitch_peak','front_jnc_min','rear_jnc_min'};
for i = 1:numel(names)
    name = names{i};
    cmp.gap.(name) = active.metrics.(name) - passive.metrics.(name);
end
cmp.band = active.band;
cmp.phase = active.phase;
cmp.passive_metrics = passive.metrics;
cmp.active_metrics = active.metrics;
end

function cmp = local_empty_comparison()
cmp = struct();
cmp.name = '';
cmp.active = struct();
cmp.gap = struct();
cmp.band = struct();
cmp.phase = struct();
cmp.passive_metrics = struct();
cmp.active_metrics = struct();
end

function event = local_event_window(T, time, valid, settings)
z_names = {'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2'};
road = nan(numel(time), numel(z_names));
for i = 1:numel(z_names)
    road(:, i) = abs(local_column_or_nan(T, z_names{i}));
end
road_abs = max(road, [], 2);
road_peak = max(road_abs(valid));
threshold = max(settings.event_threshold_abs_m, settings.event_threshold_fraction * road_peak);
active = valid & isfinite(road_abs) & road_abs >= threshold;

event = struct();
event.has_event = any(active);
event.road_peak_abs_m = road_peak;
event.threshold_m = threshold;
if event.has_event
    event.first_contact_s = min(time(active));
    event.last_contact_s = max(time(active));
else
    event.first_contact_s = min(time(valid));
    event.last_contact_s = max(time(valid));
end
event.window_start_s = max(min(time(valid)), event.first_contact_s - settings.event_pre_s);
event.window_end_s = min(max(time(valid)), event.last_contact_s + settings.event_post_s);
end

function local_write_markdown(output_markdown, passive, comparisons, settings)
[folder, ~] = fileparts(output_markdown);
if ~isempty(folder) && exist(folder, 'dir') ~= 7
    mkdir(folder);
end
fid = fopen(output_markdown, 'w');
assert(fid > 0, 'Unable to write Road-3 T2 report: %s', output_markdown);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Road-3 T2 Passive Gap Report\n\n');
fprintf(fid, '- Passive: `%s`\n', passive.name);
fprintf(fid, '- Event padding: `%.3f s` before, `%.3f s` after\n', settings.event_pre_s, settings.event_post_s);
fprintf(fid, '- Passive event window: `%.3f` to `%.3f s`\n\n', ...
    passive.event.window_start_s, passive.event.window_end_s);

fprintf(fid, '## Passive Gap Summary\n\n');
fprintf(fid, '| Active case | Az event RMS | Gap | Az 0-4 RMS | Gap | Az 0-15 RMS | Gap | AA_P 0-15 RMS | Gap | Heave peak | Gap | Pitch peak | Gap | Front Jnc min | Gap | Rear Jnc min | Gap |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:numel(comparisons)
    a = comparisons(i).active_metrics;
    g = comparisons(i).gap;
    fprintf(fid, '| `%s` | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
        comparisons(i).name, ...
        a.Az_event_rms, g.Az_event_rms, ...
        a.Az_0_4_rms, g.Az_0_4_rms, ...
        a.Az_0_15_rms, g.Az_0_15_rms, ...
        a.AA_P_0_15_rms, g.AA_P_0_15_rms, ...
        a.Zcg_SM_heave_peak, g.Zcg_SM_heave_peak, ...
        a.Pitch_peak, g.Pitch_peak, ...
        a.front_jnc_min, g.front_jnc_min, ...
        a.rear_jnc_min, g.rear_jnc_min);
end

fprintf(fid, '\n## Phase Timing\n\n');
fprintf(fid, '| Active case | Az peak s | Az peak | AA_P peak s | AA_P peak | FsExt_L1 peak s | FsExt_L1 peak N | L1-Az lag s | FsExt_L2 peak s | FsExt_L2 peak N | L2-Az lag s |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:numel(comparisons)
    p = comparisons(i).phase;
    fprintf(fid, '| `%s` | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
        comparisons(i).name, ...
        p.Az_SM.time_s, p.Az_SM.value, ...
        p.AA_P.time_s, p.AA_P.value, ...
        p.FsExt_L1.time_s, p.FsExt_L1.value, p.FsExt_L1_lag_vs_Az_s, ...
        p.FsExt_L2.time_s, p.FsExt_L2.value, p.FsExt_L2_lag_vs_Az_s);
end

fprintf(fid, '\n## Band-Split RMS\n\n');
fprintf(fid, '| Active case | Signal | Event RMS | 0-2 Hz | 2-4 Hz | 4-8 Hz | 8-15 Hz | 0-4 Hz | 0-15 Hz |\n');
fprintf(fid, '|---|---|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:numel(comparisons)
    local_write_band_row(fid, comparisons(i).name, 'Az_SM m/s^2', comparisons(i).band.Az_SM_m_s2);
    local_write_band_row(fid, comparisons(i).name, 'AA_P rad/s^2', comparisons(i).band.AA_P);
end

delete(cleanup);
end

function local_write_band_row(fid, case_name, signal_name, item)
fprintf(fid, '| `%s` | %s | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
    case_name, signal_name, item.event_rms, item.rms_0_2, item.rms_2_4, ...
    item.rms_4_8, item.rms_8_15, item.rms_0_4, item.rms_0_15);
end

function value = local_heave_peak(T, mask)
z = local_column_or_nan(T, 'Zcg_SM');
finite = isfinite(z);
if ~any(finite)
    value = nan;
    return;
end
z0 = z(find(finite, 1, 'first'));
value = local_peak_abs(z(mask) - z0);
end

function p = local_peak_time(time, values)
time = time(:);
values = values(:);
valid = isfinite(time) & isfinite(values);
p = struct('time_s', nan, 'value', nan, 'peak_abs', nan);
if ~any(valid)
    return;
end
tv = time(valid);
vv = values(valid);
[peak_abs, idx] = max(abs(vv));
p.time_s = tv(idx);
p.value = vv(idx);
p.peak_abs = peak_abs;
end

function values = local_column(T, name)
assert(any(strcmp(T.Properties.VariableNames, name)), 'Missing required column: %s', name);
values = T.(name);
values = values(:);
end

function values = local_column_or_nan(T, name, mask)
if any(strcmp(T.Properties.VariableNames, name))
    values_all = T.(name);
    values_all = values_all(:);
else
    values_all = nan(height(T), 1);
end
if nargin >= 3
    values = values_all(mask);
else
    values = values_all;
end
end

function y = local_min(values)
finite = values(isfinite(values));
if isempty(finite)
    y = nan;
else
    y = min(finite);
end
end

function y = local_peak_abs(values)
finite = values(isfinite(values));
if isempty(finite)
    y = nan;
else
    y = max(abs(finite));
end
end

function y = local_rms(values)
finite = values(isfinite(values));
if isempty(finite)
    y = nan;
else
    y = sqrt(mean(finite.^2));
end
end

function y = local_band_rms(values, time, f_min, f_max)
values = values(:);
time = time(:);
valid = isfinite(values) & isfinite(time);
values = values(valid);
time = time(valid);
if numel(values) < 4
    y = nan;
    return;
end
dt = local_sample_dt(time);
if ~isfinite(dt) || dt <= 0
    y = nan;
    return;
end
values = values - mean(values);
n = numel(values);
freq = (0:n-1)' / (n * dt);
Y = fft(values);
keep = freq >= f_min & freq <= f_max;
keep = keep | (freq >= (1/dt - f_max) & freq <= (1/dt - f_min));
filtered = real(ifft(Y .* keep));
y = sqrt(mean(filtered.^2));
end

function dt = local_sample_dt(time)
time = sort(time(:));
d = diff(time);
d = d(isfinite(d) & d > 0);
if isempty(d)
    dt = nan;
else
    dt = median(d);
end
end
