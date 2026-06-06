function report = AnalyzeFlatPose_2020(csv_files, output_markdown)
%ANALYZEFLATPOSE_2020 Diagnose flat-road straight-line CarSim posture CSVs.
%
%   report = AnalyzeFlatPose_2020(csv_file)
%   report = AnalyzeFlatPose_2020({zero_force_csv, mpc_csv}, output_markdown)
%
% The parser uses CSV column names, not column order. Missing diagnostic
% columns are reported instead of causing a hard failure.

if nargin < 1 || isempty(csv_files)
    project_root = fileparts(fileparts(mfilename('fullpath')));
    csv_files = fullfile(project_root, 'Output', {'2026-06-05_12.41.17_20260605_exp1.csv',...
       '2026-06-05_13.01.16_20260605_exp_MPC.csv'...
       });
end
if nargin < 2
    output_markdown = '';
end

csv_files = local_normalize_files(csv_files);
assert(~isempty(csv_files), 'No CSV files provided.');

case_cells = cell(1, numel(csv_files));
for i = 1:numel(csv_files)
    case_cells{i} = local_analyze_one(csv_files{i});
end
cases = [case_cells{:}];

if isempty(output_markdown)
    output_markdown = local_default_report_path(csv_files);
end

comparison = [];
if numel(cases) >= 2
    comparison = local_compare_cases(cases(1), cases(2));
end

local_write_markdown(output_markdown, cases, comparison);

report = struct();
report.cases = cases;
report.comparison = comparison;
report.output_markdown = output_markdown;

fprintf('Flat-pose report written: %s\n', output_markdown);
for i = 1:numel(cases)
    fprintf('%s: %d warnings, %d missing diagnostics\n', ...
        cases(i).name, numel(cases(i).warnings), numel(cases(i).missing_required));
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
    out = fullfile(folder, ['flat_pose_report_' name '.md']);
else
    out = fullfile(folder, 'flat_pose_report_compare.md');
end
end

function result = local_analyze_one(csv_file)
opts = detectImportOptions(csv_file, 'VariableNamingRule', 'preserve');
T = readtable(csv_file, opts);
names = T.Properties.VariableNames;

[required, alternatives] = local_required_columns();
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

time = local_column(T, 'Time');
time = time(:);
valid_time = isfinite(time);
assert(any(valid_time), 'CSV has no finite Time values: %s', csv_file);
t0 = min(time(valid_time));
t1 = max(time(valid_time));
final_mask = valid_time & time >= (t1 - 2.0);
full_mask = valid_time;

metrics = struct();
metrics.time_start = t0;
metrics.time_end = t1;
metrics.n_rows = height(T);
metrics.final_window_start = max(time(final_mask));
if any(final_mask)
    metrics.final_window_start = min(time(final_mask));
end

key_cols = { ...
    'Pitch','Roll','Roll_E','Yaw','Yo','Xo','Ay_SM','Az_SM','Vz_SM','Vx','Vxz_Fwd','Steer_SW', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'Fs_L1','Fs_R1','Fs_L2','Fs_R2', ...
    'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2', ...
    'Rot_L1','Rot_R1','Rot_L2','Rot_R2' ...
};
metrics.full = local_stats_for_columns(T, key_cols, full_mask);
metrics.final = local_stats_for_columns(T, key_cols, final_mask);
metrics.derived = local_derived_metrics(T, final_mask, t0, t1);

warnings = local_make_warnings(metrics, missing);

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
    'Az_SM','Vz_SM','Ay_SM','Steer_SW', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'Fs_L1','Fs_R1','Fs_L2','Fs_R2', ...
    'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2', ...
    'Rot_L1','Rot_R1','Rot_L2','Rot_R2' ...
};
alternatives = { ...
    'Vx or Vxz_Fwd', {'Vx','Vxz_Fwd'} ...
};
end

function tf = local_has_column(names, col)
tf = any(strcmp(names, col));
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

