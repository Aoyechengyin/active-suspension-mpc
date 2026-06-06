function report = AnalyzeRoadExperiment_2020(csv_files, output_markdown, settings)
%ANALYZEROADEXPERIMENT_2020 Diagnose CarSim road experiments for eMPC.
%
%   report = AnalyzeRoadExperiment_2020(csv_file)
%   report = AnalyzeRoadExperiment_2020({baseline_csv, road_csv}, output_markdown)
%
% The parser uses CSV column names, not column order. The default force
% limits match the accepted B4 baseline: front 3000 N, rear 2000 N.

if nargin < 1 || isempty(csv_files)
    project_root = fileparts(fileparts(mfilename('fullpath')));
    csv_files = fullfile(project_root, 'Output', 'CaseB4', '2026-06-06_00.28.33.csv');
end
if nargin < 2
    output_markdown = '';
end
if nargin < 3 || isempty(settings)
    settings = local_default_settings();
else
    settings = local_merge_settings(local_default_settings(), settings);
end

csv_files = local_normalize_files(csv_files);
assert(~isempty(csv_files), 'No CSV files provided.');

case_cells = cell(1, numel(csv_files));
for i = 1:numel(csv_files)
    case_cells{i} = local_analyze_one(csv_files{i}, settings);
end
cases = [case_cells{:}];

if isempty(output_markdown)
    output_markdown = local_default_report_path(csv_files);
end

comparison = [];
if numel(cases) >= 2
    comparison = local_compare_to_baseline(cases);
end

local_write_markdown(output_markdown, cases, comparison, settings);

report = struct();
report.cases = cases;
report.comparison = comparison;
report.settings = settings;
report.output_markdown = output_markdown;

fprintf('Road-experiment report written: %s\n', output_markdown);
for i = 1:numel(cases)
    fprintf('%s: %d warnings, %d missing diagnostics\n', ...
        cases(i).name, numel(cases(i).warnings), numel(cases(i).missing_required));
end
end

function settings = local_default_settings()
settings = struct();
settings.expected_w1_lead_s = 0.010;
settings.expected_w2_lead_s = 0.020;
settings.preview_search_min_s = -0.050;
settings.preview_search_max_s = 0.080;
settings.preview_search_step_s = 0.001;
settings.preview_min_variation_m = 1e-5;
settings.preview_tolerance_s = 0.005;
settings.event_threshold_abs_m = 1e-6;
settings.event_threshold_fraction = 0.05;
settings.event_padding_s = 0.50;
settings.az_peak_limit_g = 0.50;
settings.flat_recheck_az_limit_g = 0.01;
settings.saturation_fraction_limit = 0.01;
settings.saturation_tolerance_N = 1.0;
settings.force_limits_N = struct( ...
    'FsExt_L1', 3000, ...
    'FsExt_R1', 3000, ...
    'FsExt_L2', 2000, ...
    'FsExt_R2', 2000);
settings.hard_force_limit_N = 9000;
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
[folder, name] = fileparts(files{1});
if isempty(folder)
    folder = pwd;
end
if numel(files) == 1
    out = fullfile(folder, ['road_experiment_report_' name '.md']);
else
    out = fullfile(folder, 'road_experiment_report_compare.md');
end
end

function result = local_analyze_one(csv_file, settings)
opts = detectImportOptions(csv_file, 'VariableNamingRule', 'preserve');
T = readtable(csv_file, opts);
names = T.Properties.VariableNames;

[required, alternatives] = local_required_columns();
missing = local_missing_columns(names, required, alternatives);

time = local_column(T, 'Time');
time = time(:);
valid_time = isfinite(time);
assert(any(valid_time), 'CSV has no finite Time values: %s', csv_file);

t0 = min(time(valid_time));
t1 = max(time(valid_time));
sample_dt = local_sample_dt(time(valid_time));
full_mask = valid_time;
final_mask = valid_time & time >= (t1 - 2.0);
[event_mask, event_info] = local_event_mask(T, time, full_mask, settings);

metrics = struct();
metrics.time_start = t0;
metrics.time_end = t1;
metrics.n_rows = height(T);
metrics.sample_dt = sample_dt;
metrics.final_window_start = t1;
if any(final_mask)
    metrics.final_window_start = min(time(final_mask));
