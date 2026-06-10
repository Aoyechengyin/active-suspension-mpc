function report = AnalyzeRoad3BumpExperiment_2020(csv_files, output_markdown, settings)
%ANALYZEROAD3BUMPEXPERIMENT_2020 Compare Road-3 speed-bump experiment CSVs.
%
% The report is intended for the Road-3 paper speed-bump stage:
% passive, eMPC no-preview, and eMPC preview.

if nargin < 1 || isempty(csv_files)
    error('Provide one or more Road-3 CSV files.');
end
if nargin < 2
    output_markdown = '';
end
if nargin < 3 || isempty(settings)
    settings = local_default_settings();
else
    settings = local_merge_settings(local_default_settings(), settings);
end

files = local_normalize_files(csv_files);
cases = repmat(local_empty_case(), numel(files), 1);
for i = 1:numel(files)
    cases(i) = local_analyze_one(files{i}, settings);
end

if isempty(output_markdown)
    output_markdown = local_default_report_path(files);
end

local_write_markdown(output_markdown, cases, settings);

report = struct();
report.cases = cases;
report.settings = settings;
report.output_markdown = output_markdown;

fprintf('Road-3 bump report written: %s\n', output_markdown);
for i = 1:numel(cases)
    fprintf('%s: %d warnings\n', cases(i).name, numel(cases(i).warnings));
end
end

function settings = local_default_settings()
settings = struct();
settings.g = 9.81;
settings.event_threshold_abs_m = 1e-6;
settings.event_threshold_fraction = 0.05;
settings.event_pre_s = 0.5;
settings.event_post_s = 3.0;
settings.saturation_tolerance_N = 1.0;
settings.saturation_fraction_limit_pilot = 0.01;
settings.saturation_fraction_limit_full = 0.05;
settings.force_limits_N = struct( ...
    'FsExt_L1', 3000, ...
    'FsExt_R1', 3000, ...
    'FsExt_L2', 2000, ...
    'FsExt_R2', 2000);
settings.rear_diff_limit_N = 1000;
settings.high_freq_min_Hz = 15;
settings.high_freq_max_Hz = 20;
settings.fft_max_Hz = 30;
end

function settings = local_merge_settings(defaults, override)
settings = defaults;
names = fieldnames(override);
for i = 1:numel(names)
    name = names{i};
    if isstruct(override.(name)) && isfield(settings, name) && isstruct(settings.(name))
        nested = fieldnames(override.(name));
        for j = 1:numel(nested)
            settings.(name).(nested{j}) = override.(name).(nested{j});
        end
    else
        settings.(name) = override.(name);
    end
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
    error('csv_files must be a char, string, or cell array.');
end
for i = 1:numel(files)
    files{i} = char(files{i});
    assert(exist(files{i}, 'file') > 0, 'CSV file not found: %s', files{i});
end
end

function out = local_default_report_path(files)
[folder, ~] = fileparts(files{1});
if isempty(folder)
    folder = pwd;
end
out = fullfile(folder, 'road3_bump_report.md');
end

function c = local_empty_case()
c = struct();
c.file = '';
c.name = '';
c.columns = {};
c.missing_required = {};
c.missing_recommended = {};
c.metrics = struct();
c.warnings = {};
end

function result = local_analyze_one(csv_file, settings)
opts = detectImportOptions(csv_file, 'VariableNamingRule', 'preserve');
T = readtable(csv_file, opts);
names = T.Properties.VariableNames;

[missing_required, missing_recommended] = local_missing_columns(names);
time = local_column(T, 'Time');
time = time(:);
valid = isfinite(time);
assert(any(valid), 'CSV has no finite Time values: %s', csv_file);

event = local_event_window(T, time, valid, settings);
mask_event = valid & time >= event.window_start_s & time <= event.window_end_s;
if ~any(mask_event)
    mask_event = valid;
end