function derived = local_derived_metrics(T, mask, t0, t1)
derived = struct();
derived.has_external_force_lr = local_has_all(T, {'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2'});
derived.has_force_lr = local_has_all(T, {'Fs_L1','Fs_R1','Fs_L2','Fs_R2'});
derived.has_jounce_lr = local_has_all(T, {'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2'});
derived.has_jounce_rate_lr = local_has_all(T, {'JncR_L1','JncR_R1','JncR_L2','JncR_R2'});
derived.has_road_lr = local_has_all(T, {'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2'});
derived.has_wheel_rotation = local_has_all(T, {'Rot_L1','Rot_R1','Rot_L2','Rot_R2'});

if derived.has_external_force_lr
    fext_l1 = local_column(T, 'FsExt_L1');
    fext_r1 = local_column(T, 'FsExt_R1');
    fext_l2 = local_column(T, 'FsExt_L2');
    fext_r2 = local_column(T, 'FsExt_R2');
    derived.front_external_force_lr = local_vector_stats(fext_l1(mask) - fext_r1(mask));
    derived.rear_external_force_lr = local_vector_stats(fext_l2(mask) - fext_r2(mask));
    all_fext = [fext_l1(:); fext_r1(:); fext_l2(:); fext_r2(:)];
    valid_fext = all_fext(isfinite(all_fext));
    derived.external_force_saturation_fraction = mean(abs(valid_fext) >= 8999);
    names = {'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2'};
    derived.external_force_saturation = struct();
    for i = 1:numel(names)
        vals = local_column(T, names{i});
        vals = vals(isfinite(vals));
        derived.external_force_saturation.(names{i}) = mean(abs(vals) >= 8999);
    end
end

if derived.has_force_lr
    fs_l1 = local_column(T, 'Fs_L1');
    fs_r1 = local_column(T, 'Fs_R1');
    fs_l2 = local_column(T, 'Fs_L2');
    fs_r2 = local_column(T, 'Fs_R2');
    derived.front_force_lr = local_vector_stats(fs_l1(mask) - fs_r1(mask));
    derived.rear_force_lr = local_vector_stats(fs_l2(mask) - fs_r2(mask));
    all_fs = [fs_l1(:); fs_r1(:); fs_l2(:); fs_r2(:)];
    derived.force_saturation_fraction = mean(abs(all_fs(isfinite(all_fs))) > 8900);
end

if derived.has_jounce_lr
    j_l1 = local_column(T, 'Jnc_L1');
    j_r1 = local_column(T, 'Jnc_R1');
    j_l2 = local_column(T, 'Jnc_L2');
    j_r2 = local_column(T, 'Jnc_R2');
    derived.front_jounce_lr = local_vector_stats(j_l1(mask) - j_r1(mask));
    derived.rear_jounce_lr = local_vector_stats(j_l2(mask) - j_r2(mask));
end

if derived.has_jounce_rate_lr
    jr_l1 = local_column(T, 'JncR_L1');
    jr_r1 = local_column(T, 'JncR_R1');
    jr_l2 = local_column(T, 'JncR_L2');
    jr_r2 = local_column(T, 'JncR_R2');
    derived.front_jounce_rate_lr = local_vector_stats(jr_l1(mask) - jr_r1(mask));
    derived.rear_jounce_rate_lr = local_vector_stats(jr_l2(mask) - jr_r2(mask));
    derived.front_jounce_rate_peak_abs = max([local_peak_abs(jr_l1), local_peak_abs(jr_r1)]);
    derived.rear_jounce_rate_peak_abs = max([local_peak_abs(jr_l2), local_peak_abs(jr_r2)]);
end

if derived.has_road_lr
    z_l1 = local_column(T, 'Zgnd_L1');
    z_r1 = local_column(T, 'Zgnd_R1');
    z_l2 = local_column(T, 'Zgnd_L2');
    z_r2 = local_column(T, 'Zgnd_R2');
    derived.front_road_lr = local_vector_stats(z_l1(mask) - z_r1(mask));
    derived.rear_road_lr = local_vector_stats(z_l2(mask) - z_r2(mask));
    all_z = [z_l1(:); z_r1(:); z_l2(:); z_r2(:)];
    derived.road_flat_peak_abs = local_peak_abs(all_z);