end
metrics.event = event_info;

key_cols = local_key_columns();
metrics.full = local_stats_for_columns(T, key_cols, full_mask);
metrics.final = local_stats_for_columns(T, key_cols, final_mask);
if event_info.has_event
    metrics.event_stats = local_stats_for_columns(T, key_cols, event_mask);
else
    metrics.event_stats = struct();
end
metrics.derived = local_derived_metrics(T, full_mask, final_mask, event_mask, event_info, settings);

warnings = local_make_warnings(metrics, missing, settings);

[~, name, ext] = fileparts(csv_file);
result = struct();
result.file = csv_file;
result.name = [name ext];
result.columns = names;
result.missing_required = missing;
result.metrics = metrics;
result.warnings = warnings;
end

function [required, alternatives] = local_required_columns()
required = { ...
    'Time', ...
    'Pitch','Roll','Yaw','Xo','Yo', ...
    'Az_SM','Ay_SM','Vz_SM','Steer_SW', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'Fs_L1','Fs_R1','Fs_L2','Fs_R2', ...
    'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2', ...
    'W1_L1','W1_R1','W1_L2','W1_R2', ...
    'W2_L1','W2_R1','W2_L2','W2_R2', ...
    'Rot_L1','Rot_R1','Rot_L2','Rot_R2' ...
};
alternatives = { ...
    'Vx or Vxz_Fwd', {'Vx','Vxz_Fwd'} ...
};
end

function missing = local_missing_columns(names, required, alternatives)
missing = {};
for i = 1:numel(required)
    if ~local_has_column(names, required{i})
        missing{end+1} = required{i}; %#ok<AGROW>
    end
end
for i = 1:size(alternatives, 1)
    choices = alternatives{i, 2};
    has_choice = false;
    for j = 1:numel(choices)
        has_choice = has_choice || local_has_column(names, choices{j});
    end
    if ~has_choice
        missing{end+1} = alternatives{i, 1}; %#ok<AGROW>
    end
end
end

function cols = local_key_columns()
cols = { ...
    'Pitch','Roll','Roll_E','Yaw','Xo','Yo','Vx','Vxz_Fwd','Steer_SW', ...
    'Ay_SM','Az_SM','Vz_SM', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'Fs_L1','Fs_R1','Fs_L2','Fs_R2', ...
    'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2', ...
    'W1_L1','W1_R1','W1_L2','W1_R2', ...
    'W2_L1','W2_R1','W2_L2','W2_R2', ...
    'Rot_L1','Rot_R1','Rot_L2','Rot_R2' ...
};
end

function tf = local_has_column(names, col)
tf = any(strcmp(names, col));
end

function tf = local_has_all(T, cols)
tf = true;
for i = 1:numel(cols)
    tf = tf && local_has_column(T.Properties.VariableNames, cols{i});
end
end

function x = local_column(T, col)
if local_has_column(T.Properties.VariableNames, col)
    x = T.(col);
    if iscell(x)
        x = str2double(x);
    end
    x = double(x);
else
    x = nan(height(T), 1);
end
end

function dt = local_sample_dt(time)
time = sort(time(isfinite(time)));
if numel(time) < 2
    dt = nan;
else
    d = diff(time);
    d = d(d > 0);
    if isempty(d)
        dt = nan;
    else
        dt = median(d);
    end
end
end

function [mask, info] = local_event_mask(T, time, full_mask, settings)
info = struct();
info.has_road_columns = local_has_all(T, {'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2'});
info.has_event = false;
info.start = nan;
info.stop = nan;
info.threshold_m = settings.event_threshold_abs_m;
info.road_peak_abs_m = nan;

mask = false(size(time));
if ~info.has_road_columns
    return;
end

road = [ ...
    local_column(T, 'Zgnd_L1'), local_column(T, 'Zgnd_R1'), ...
    local_column(T, 'Zgnd_L2'), local_column(T, 'Zgnd_R2') ...
];
road_abs = max(abs(road), [], 2);
info.road_peak_abs_m = local_peak_abs(road_abs);
if ~isfinite(info.road_peak_abs_m)
    return;