metrics = struct();
metrics.sample = local_sample_metrics(T, time, valid);
metrics.event = event;
metrics.signal = local_signal_metrics(T, mask_event, settings);
metrics.band = local_band_metrics(T, time, mask_event, settings);
metrics.force = local_force_metrics(T, valid, mask_event, settings);
metrics.jounce = local_jounce_metrics(T, mask_event);
metrics.preview = local_preview_summary(T, time);
metrics.wheel_rotation_min_delta = local_wheel_rotation_delta(T);

warnings = local_make_warnings(metrics, missing_required, settings);

[~, name, ext] = fileparts(csv_file);
result = local_empty_case();
result.file = csv_file;
result.name = [name ext];
result.columns = names;
result.missing_required = missing_required;
result.missing_recommended = missing_recommended;
result.metrics = metrics;
result.warnings = warnings;
end

function [missing_required, missing_recommended] = local_missing_columns(names)
required = { ...
    'Time','Pitch','Roll','Yaw','Xo','Yo','Az_SM','Ay_SM','Vz_SM', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2', ...
    'W1_L1','W1_R1','W1_L2','W1_R2', ...
    'W2_L1','W2_R1','W2_L2','W2_R2', ...
    'Rot_L1','Rot_R1','Rot_L2','Rot_R2' ...
};
recommended = {'Zcg_SM','AV_P','AA_P','AV_R','AA_R','Steer_SW'};

missing_required = {};
for i = 1:numel(required)
    if ~local_has_column(names, required{i})
        missing_required{end+1} = required{i}; %#ok<AGROW>
    end
end
if ~(local_has_column(names, 'Vx') || local_has_column(names, 'Vxz_Fwd'))
    missing_required{end+1} = 'Vx or Vxz_Fwd'; %#ok<AGROW>
end

missing_recommended = {};
for i = 1:numel(recommended)
    if ~local_has_column(names, recommended{i})
        missing_recommended{end+1} = recommended{i}; %#ok<AGROW>
    end
end
end

function metrics = local_sample_metrics(T, time, valid)
metrics = struct();
metrics.rows = height(T);
metrics.time_start_s = min(time(valid));
metrics.time_end_s = max(time(valid));
metrics.dt_s = local_sample_dt(time(valid));
if local_has_table_column(T, 'Vxz_Fwd')
    vx = local_column(T, 'Vxz_Fwd');
elseif local_has_table_column(T, 'Vx')
    vx = local_column(T, 'Vx');
else
    vx = nan(size(time));
end
metrics.vx_mean_km_h = mean(vx(isfinite(vx)));
if local_has_table_column(T, 'Xo')
    x = local_column(T, 'Xo');
    metrics.station_end_m = x(find(isfinite(x), 1, 'last'));
else
    metrics.station_end_m = nan;
end
end

function event = local_event_window(T, time, valid, settings)
z_names = {'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2'};
road = nan(numel(time), numel(z_names));
for i = 1:numel(z_names)
    if local_has_table_column(T, z_names{i})
        road(:, i) = abs(local_column(T, z_names{i}));
    end
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

function metrics = local_signal_metrics(T, mask, settings)
metrics = struct();
metrics.Az_SM_m_s2 = local_stats(local_column_or_nan(T, 'Az_SM', mask) * settings.g);
metrics.Ay_SM_m_s2 = local_stats(local_column_or_nan(T, 'Ay_SM', mask) * settings.g);
metrics.Vz_SM = local_stats(local_column_or_nan(T, 'Vz_SM', mask));
metrics.Pitch = local_stats(local_column_or_nan(T, 'Pitch', mask));
metrics.Roll = local_stats(local_column_or_nan(T, 'Roll', mask));
metrics.Yaw = local_stats(local_column_or_nan(T, 'Yaw', mask));
metrics.Yo = local_stats(local_column_or_nan(T, 'Yo', mask));
metrics.AA_P = local_stats(local_column_or_nan(T, 'AA_P', mask));
metrics.AA_R = local_stats(local_column_or_nan(T, 'AA_R', mask));
metrics.AV_P = local_stats(local_column_or_nan(T, 'AV_P', mask));
metrics.AV_R = local_stats(local_column_or_nan(T, 'AV_R', mask));