end

if derived.has_wheel_rotation
    time = local_column(T, 'Time');
    derived.wheel_rotation_L1_delta = local_delta(T, 'Rot_L1', t0, t1, time);
    derived.wheel_rotation_R1_delta = local_delta(T, 'Rot_R1', t0, t1, time);
    derived.wheel_rotation_L2_delta = local_delta(T, 'Rot_L2', t0, t1, time);
    derived.wheel_rotation_R2_delta = local_delta(T, 'Rot_R2', t0, t1, time);
    derived.wheel_rotation_min_delta = min([ ...
        derived.wheel_rotation_L1_delta, derived.wheel_rotation_R1_delta, ...
        derived.wheel_rotation_L2_delta, derived.wheel_rotation_R2_delta ...
    ]);
end

time = local_column(T, 'Time');
derived.yo_delta = local_delta(T, 'Yo', t0, t1, time);
derived.yaw_delta = local_delta(T, 'Yaw', t0, t1, time);
derived.roll_delta = local_delta(T, 'Roll', t0, t1, time);
derived.pitch_delta = local_delta(T, 'Pitch', t0, t1, time);
derived.steer_peak_abs = local_peak_abs(local_column(T, 'Steer_SW'));
end

function tf = local_has_all(T, cols)
tf = true;
for i = 1:numel(cols)
    tf = tf && local_has_column(T.Properties.VariableNames, cols{i});
end
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

function y = local_peak_abs(vals)
vals = vals(isfinite(vals));
if isempty(vals)
    y = nan;
else
    y = max(abs(vals));
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

function warnings = local_make_warnings(metrics, missing)
warnings = {};
for i = 1:numel(missing)
    warnings{end+1} = ['Missing diagnostic column: ' missing{i}]; %#ok<AGROW>
end

final = metrics.final;
derived = metrics.derived;

warnings = local_threshold_warning(warnings, final, 'Roll', 'peak_abs', 0.2, ...
    'Final 2 s Roll peak exceeds flat-road target 0.2 deg.');
warnings = local_threshold_warning(warnings, final, 'Roll', 'mean', 0.02, ...
    'Final 2 s Roll mean exceeds flat-road target 0.02 deg.');
warnings = local_threshold_warning(warnings, final, 'Yaw', 'peak_abs', 0.2, ...
    'Final 2 s Yaw peak exceeds straight-line target 0.2 deg.');

if isfinite(derived.yo_delta) && abs(derived.yo_delta) > 0.05
    warnings{end+1} = sprintf('Yo drift %.4g m exceeds straight-line target 0.05 m.', derived.yo_delta); %#ok<AGROW>
end
if isfield(final, 'Ay_SM') && final.Ay_SM.peak_abs > 0.02
    warnings{end+1} = sprintf('Final 2 s Ay_SM peak %.4g exceeds 0.02; check if road case is still maneuvering.', final.Ay_SM.peak_abs); %#ok<AGROW>
end
if isfield(metrics.full, 'Az_SM') && metrics.full.Az_SM.peak_abs > 0.05
    warnings{end+1} = sprintf('Full-run Az_SM peak %.4g g exceeds flat-road target 0.05 g.', metrics.full.Az_SM.peak_abs); %#ok<AGROW>
end
if isfield(derived, 'road_flat_peak_abs') && derived.road_flat_peak_abs > 1e-6
    warnings{end+1} = sprintf('Road height peak %.4g m exceeds flat-road target 1e-6 m.', derived.road_flat_peak_abs); %#ok<AGROW>
end
if isfield(derived, 'steer_peak_abs') && derived.steer_peak_abs > 1e-5
    warnings{end+1} = sprintf('Steer_SW peak %.4g is not zero for the flat straight-line case.', derived.steer_peak_abs); %#ok<AGROW>
end
if isfield(derived, 'external_force_saturation_fraction') && derived.external_force_saturation_fraction > 0.01
    warnings{end+1} = sprintf('FsExt saturation fraction %.4g exceeds target 0.01.', derived.external_force_saturation_fraction); %#ok<AGROW>