end

info.threshold_m = max(settings.event_threshold_abs_m, ...
    settings.event_threshold_fraction * info.road_peak_abs_m);
active = full_mask & isfinite(road_abs) & road_abs >= info.threshold_m;
if ~any(active)
    return;
end

event_start = min(time(active)) - settings.event_padding_s;
event_stop = max(time(active)) + settings.event_padding_s;
mask = full_mask & time >= event_start & time <= event_stop;
info.has_event = any(mask);
info.start = min(time(mask));
info.stop = max(time(mask));
end

function stats = local_stats_for_columns(T, cols, mask)
stats = struct();
for i = 1:numel(cols)
    col = cols{i};
    if ~local_has_column(T.Properties.VariableNames, col)
        continue;
    end
    vals = local_column(T, col);
    vals = vals(mask & isfinite(vals));
    if isempty(vals)
        continue;
    end
    s = struct();
    s.mean = mean(vals);
    s.min = min(vals);
    s.max = max(vals);
    s.rms = sqrt(mean(vals.^2));
    s.peak_abs = max(abs(vals));
    stats.(col) = s;
end
end

function derived = local_derived_metrics(T, full_mask, final_mask, event_mask, event_info, settings)
derived = struct();
time = local_column(T, 'Time');
derived.has_event = event_info.has_event;
derived.has_external_force_lr = local_has_all(T, {'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2'});
derived.has_force_lr = local_has_all(T, {'Fs_L1','Fs_R1','Fs_L2','Fs_R2'});
derived.has_road_lr = local_has_all(T, {'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2'});
derived.has_preview = local_has_all(T, {'W1_L1','W1_R1','W1_L2','W1_R2','W2_L1','W2_R1','W2_L2','W2_R2'});
derived.has_wheel_rotation = local_has_all(T, {'Rot_L1','Rot_R1','Rot_L2','Rot_R2'});
derived.has_jounce_rate_lr = local_has_all(T, {'JncR_L1','JncR_R1','JncR_L2','JncR_R2'});

if event_info.has_event
    dynamics_mask = event_mask;
else
    dynamics_mask = full_mask;
end

derived.az_peak_g = local_peak_abs(local_column(T, 'Az_SM'));
derived.az_rms_g = local_rms(local_column(T, 'Az_SM'), dynamics_mask);
derived.az_peak_m_s2 = derived.az_peak_g * 9.81;
derived.az_rms_m_s2 = derived.az_rms_g * 9.81;
derived.ay_peak_g = local_peak_abs(local_column(T, 'Ay_SM'));
derived.vz_peak = local_peak_abs(local_column(T, 'Vz_SM'));
derived.steer_peak_abs = local_peak_abs(local_column(T, 'Steer_SW'));

if derived.has_external_force_lr
    names = {'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2'};
    derived.external_force = struct();
    all_sat = [];
    all_hard_sat = [];
    for i = 1:numel(names)
        vals = local_column(T, names{i});
        lim = settings.force_limits_N.(names{i});
        sat = local_saturation_fraction(vals, lim, settings.saturation_tolerance_N);
        hard_sat = local_saturation_fraction(vals, settings.hard_force_limit_N, settings.saturation_tolerance_N);
        derived.external_force.(names{i}) = local_vector_stats(vals(dynamics_mask));
        derived.external_force.(names{i}).limit_N = lim;
        derived.external_force.(names{i}).saturation_fraction = sat;
        derived.external_force.(names{i}).hard_saturation_fraction = hard_sat;
        all_sat(end+1) = sat; %#ok<AGROW>
        all_hard_sat(end+1) = hard_sat; %#ok<AGROW>
    end
    f_l1 = local_column(T, 'FsExt_L1');
    f_r1 = local_column(T, 'FsExt_R1');
    f_l2 = local_column(T, 'FsExt_L2');
    f_r2 = local_column(T, 'FsExt_R2');
    front_diff = f_l1 - f_r1;
    rear_diff = f_l2 - f_r2;
    derived.front_external_force_lr = local_vector_stats(front_diff(dynamics_mask));
    derived.rear_external_force_lr = local_vector_stats(rear_diff(dynamics_mask));
    derived.max_external_force_saturation_fraction = max(all_sat);
    derived.max_hard_force_saturation_fraction = max(all_hard_sat);
    derived.rear_external_diff_frequency = local_dominant_frequency(time, f_l2 - f_r2, settings.fft_max_Hz);