if local_has_table_column(T, 'Zcg_SM')
    z = local_column(T, 'Zcg_SM');
    finite = isfinite(z);
    if any(finite)
        z0 = z(find(finite, 1, 'first'));
        metrics.Zcg_SM_heave_m = local_stats(z(mask) - z0);
    else
        metrics.Zcg_SM_heave_m = local_stats(nan(sum(mask), 1));
    end
else
    metrics.Zcg_SM_heave_m = local_stats(nan(sum(mask), 1));
end
end

function band = local_band_metrics(T, time, mask, settings)
band = struct();
band.Az_SM_m_s2 = local_band_item(local_column_or_nan(T, 'Az_SM', mask) * settings.g, time(mask));
band.AA_P = local_band_item(local_column_or_nan(T, 'AA_P', mask), time(mask));
band.AA_R = local_band_item(local_column_or_nan(T, 'AA_R', mask), time(mask));
end

function item = local_band_item(values, time)
item = struct();
item.event_rms = local_rms(values);
item.rms_0_4 = local_band_rms(values, time, 0, 4);
item.rms_0_15 = local_band_rms(values, time, 0, 15);
end

function force = local_force_metrics(T, full_mask, event_mask, settings)
force = struct();
names = {'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2'};
max_sat = 0;
for i = 1:numel(names)
    name = names{i};
    vals = local_column_or_nan(T, name, full_mask);
    event_vals = local_column_or_nan(T, name, event_mask);
    lim = settings.force_limits_N.(name);
    stat = local_stats(event_vals);
    stat.limit_N = lim;
    stat.saturation_fraction = mean(abs(vals(isfinite(vals))) >= (lim - settings.saturation_tolerance_N));
    if isempty(stat.saturation_fraction) || ~isfinite(stat.saturation_fraction)
        stat.saturation_fraction = nan;
    end
    force.(name) = stat;
    max_sat = max(max_sat, stat.saturation_fraction);
end
force.max_saturation_fraction = max_sat;

if local_has_table_column(T, 'FsExt_L1') && local_has_table_column(T, 'FsExt_R1')
    force.front_lr = local_stats(local_column(T, 'FsExt_L1') - local_column(T, 'FsExt_R1'));
else
    force.front_lr = local_stats(nan(sum(full_mask), 1));
end
if local_has_table_column(T, 'FsExt_L2') && local_has_table_column(T, 'FsExt_R2')
    rear_diff = local_column(T, 'FsExt_L2') - local_column(T, 'FsExt_R2');
    force.rear_lr = local_stats(rear_diff);
    force.rear_lr_dominant_Hz = local_dominant_frequency(local_column(T, 'Time'), rear_diff, settings.fft_max_Hz);
else
    force.rear_lr = local_stats(nan(sum(full_mask), 1));
    force.rear_lr_dominant_Hz = nan;
end
end

function jounce = local_jounce_metrics(T, mask)
names = {'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2','JncR_L1','JncR_R1','JncR_L2','JncR_R2'};
jounce = struct();
for i = 1:numel(names)
    jounce.(names{i}) = local_stats(local_column_or_nan(T, names{i}, mask));
end
end

function preview = local_preview_summary(T, time)
preview = struct();
pairs = { ...
    'W1_L1','Zgnd_L1',0.010; 'W1_R1','Zgnd_R1',0.010; ...
    'W1_L2','Zgnd_L2',0.010; 'W1_R2','Zgnd_R2',0.010; ...
    'W2_L1','Zgnd_L1',0.020; 'W2_R1','Zgnd_R1',0.020; ...
    'W2_L2','Zgnd_L2',0.020; 'W2_R2','Zgnd_R2',0.020 ...
};
for i = 1:size(pairs, 1)
    pname = pairs{i, 1};
    zname = pairs{i, 2};
    expected = pairs{i, 3};
    item = struct('expected_lead_s', expected, 'estimated_lead_s', nan, 'z_peak_m', nan, 'preview_peak_m', nan);
    if local_has_table_column(T, pname) && local_has_table_column(T, zname)
        z = abs(local_column(T, zname));
        p = abs(local_column(T, pname));
        [item.z_peak_m, iz] = max(z);
        [item.preview_peak_m, ip] = max(p);
        item.estimated_lead_s = time(iz) - time(ip);
    end
    preview.(pname) = item;