end
if isfield(derived, 'external_force_saturation')
    sat_names = fieldnames(derived.external_force_saturation);
    for i = 1:numel(sat_names)
        sat_val = derived.external_force_saturation.(sat_names{i});
        if isfinite(sat_val) && sat_val > 0.01
            warnings{end+1} = sprintf('%s saturation fraction %.4g exceeds target 0.01.', sat_names{i}, sat_val); %#ok<AGROW>
        end
    end
end
if isfield(derived, 'rear_external_force_lr') && derived.rear_external_force_lr.peak_abs > 1000
    warnings{end+1} = sprintf('Rear FsExt L-R peak %.4g N exceeds target 1000 N.', derived.rear_external_force_lr.peak_abs); %#ok<AGROW>
end
if isfield(derived, 'rear_jounce_rate_peak_abs') && derived.rear_jounce_rate_peak_abs > 50
    warnings{end+1} = sprintf('Rear JncR peak %.4g mm/s exceeds target 50 mm/s.', derived.rear_jounce_rate_peak_abs); %#ok<AGROW>
end
if isfield(derived, 'wheel_rotation_min_delta') && derived.wheel_rotation_min_delta <= 0
    warnings{end+1} = sprintf('Minimum wheel rotation delta %.4g rev is not positive.', derived.wheel_rotation_min_delta); %#ok<AGROW>
end
if isfield(derived, 'front_force_lr') && abs(derived.front_force_lr.mean) > 100
    warnings{end+1} = sprintf('Front built-in Fs L-R mean %.4g N exceeds 100 N.', derived.front_force_lr.mean); %#ok<AGROW>
end
if isfield(derived, 'rear_force_lr') && abs(derived.rear_force_lr.mean) > 100
    warnings{end+1} = sprintf('Rear built-in Fs L-R mean %.4g N exceeds 100 N.', derived.rear_force_lr.mean); %#ok<AGROW>
end
end

function warnings = local_threshold_warning(warnings, stats, col, field, limit_abs, message)
if isfield(stats, col) && isfield(stats.(col), field)
    val = stats.(col).(field);
    if abs(val) > limit_abs
        warnings{end+1} = sprintf('%s value=%.4g', message, val); %#ok<AGROW>
    end
end
end

function comparison = local_compare_cases(case_a, case_b)
comparison = struct();
comparison.case_a = case_a.name;
comparison.case_b = case_b.name;
comparison.notes = {};

comparison.roll_peak_delta = local_metric(case_b, 'Roll', 'peak_abs') - local_metric(case_a, 'Roll', 'peak_abs');
comparison.roll_mean_delta = local_metric(case_b, 'Roll', 'mean') - local_metric(case_a, 'Roll', 'mean');
comparison.yo_final_mean_delta = local_metric(case_b, 'Yo', 'mean') - local_metric(case_a, 'Yo', 'mean');
comparison.yo_drift_delta = case_b.metrics.derived.yo_delta - case_a.metrics.derived.yo_delta;
comparison.az_peak_delta = local_full_metric(case_b, 'Az_SM', 'peak_abs') - local_full_metric(case_a, 'Az_SM', 'peak_abs');
comparison.front_force_lr_mean_delta = local_derived_metric(case_b, 'front_force_lr', 'mean') - local_derived_metric(case_a, 'front_force_lr', 'mean');
comparison.rear_force_lr_mean_delta = local_derived_metric(case_b, 'rear_force_lr', 'mean') - local_derived_metric(case_a, 'rear_force_lr', 'mean');
comparison.front_external_force_lr_peak_b = local_derived_metric(case_b, 'front_external_force_lr', 'peak_abs');
comparison.rear_external_force_lr_peak_b = local_derived_metric(case_b, 'rear_external_force_lr', 'peak_abs');
comparison.external_force_saturation_b = local_derived_scalar(case_b, 'external_force_saturation_fraction');
comparison.road_flat_peak_b = local_derived_scalar(case_b, 'road_flat_peak_abs');
comparison.steer_peak_b = local_derived_scalar(case_b, 'steer_peak_abs');
comparison.rear_jounce_rate_peak_b = local_derived_scalar(case_b, 'rear_jounce_rate_peak_abs');
comparison.wheel_rotation_min_delta_b = local_derived_scalar(case_b, 'wheel_rotation_min_delta');