end

if derived.has_force_lr
    fs_l1 = local_column(T, 'Fs_L1');
    fs_r1 = local_column(T, 'Fs_R1');
    fs_l2 = local_column(T, 'Fs_L2');
    fs_r2 = local_column(T, 'Fs_R2');
    front_fs_diff = fs_l1 - fs_r1;
    rear_fs_diff = fs_l2 - fs_r2;
    derived.front_force_lr = local_vector_stats(front_fs_diff(dynamics_mask));
    derived.rear_force_lr = local_vector_stats(rear_fs_diff(dynamics_mask));
end

if derived.has_jounce_rate_lr
    jr_l1 = local_column(T, 'JncR_L1');
    jr_r1 = local_column(T, 'JncR_R1');
    jr_l2 = local_column(T, 'JncR_L2');
    jr_r2 = local_column(T, 'JncR_R2');
    derived.front_jounce_rate_peak_abs = max([local_peak_abs(jr_l1(dynamics_mask)), local_peak_abs(jr_r1(dynamics_mask))]);
    derived.rear_jounce_rate_peak_abs = max([local_peak_abs(jr_l2(dynamics_mask)), local_peak_abs(jr_r2(dynamics_mask))]);
    derived.rear_jounce_rate_frequency = local_dominant_frequency(time, max(abs([jr_l2 jr_r2]), [], 2), settings.fft_max_Hz);
end

if derived.has_road_lr
    z_l1 = local_column(T, 'Zgnd_L1');
    z_r1 = local_column(T, 'Zgnd_R1');
    z_l2 = local_column(T, 'Zgnd_L2');
    z_r2 = local_column(T, 'Zgnd_R2');
    all_z = [z_l1(:); z_r1(:); z_l2(:); z_r2(:)];
    derived.road_peak_abs_m = local_peak_abs(all_z);
    front_road_diff = z_l1 - z_r1;
    rear_road_diff = z_l2 - z_r2;
    derived.front_road_lr = local_vector_stats(front_road_diff(dynamics_mask));
    derived.rear_road_lr = local_vector_stats(rear_road_diff(dynamics_mask));
end

if derived.has_preview
    derived.preview = local_preview_metrics(T, settings);
end

if derived.has_wheel_rotation
    t0 = min(time(isfinite(time)));
    t1 = max(time(isfinite(time)));
    derived.wheel_rotation_L1_delta = local_delta(T, 'Rot_L1', t0, t1, time);
    derived.wheel_rotation_R1_delta = local_delta(T, 'Rot_R1', t0, t1, time);
    derived.wheel_rotation_L2_delta = local_delta(T, 'Rot_L2', t0, t1, time);
    derived.wheel_rotation_R2_delta = local_delta(T, 'Rot_R2', t0, t1, time);
    derived.wheel_rotation_min_delta = min([ ...
        derived.wheel_rotation_L1_delta, derived.wheel_rotation_R1_delta, ...
        derived.wheel_rotation_L2_delta, derived.wheel_rotation_R2_delta ...
    ]);
end

if any(final_mask)
    derived.final_roll_mean = local_mean(local_column(T, 'Roll'), final_mask);
    derived.final_yaw_mean = local_mean(local_column(T, 'Yaw'), final_mask);
    derived.final_yo_mean = local_mean(local_column(T, 'Yo'), final_mask);
else
    derived.final_roll_mean = nan;
    derived.final_yaw_mean = nan;
    derived.final_yo_mean = nan;
end
end

function preview = local_preview_metrics(T, settings)
corners = {'L1','R1','L2','R2'};
time = local_column(T, 'Time');
preview = struct();
for i = 1:numel(corners)
    c = corners{i};
    z = local_column(T, ['Zgnd_' c]);
    w1 = local_column(T, ['W1_' c]);
    w2 = local_column(T, ['W2_' c]);
    preview.(['W1_' c]) = local_estimate_preview_lead(time, z, w1, settings.expected_w1_lead_s, settings);
    preview.(['W2_' c]) = local_estimate_preview_lead(time, z, w2, settings.expected_w2_lead_s, settings);