end
end

function delta = local_wheel_rotation_delta(T)
names = {'Rot_L1','Rot_R1','Rot_L2','Rot_R2'};
vals = nan(numel(names), 1);
for i = 1:numel(names)
    if local_has_table_column(T, names{i})
        v = local_column(T, names{i});
        finite = isfinite(v);
        if any(finite)
            vals(i) = v(find(finite, 1, 'last')) - v(find(finite, 1, 'first'));
        end
    end
end
delta = min(vals);
end

function warnings = local_make_warnings(metrics, missing_required, settings)
warnings = {};
if ~isempty(missing_required)
    warnings{end+1} = ['Missing required columns: ' strjoin(missing_required, ', ')]; %#ok<AGROW>
end
if metrics.force.max_saturation_fraction > settings.saturation_fraction_limit_full
    warnings{end+1} = sprintf('FsExt saturation fraction %.4g exceeds full-test limit %.4g.', ...
        metrics.force.max_saturation_fraction, settings.saturation_fraction_limit_full); %#ok<AGROW>
end
if metrics.force.rear_lr.peak_abs > settings.rear_diff_limit_N
    warnings{end+1} = sprintf('Rear FsExt L-R peak %.4g N exceeds %.4g N.', ...
        metrics.force.rear_lr.peak_abs, settings.rear_diff_limit_N); %#ok<AGROW>
end
if metrics.wheel_rotation_min_delta <= 0
    warnings{end+1} = 'At least one Rot_* signal did not increase.'; %#ok<AGROW>
end
f = metrics.force.rear_lr_dominant_Hz;
if isfinite(f) && f >= settings.high_freq_min_Hz && f <= settings.high_freq_max_Hz
    warnings{end+1} = sprintf('Rear FsExt L-R dominant frequency %.4g Hz is in the 15-20 Hz watch band.', f); %#ok<AGROW>
end
end

function local_write_markdown(output_markdown, cases, settings)
[folder, ~] = fileparts(output_markdown);
if ~isempty(folder) && ~exist(folder, 'dir')
    mkdir(folder);
end
fid = fopen(output_markdown, 'w');
assert(fid > 0, 'Unable to write Road-3 report: %s', output_markdown);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Road-3 Bump Experiment Report\n\n');
fprintf(fid, '- Cases: `%d`\n', numel(cases));
fprintf(fid, '- Event padding: `%.3f s` before, `%.3f s` after\n', settings.event_pre_s, settings.event_post_s);
fprintf(fid, '- Force limits: front `%.0f N`, rear `%.0f N`\n\n', ...
    settings.force_limits_N.FsExt_L1, settings.force_limits_N.FsExt_L2);