if isfinite(comparison.roll_peak_delta) && comparison.roll_peak_delta > 0.2
    comparison.notes{end+1} = 'MPC case increases final Roll peak by more than 0.2 deg.';
end
if isfinite(comparison.yo_final_mean_delta) && abs(comparison.yo_final_mean_delta) > 0.1
    comparison.notes{end+1} = 'MPC case changes final Yo mean by more than 0.1 m.';
end
if isfinite(comparison.rear_external_force_lr_peak_b) && comparison.rear_external_force_lr_peak_b > 1000
    comparison.notes{end+1} = 'MPC case rear FsExt L-R peak exceeds 1000 N.';
end
if isfinite(comparison.external_force_saturation_b) && comparison.external_force_saturation_b > 0.01
    comparison.notes{end+1} = 'MPC case FsExt saturation fraction exceeds 1%.';
end
if isfinite(comparison.az_peak_delta) && comparison.az_peak_delta > 0.05
    comparison.notes{end+1} = 'MPC case increases Az_SM peak by more than 0.05 g.';
end
if isfinite(comparison.wheel_rotation_min_delta_b) && comparison.wheel_rotation_min_delta_b <= 0
    comparison.notes{end+1} = 'MPC case has at least one non-increasing Rot_* signal.';
end
end

function val = local_metric(case_data, col, field)
val = nan;
if isfield(case_data.metrics.final, col) && isfield(case_data.metrics.final.(col), field)
    val = case_data.metrics.final.(col).(field);
end
end

function val = local_full_metric(case_data, col, field)
val = nan;
if isfield(case_data.metrics.full, col) && isfield(case_data.metrics.full.(col), field)
    val = case_data.metrics.full.(col).(field);
end
end

function val = local_derived_metric(case_data, item, field)
val = nan;
if isfield(case_data.metrics.derived, item) && isfield(case_data.metrics.derived.(item), field)
    val = case_data.metrics.derived.(item).(field);
end
end

function val = local_derived_scalar(case_data, item)
val = nan;
if isfield(case_data.metrics.derived, item)
    val = case_data.metrics.derived.(item);
end
end

function local_write_markdown(output_markdown, cases, comparison)
[folder, ~, ~] = fileparts(output_markdown);
if ~isempty(folder) && exist(folder, 'dir') == 0
    mkdir(folder);
end
fid = fopen(output_markdown, 'w', 'n', 'UTF-8');
assert(fid > 0, 'Unable to write report: %s', output_markdown);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Flat-Road Posture Diagnostic Report\n\n');
fprintf(fid, '> Generated by `src_2020/AnalyzeFlatPose_2020.m`.\n\n');

for i = 1:numel(cases)
    local_write_case(fid, cases(i));
end