end
end

function est = local_estimate_preview_lead(time, road_now, road_preview, expected_lead, settings)
est = struct();
est.expected_lead_s = expected_lead;
est.estimated_lead_s = nan;
est.error_s = nan;
est.rmse_m = nan;
est.status = 'not_enough_data';

valid = isfinite(time) & isfinite(road_now) & isfinite(road_preview);
time = time(valid);
road_now = road_now(valid);
road_preview = road_preview(valid);
if numel(time) < 5
    return;
end

[time, order] = sort(time);
road_now = road_now(order);
road_preview = road_preview(order);

variation = max([local_signal_span(road_now), local_signal_span(road_preview)]);
if variation < settings.preview_min_variation_m
    est.status = 'flat_or_low_variation';
    return;
end

leads = settings.preview_search_min_s:settings.preview_search_step_s:settings.preview_search_max_s;
rmse = nan(size(leads));
for i = 1:numel(leads)
    shifted_road = interp1(time, road_now, time + leads(i), 'linear', nan);
    ok = isfinite(shifted_road) & isfinite(road_preview);
    if sum(ok) < 5
        continue;
    end
    err = road_preview(ok) - shifted_road(ok);
    rmse(i) = sqrt(mean(err.^2));
end

[best_rmse, idx] = min(rmse);
if isempty(idx) || ~isfinite(best_rmse)
    est.status = 'no_overlap';
    return;
end

est.estimated_lead_s = leads(idx);
est.error_s = est.estimated_lead_s - expected_lead;
est.rmse_m = best_rmse;
est.status = 'ok';
end

function warnings = local_make_warnings(metrics, missing, settings)
warnings = {};
for i = 1:numel(missing)
    warnings{end+1} = ['Missing diagnostic column: ' missing{i}]; %#ok<AGROW>
end

d = metrics.derived;
if isfield(d, 'steer_peak_abs') && isfinite(d.steer_peak_abs) && d.steer_peak_abs > 1e-5
    warnings{end+1} = sprintf('Steer_SW peak %.4g is not zero; road tests should stay straight-line.', d.steer_peak_abs); %#ok<AGROW>
end
if isfield(d, 'max_external_force_saturation_fraction') && ...
        d.max_external_force_saturation_fraction > settings.saturation_fraction_limit
    warnings{end+1} = sprintf('Configured FsExt saturation fraction %.4g exceeds target %.4g.', ...
        d.max_external_force_saturation_fraction, settings.saturation_fraction_limit); %#ok<AGROW>
end
if isfield(d, 'max_hard_force_saturation_fraction') && d.max_hard_force_saturation_fraction > 0
    warnings{end+1} = sprintf('Hard 9000 N FsExt saturation fraction %.4g is nonzero.', ...
        d.max_hard_force_saturation_fraction); %#ok<AGROW>
end
if isfield(d, 'wheel_rotation_min_delta') && d.wheel_rotation_min_delta <= 0
    warnings{end+1} = sprintf('Minimum wheel rotation delta %.4g rev is not positive.', d.wheel_rotation_min_delta); %#ok<AGROW>
end
if isfield(d, 'az_peak_g') && d.az_peak_g > settings.az_peak_limit_g
    warnings{end+1} = sprintf('Az_SM peak %.4g g exceeds road-test guard %.4g g.', d.az_peak_g, settings.az_peak_limit_g); %#ok<AGROW>
end
if isfield(d, 'preview')
    pnames = fieldnames(d.preview);
    sample_dt = metrics.sample_dt;
    for i = 1:numel(pnames)
        item = d.preview.(pnames{i});
        if strcmp(item.status, 'ok')
            tol = max(settings.preview_tolerance_s, 0.5 * sample_dt);
            if abs(item.error_s) > tol
                warnings{end+1} = sprintf('%s preview lead %.4g s differs from expected %.4g s by %.4g s.', ...
                    pnames{i}, item.estimated_lead_s, item.expected_lead_s, item.error_s); %#ok<AGROW>
            end
        end
    end