fprintf(fid, '## Summary\n\n');
fprintf(fid, '| Case | Road peak m | Az event RMS m/s^2 | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | AA_R 0-15 RMS | Max FsExt sat. | Rear L-R peak N | Rot min delta |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:numel(cases)
    m = cases(i).metrics;
    fprintf(fid, '| `%s` | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
        cases(i).name, m.event.road_peak_abs_m, ...
        m.band.Az_SM_m_s2.event_rms, m.band.Az_SM_m_s2.rms_0_4, m.band.Az_SM_m_s2.rms_0_15, ...
        m.band.AA_P.rms_0_15, m.band.AA_R.rms_0_15, ...
        m.force.max_saturation_fraction, m.force.rear_lr.peak_abs, m.wheel_rotation_min_delta);
end

for i = 1:numel(cases)
    local_write_case(fid, cases(i));
end

delete(cleanup);
end

function local_write_case(fid, c)
m = c.metrics;
fprintf(fid, '\n## `%s`\n\n', c.name);
fprintf(fid, '- Source: `%s`\n', c.file);
fprintf(fid, '- Rows/time: `%d`, `%.3f` to `%.3f s`, dt `%.6g s`\n', ...
    m.sample.rows, m.sample.time_start_s, m.sample.time_end_s, m.sample.dt_s);
fprintf(fid, '- Event window: `%.3f` to `%.3f s`, road peak `%.6g m`\n', ...
    m.event.window_start_s, m.event.window_end_s, m.event.road_peak_abs_m);
fprintf(fid, '- Final station/speed: `%.6g m`, `%.6g km/h`\n', ...
    m.sample.station_end_m, m.sample.vx_mean_km_h);
fprintf(fid, '- Heave peak abs from `Zcg_SM`: `%.6g m`\n', m.signal.Zcg_SM_heave_m.peak_abs);
fprintf(fid, '- Pitch/Roll peak abs: `%.6g deg` / `%.6g deg`\n', ...
    m.signal.Pitch.peak_abs, m.signal.Roll.peak_abs);
fprintf(fid, '- Front/Rear FsExt L-R peak abs: `%.6g N` / `%.6g N`\n', ...
    m.force.front_lr.peak_abs, m.force.rear_lr.peak_abs);

fprintf(fid, '\n### Band RMS\n\n');
fprintf(fid, '| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |\n|---|---:|---:|---:|\n');
fprintf(fid, '| Az_SM m/s^2 | %.6g | %.6g | %.6g |\n', ...
    m.band.Az_SM_m_s2.event_rms, m.band.Az_SM_m_s2.rms_0_4, m.band.Az_SM_m_s2.rms_0_15);
fprintf(fid, '| AA_P rad/s^2 | %.6g | %.6g | %.6g |\n', ...
    m.band.AA_P.event_rms, m.band.AA_P.rms_0_4, m.band.AA_P.rms_0_15);
fprintf(fid, '| AA_R rad/s^2 | %.6g | %.6g | %.6g |\n', ...
    m.band.AA_R.event_rms, m.band.AA_R.rms_0_4, m.band.AA_R.rms_0_15);

fprintf(fid, '\n### Force Saturation\n\n');
fprintf(fid, '| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |\n|---|---:|---:|---:|---:|---:|\n');
names = {'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2'};
for i = 1:numel(names)
    s = m.force.(names{i});
    fprintf(fid, '| %s | %.0f | %.3f | %.3f | %.3f | %.6g |\n', ...
        names{i}, s.limit_N, s.min, s.max, s.rms, s.saturation_fraction);
end

if isempty(c.warnings)
    fprintf(fid, '\nWarnings: none.\n');
else
    fprintf(fid, '\nWarnings:\n');
    for i = 1:numel(c.warnings)
        fprintf(fid, '- %s\n', c.warnings{i});
    end
end
end

function tf = local_has_table_column(T, name)
tf = local_has_column(T.Properties.VariableNames, name);
end

function tf = local_has_column(names, name)
tf = any(strcmp(names, name));
end

function values = local_column(T, name)
values = T.(name);
values = values(:);
end

function values = local_column_or_nan(T, name, mask)
if local_has_table_column(T, name)
    all_values = local_column(T, name);
else
    all_values = nan(height(T), 1);
end
values = all_values(mask);
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

function s = local_stats(values)
values = values(:);
finite = values(isfinite(values));
s = struct('mean', nan, 'min', nan, 'max', nan, 'rms', nan, 'peak_abs', nan);
if isempty(finite)
    return;
end
s.mean = mean(finite);
s.min = min(finite);
s.max = max(finite);
s.rms = sqrt(mean(finite.^2));
s.peak_abs = max(abs(finite));
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

function f = local_dominant_frequency(time, values, max_hz)
time = time(:);
values = values(:);
valid = isfinite(time) & isfinite(values);
time = time(valid);
values = values(valid);
if numel(values) < 8
    f = nan;
    return;
end
dt = local_sample_dt(time);
if ~isfinite(dt) || dt <= 0
    f = nan;
    return;
end
values = values - mean(values);
n = numel(values);
freq = (0:n-1)' / (n * dt);
amp = abs(fft(values));
mask = freq > 0 & freq <= max_hz;
if ~any(mask)
    f = nan;
    return;
end
freqs = freq(mask);
amps = amp(mask);
[~, idx] = max(amps);
f = freqs(idx);
end