if ~isempty(comparison)
    fprintf(fid, '## Case Comparison\n\n');
    fprintf(fid, '- Case A: `%s`\n', comparison.case_a);
    fprintf(fid, '- Case B: `%s`\n', comparison.case_b);
    fprintf(fid, '- Final Roll peak delta B-A: `%.6g deg`\n', comparison.roll_peak_delta);
    fprintf(fid, '- Final Roll mean delta B-A: `%.6g deg`\n', comparison.roll_mean_delta);
    fprintf(fid, '- Final Yo mean delta B-A: `%.6g m`\n', comparison.yo_final_mean_delta);
    fprintf(fid, '- Yo drift delta B-A: `%.6g m`\n', comparison.yo_drift_delta);
    fprintf(fid, '- Full-run Az_SM peak delta B-A: `%.6g g`\n', comparison.az_peak_delta);
    fprintf(fid, '- Front built-in Fs L-R mean delta B-A: `%.6g N`\n', comparison.front_force_lr_mean_delta);
    fprintf(fid, '- Rear built-in Fs L-R mean delta B-A: `%.6g N`\n', comparison.rear_force_lr_mean_delta);
    fprintf(fid, '- Case B front FsExt L-R peak: `%.6g N`\n', comparison.front_external_force_lr_peak_b);
    fprintf(fid, '- Case B rear FsExt L-R peak: `%.6g N`\n', comparison.rear_external_force_lr_peak_b);
    fprintf(fid, '- Case B FsExt saturation fraction: `%.6g`\n', comparison.external_force_saturation_b);
    fprintf(fid, '- Case B road height peak abs: `%.6g m`\n', comparison.road_flat_peak_b);
    fprintf(fid, '- Case B Steer_SW peak abs: `%.6g`\n', comparison.steer_peak_b);
    fprintf(fid, '- Case B rear JncR peak abs: `%.6g mm/s`\n', comparison.rear_jounce_rate_peak_b);
    fprintf(fid, '- Case B minimum Rot_* delta: `%.6g rev`\n\n', comparison.wheel_rotation_min_delta_b);
    if isempty(comparison.notes)
        fprintf(fid, 'No comparison warnings were triggered.\n\n');
    else
        fprintf(fid, 'Comparison warnings:\n');
        for i = 1:numel(comparison.notes)
            fprintf(fid, '- %s\n', comparison.notes{i});
        end
        fprintf(fid, '\n');
    end
end
end

function local_write_case(fid, case_data)
fprintf(fid, '## `%s`\n\n', case_data.name);
fprintf(fid, '- Source: `%s`\n', case_data.file);
fprintf(fid, '- Rows: `%d`\n', case_data.metrics.n_rows);
fprintf(fid, '- Time span: `%.6g` to `%.6g` s\n', case_data.metrics.time_start, case_data.metrics.time_end);
fprintf(fid, '- Final window: `%.6g` to `%.6g` s\n\n', case_data.metrics.final_window_start, case_data.metrics.time_end);

if isempty(case_data.missing_required)
    fprintf(fid, 'All required diagnostic columns are present.\n\n');
else
    fprintf(fid, 'Missing required diagnostics:\n');
    for i = 1:numel(case_data.missing_required)
        fprintf(fid, '- `%s`\n', case_data.missing_required{i});
    end
    fprintf(fid, '\n');
end

if isempty(case_data.warnings)
    fprintf(fid, 'No flat-posture warnings were triggered.\n\n');
else
    fprintf(fid, 'Warnings:\n');
    for i = 1:numel(case_data.warnings)
        fprintf(fid, '- %s\n', case_data.warnings{i});
    end
    fprintf(fid, '\n');
end

fprintf(fid, 'Final 2 s metrics:\n\n');
fprintf(fid, '| Signal | Mean | Min | Max | RMS | Peak abs |\n');
fprintf(fid, '|---|---:|---:|---:|---:|---:|\n');
cols = {'Pitch','Roll','Roll_E','Yaw','Yo','Ay_SM','Az_SM','Vz_SM','Vx','Vxz_Fwd','Steer_SW', ...
    'FsExt_L1','FsExt_R1','FsExt_L2','FsExt_R2', ...
    'Fs_L1','Fs_R1','Fs_L2','Fs_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2'};
for i = 1:numel(cols)
    col = cols{i};
    if isfield(case_data.metrics.final, col)
        s = case_data.metrics.final.(col);
        fprintf(fid, '| `%s` | %.6g | %.6g | %.6g | %.6g | %.6g |\n', ...
            col, s.mean, s.min, s.max, s.rms, s.peak_abs);
    end
end
fprintf(fid, '\n');

d = case_data.metrics.derived;
fprintf(fid, 'Derived final-window checks:\n\n');
fprintf(fid, '- `Yo` end-start drift: `%.6g m`\n', d.yo_delta);
fprintf(fid, '- `Yaw` end-start drift: `%.6g deg`\n', d.yaw_delta);
fprintf(fid, '- `Roll` end-start drift: `%.6g deg`\n', d.roll_delta);
fprintf(fid, '- `Pitch` end-start drift: `%.6g deg`\n', d.pitch_delta);
if isfield(d, 'steer_peak_abs')
    fprintf(fid, '- `Steer_SW` peak abs: `%.6g`\n', d.steer_peak_abs);