end
if isfield(d, 'rear_external_diff_frequency') && ...
        d.rear_external_diff_frequency.frequency_Hz >= settings.high_freq_min_Hz && ...
        d.rear_external_diff_frequency.frequency_Hz <= settings.high_freq_max_Hz && ...
        d.rear_external_diff_frequency.relative_amplitude > 0.10
    warnings{end+1} = sprintf('Rear FsExt L-R dominant frequency %.4g Hz is in the 15-20 Hz watch band.', ...
        d.rear_external_diff_frequency.frequency_Hz); %#ok<AGROW>
end
end

function comparison = local_compare_to_baseline(cases)
comparison = struct();
comparison.baseline = cases(1).name;
comparison.rows = struct([]);
for i = 2:numel(cases)
    row = struct();
    row.case_name = cases(i).name;
    row.az_peak_delta_g = cases(i).metrics.derived.az_peak_g - cases(1).metrics.derived.az_peak_g;
    row.az_rms_delta_g = cases(i).metrics.derived.az_rms_g - cases(1).metrics.derived.az_rms_g;
    row.final_roll_mean_delta_deg = cases(i).metrics.derived.final_roll_mean - cases(1).metrics.derived.final_roll_mean;
    row.final_yo_mean_delta_m = cases(i).metrics.derived.final_yo_mean - cases(1).metrics.derived.final_yo_mean;
    row.road_peak_abs_m = local_derived_scalar(cases(i), 'road_peak_abs_m');
    row.max_external_force_saturation_fraction = local_derived_scalar(cases(i), 'max_external_force_saturation_fraction');
    if isempty(comparison.rows)
        comparison.rows = row;
    else
        comparison.rows(end+1) = row; %#ok<AGROW>
    end
end
end

function val = local_derived_scalar(case_data, item)
val = nan;
if isfield(case_data.metrics.derived, item)
    val = case_data.metrics.derived.(item);
end
end

function local_write_markdown(output_markdown, cases, comparison, settings)
[folder, ~, ~] = fileparts(output_markdown);
if ~isempty(folder) && exist(folder, 'dir') == 0
    mkdir(folder);
end
fid = fopen(output_markdown, 'w', 'n', 'UTF-8');
assert(fid > 0, 'Unable to write report: %s', output_markdown);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Road Experiment Diagnostic Report\n\n');
fprintf(fid, '> Generated by `src_2020/AnalyzeRoadExperiment_2020.m`.\n\n');
fprintf(fid, 'Default configured force limits: front `%.0f N`, rear `%.0f N`.\n\n', ...
    settings.force_limits_N.FsExt_L1, settings.force_limits_N.FsExt_L2);
fprintf(fid, 'Expected preview leads: W1 `%.3f s`, W2 `%.3f s`.\n\n', ...
    settings.expected_w1_lead_s, settings.expected_w2_lead_s);

for i = 1:numel(cases)
    local_write_case(fid, cases(i));
end

if ~isempty(comparison)
    fprintf(fid, '## Baseline Comparison\n\n');
    fprintf(fid, '- Baseline: `%s`\n\n', comparison.baseline);
    fprintf(fid, '| Case | Az peak delta (g) | Az RMS delta (g) | Final Roll mean delta (deg) | Final Yo mean delta (m) | Road peak abs (m) | Max FsExt sat. |\n');
    fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:numel(comparison.rows)
        r = comparison.rows(i);
        fprintf(fid, '| `%s` | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
            r.case_name, r.az_peak_delta_g, r.az_rms_delta_g, ...
            r.final_roll_mean_delta_deg, r.final_yo_mean_delta_m, ...
            r.road_peak_abs_m, r.max_external_force_saturation_fraction);
    end
    fprintf(fid, '\n');
end
end

function local_write_case(fid, case_data)
fprintf(fid, '## `%s`\n\n', case_data.name);
fprintf(fid, '- Source: `%s`\n', case_data.file);
fprintf(fid, '- Rows: `%d`\n', case_data.metrics.n_rows);
fprintf(fid, '- Time span: `%.6g` to `%.6g` s\n', case_data.metrics.time_start, case_data.metrics.time_end);
fprintf(fid, '- Sample dt estimate: `%.6g s`\n', case_data.metrics.sample_dt);
if case_data.metrics.event.has_event
    fprintf(fid, '- Road event window: `%.6g` to `%.6g` s\n\n', ...
        case_data.metrics.event.start, case_data.metrics.event.stop);
else
    fprintf(fid, '- Road event window: none detected\n\n');
end

if isempty(case_data.missing_required)
    fprintf(fid, 'All required road diagnostics are present.\n\n');
else
    fprintf(fid, 'Missing required diagnostics:\n');
    for i = 1:numel(case_data.missing_required)
        fprintf(fid, '- `%s`\n', case_data.missing_required{i});
    end
    fprintf(fid, '\n');
end

if isempty(case_data.warnings)
    fprintf(fid, 'No road-experiment warnings were triggered.\n\n');
else
    fprintf(fid, 'Warnings:\n');
    for i = 1:numel(case_data.warnings)
        fprintf(fid, '- %s\n', case_data.warnings{i});
    end
    fprintf(fid, '\n');
end

d = case_data.metrics.derived;
fprintf(fid, 'Core derived metrics:\n\n');
fprintf(fid, '- Road peak abs across `Zgnd_*`: `%.6g m`\n', local_get_field(d, 'road_peak_abs_m'));
fprintf(fid, '- `Az_SM` peak: `%.6g g` / `%.6g m/s^2`\n', d.az_peak_g, d.az_peak_m_s2);
fprintf(fid, '- `Az_SM` RMS over event/full window: `%.6g g` / `%.6g m/s^2`\n', d.az_rms_g, d.az_rms_m_s2);
fprintf(fid, '- `Ay_SM` peak: `%.6g g`\n', d.ay_peak_g);
fprintf(fid, '- `Steer_SW` peak abs: `%.6g`\n', d.steer_peak_abs);
fprintf(fid, '- Final Roll mean: `%.6g deg`\n', d.final_roll_mean);
fprintf(fid, '- Final Yaw mean: `%.6g deg`\n', d.final_yaw_mean);
fprintf(fid, '- Final Yo mean: `%.6g m`\n', d.final_yo_mean);
if isfield(d, 'front_external_force_lr')
    fprintf(fid, '- Front `FsExt` L-R peak abs: `%.6g N`\n', d.front_external_force_lr.peak_abs);
    fprintf(fid, '- Rear `FsExt` L-R peak abs: `%.6g N`\n', d.rear_external_force_lr.peak_abs);
    fprintf(fid, '- Max configured `FsExt` saturation fraction: `%.6g`\n', d.max_external_force_saturation_fraction);
    fprintf(fid, '- Max hard 9000 N `FsExt` saturation fraction: `%.6g`\n', d.max_hard_force_saturation_fraction);
end
if isfield(d, 'rear_jounce_rate_peak_abs')
    fprintf(fid, '- Front `JncR_*` peak abs: `%.6g mm/s`\n', d.front_jounce_rate_peak_abs);
    fprintf(fid, '- Rear `JncR_*` peak abs: `%.6g mm/s`\n', d.rear_jounce_rate_peak_abs);
end
if isfield(d, 'wheel_rotation_min_delta')
    fprintf(fid, '- Wheel rotation deltas `L1/R1/L2/R2`: `%.6g`, `%.6g`, `%.6g`, `%.6g` rev\n', ...
        d.wheel_rotation_L1_delta, d.wheel_rotation_R1_delta, ...
        d.wheel_rotation_L2_delta, d.wheel_rotation_R2_delta);
    fprintf(fid, '- Minimum wheel rotation delta: `%.6g rev`\n', d.wheel_rotation_min_delta);
end
fprintf(fid, '\n');