end
if isfield(d, 'road_flat_peak_abs')
    fprintf(fid, '- Road height peak abs across `Zgnd_*`: `%.6g m`\n', d.road_flat_peak_abs);
end
if isfield(d, 'front_external_force_lr')
    fprintf(fid, '- Front `FsExt` L-R mean: `%.6g N`, peak abs: `%.6g N`\n', d.front_external_force_lr.mean, d.front_external_force_lr.peak_abs);
    fprintf(fid, '- Rear `FsExt` L-R mean: `%.6g N`, peak abs: `%.6g N`\n', d.rear_external_force_lr.mean, d.rear_external_force_lr.peak_abs);
    fprintf(fid, '- `FsExt` saturation fraction `abs(FsExt)>=8999`: `%.6g`\n', d.external_force_saturation_fraction);
    sat_names = fieldnames(d.external_force_saturation);
    for i = 1:numel(sat_names)
        fprintf(fid, '- `%s` saturation fraction: `%.6g`\n', sat_names{i}, d.external_force_saturation.(sat_names{i}));
    end
end
if isfield(d, 'front_force_lr')
    fprintf(fid, '- Front built-in `Fs` L-R mean: `%.6g N`, peak abs: `%.6g N`\n', d.front_force_lr.mean, d.front_force_lr.peak_abs);
    fprintf(fid, '- Rear built-in `Fs` L-R mean: `%.6g N`, peak abs: `%.6g N`\n', d.rear_force_lr.mean, d.rear_force_lr.peak_abs);
    fprintf(fid, '- Built-in `Fs` saturation fraction `abs(Fs)>8900`: `%.6g`\n', d.force_saturation_fraction);
end
if isfield(d, 'front_jounce_lr')
    fprintf(fid, '- Front jounce L-R mean: `%.6g`, peak abs: `%.6g`\n', d.front_jounce_lr.mean, d.front_jounce_lr.peak_abs);
    fprintf(fid, '- Rear jounce L-R mean: `%.6g`, peak abs: `%.6g`\n', d.rear_jounce_lr.mean, d.rear_jounce_lr.peak_abs);
end
if isfield(d, 'front_jounce_rate_lr')
    fprintf(fid, '- Front jounce-rate L-R mean: `%.6g mm/s`, peak abs: `%.6g mm/s`\n', d.front_jounce_rate_lr.mean, d.front_jounce_rate_lr.peak_abs);
    fprintf(fid, '- Rear jounce-rate L-R mean: `%.6g mm/s`, peak abs: `%.6g mm/s`\n', d.rear_jounce_rate_lr.mean, d.rear_jounce_rate_lr.peak_abs);
    fprintf(fid, '- Rear `JncR_*` peak abs: `%.6g mm/s`\n', d.rear_jounce_rate_peak_abs);
end
if isfield(d, 'front_road_lr')
    fprintf(fid, '- Front road L-R mean: `%.6g`, peak abs: `%.6g`\n', d.front_road_lr.mean, d.front_road_lr.peak_abs);
    fprintf(fid, '- Rear road L-R mean: `%.6g`, peak abs: `%.6g`\n', d.rear_road_lr.mean, d.rear_road_lr.peak_abs);
end
if isfield(d, 'wheel_rotation_min_delta')
    fprintf(fid, '- Wheel rotation deltas `L1/R1/L2/R2`: `%.6g`, `%.6g`, `%.6g`, `%.6g` rev\n', ...
        d.wheel_rotation_L1_delta, d.wheel_rotation_R1_delta, d.wheel_rotation_L2_delta, d.wheel_rotation_R2_delta);
    fprintf(fid, '- Minimum wheel rotation delta: `%.6g rev`\n', d.wheel_rotation_min_delta);
end
fprintf(fid, '\n');
end