if isfield(d, 'preview')
    fprintf(fid, 'Preview alignment:\n\n');
    fprintf(fid, '| Signal | Status | Expected lead (s) | Estimated lead (s) | Error (s) | RMSE (m) |\n');
    fprintf(fid, '|---|---|---:|---:|---:|---:|\n');
    pnames = fieldnames(d.preview);
    for i = 1:numel(pnames)
        p = d.preview.(pnames{i});
        fprintf(fid, '| `%s` | `%s` | %.6g | %.6g | %.6g | %.6g |\n', ...
            pnames{i}, p.status, p.expected_lead_s, p.estimated_lead_s, p.error_s, p.rmse_m);
    end
    fprintf(fid, '\n');
end

local_write_stats_table(fid, 'Event-window metrics', case_data.metrics.event_stats);
local_write_stats_table(fid, 'Final 2 s metrics', case_data.metrics.final);
end

function local_write_stats_table(fid, title, stats)
if isempty(fieldnames(stats))
    fprintf(fid, '%s: not available.\n\n', title);
    return;
end
cols = {'Pitch','Roll','Yaw','Yo','Ay_SM','Az_SM','Vz_SM', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2'};
fprintf(fid, '%s:\n\n', title);
fprintf(fid, '| Signal | Mean | Min | Max | RMS | Peak abs |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|\n');
for i = 1:numel(cols)
    col = cols{i};
    if isfield(stats, col)
        s = stats.(col);
        fprintf(fid, '| `%s` | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
            col, s.mean, s.min, s.max, s.rms, s.peak_abs);
    end
end
fprintf(fid, '\n');
end

function s = local_vector_stats(vals)
vals = vals(isfinite(vals));
if isempty(vals)
    vals = nan;
end
s = struct();
s.mean = mean(vals);
s.min = min(vals);
s.max = max(vals);
s.rms = sqrt(mean(vals.^2));
s.peak_abs = max(abs(vals));
end

function f = local_dominant_frequency(time, signal, max_freq)
f = struct();
f.frequency_Hz = nan;
f.relative_amplitude = nan;
valid = isfinite(time) & isfinite(signal);
time = time(valid);
signal = signal(valid);
if numel(time) < 8
    return;
end
[time, order] = sort(time);
signal = signal(order);
dt = local_sample_dt(time);
if ~isfinite(dt) || dt <= 0
    return;
end
uniform_time = (time(1):dt:time(end))';
if numel(uniform_time) < 8
    return;
end
uniform_signal = interp1(time, signal, uniform_time, 'linear', 'extrap');
uniform_signal = uniform_signal - mean(uniform_signal);
n = numel(uniform_signal);
y = abs(fft(uniform_signal));
freq = (0:n-1)' / (n * dt);
half = freq > 0 & freq <= max_freq & freq <= 0.5 / dt;
if ~any(half)
    return;
end
y_sel = y(half);
freq_sel = freq(half);
[amp, idx] = max(y_sel);
total = sum(y_sel);
if total <= 0
    return;
end
f.frequency_Hz = freq_sel(idx);
f.relative_amplitude = amp / total;
end

function frac = local_saturation_fraction(vals, limit_N, tol_N)
vals = vals(isfinite(vals));
if isempty(vals) || ~isfinite(limit_N) || limit_N <= 0
    frac = nan;
else
    frac = mean(abs(vals) >= (limit_N - tol_N));
end
end

function y = local_peak_abs(vals)
vals = vals(isfinite(vals));
if isempty(vals)
    y = nan;
else
    y = max(abs(vals));
end
end

function y = local_rms(vals, mask)
vals = vals(mask & isfinite(vals));
if isempty(vals)
    y = nan;
else
    y = sqrt(mean(vals.^2));
end
end

function y = local_mean(vals, mask)
vals = vals(mask & isfinite(vals));
if isempty(vals)
    y = nan;
else
    y = mean(vals);
end
end

function span = local_signal_span(vals)
vals = vals(isfinite(vals));
if isempty(vals)
    span = nan;
else
    span = max(vals) - min(vals);
end
end

function d = local_delta(T, col, t0, t1, time)
if ~local_has_column(T.Properties.VariableNames, col)
    d = nan;
    return;
end
vals = local_column(T, col);
[~, i0] = min(abs(time - t0));
[~, i1] = min(abs(time - t1));
d = vals(i1) - vals(i0);
end

function val = local_get_field(s, field)
if isfield(s, field)
    val = s.(field);
else
    val = nan;
end
end
