function summary = AnalyzeRoadAcceptance_2020(csv_file, output_markdown, settings)
%ANALYZEROADACCEPTANCE_2020 Lightweight acceptance checks for Road-1/Road-2.
%
%   summary = AnalyzeRoadAcceptance_2020(csv_file)
%   summary = AnalyzeRoadAcceptance_2020(csv_file, output_markdown)
%
% This script is intentionally small and column-name based. It complements
% AnalyzeRoadExperiment_2020 when a quick Road-stage pass/fail summary is
% needed after manually moving CarSim CSV files.

if nargin < 1 || isempty(csv_file)
    error('csv_file is required.');
end
if nargin < 2
    output_markdown = '';
end
if nargin < 3 || isempty(settings)
    settings = local_default_settings();
else
    settings = local_merge_settings(local_default_settings(), settings);
end

T = readtable(csv_file);
vars = T.Properties.VariableNames;

summary = struct();
summary.source = char(csv_file);
summary.sample = local_sample_metrics(T);
summary.road = local_road_metrics(T, vars);
summary.preview = local_preview_metrics(T, vars);
summary.force = local_force_metrics(T, vars, settings);
summary.force_diff = local_force_diff_metrics(T, vars);
summary.dynamics = local_dynamics_metrics(T, vars);
summary.final = local_final_metrics(T, vars);
summary.derived = local_derived_metrics(T, vars);
summary.warnings = local_acceptance_warnings(summary, settings);
summary.pass = isempty(summary.warnings);

if isempty(output_markdown)
    [folder, name] = fileparts(csv_file);
    output_markdown = fullfile(folder, [name '_acceptance_report.md']);
end
local_write_markdown(output_markdown, summary, settings);
summary.output_markdown = output_markdown;

fprintf('Road acceptance report written: %s\n', output_markdown);
fprintf('Road acceptance status: %s (%d warnings)\n', ...
    local_pass_text(summary.pass), numel(summary.warnings));
end

function settings = local_default_settings()
settings = struct();
settings.expected_w1_lead_ms = 10;
settings.expected_w2_lead_ms = 20;
settings.preview_tolerance_ms = 5;
settings.saturation_fraction_limit = 0.01;
settings.saturation_tolerance_N = 1;
settings.rear_force_diff_limit_N = 1000;
settings.front_force_limit_N = 3000;
settings.rear_force_limit_N = 2000;
settings.roll_final_limit_deg = 0.02;
settings.yo_final_limit_m = 0.10;
settings.require_positive_wheel_rotation = true;
end

function out = local_merge_settings(defaults, custom)
out = defaults;
names = fieldnames(custom);
for i = 1:numel(names)
    out.(names{i}) = custom.(names{i});
end
end

function sample = local_sample_metrics(T)
sample = struct();
sample.rows = height(T);
sample.time_start_s = local_first(T, 'Time');
sample.time_end_s = local_last(T, 'Time');

t = local_col(T, 'Time');
if numel(t) >= 2
    dt = diff(t);
    sample.dt_min_s = min(dt);
    sample.dt_max_s = max(dt);
    sample.dt_mean_s = mean(dt);
else
    sample.dt_min_s = NaN;
    sample.dt_max_s = NaN;
    sample.dt_mean_s = NaN;
end

sample.station_start_m = local_first_existing(T, {'Station', 'Xo'});
sample.station_end_m = local_last_existing(T, {'Station', 'Xo'});
sample.vxz_mean = local_mean_existing(T, {'Vxz_Fwd', 'Vx'});
sample.vxz_min = local_min_existing(T, {'Vxz_Fwd', 'Vx'});
sample.vxz_max = local_max_existing(T, {'Vxz_Fwd', 'Vx'});
end

function road = local_road_metrics(T, vars)
wheels = {'L1', 'R1', 'L2', 'R2'};
road = struct();
for i = 1:numel(wheels)
    wheel = wheels{i};
    z_name = ['Zgnd_' wheel];
    if ismember(z_name, vars)
        road.(z_name) = local_stats(local_col(T, z_name));
    end
end
end

function preview = local_preview_metrics(T, vars)
wheels = {'L1', 'R1', 'L2', 'R2'};
preview = struct();
for i = 1:numel(wheels)
    wheel = wheels{i};
    z_name = ['Zgnd_' wheel];
    w1_name = ['W1_' wheel];
    w2_name = ['W2_' wheel];
    if ismember(z_name, vars) && ismember(w1_name, vars)
        preview.(w1_name) = local_peak_lead(T, z_name, w1_name);
    end
    if ismember(z_name, vars) && ismember(w2_name, vars)
        preview.(w2_name) = local_peak_lead(T, z_name, w2_name);
    end
end
end

function item = local_peak_lead(T, z_name, preview_name)
t = local_col(T, 'Time');
z = abs(local_col(T, z_name));
p = abs(local_col(T, preview_name));
[z_peak, iz] = max(z);
[p_peak, ip] = max(p);
item = struct();
item.z_peak_time_s = t(iz);
item.preview_peak_time_s = t(ip);
item.lead_ms = 1000 * (t(iz) - t(ip));
item.z_peak_m = z_peak;
item.preview_peak_m = p_peak;
end

function force = local_force_metrics(T, vars, settings)
force_names = {'FsExt_L1', 'FsExt_R1', 'FsExt_L2', 'FsExt_R2'};
force = struct();
for i = 1:numel(force_names)
    name = force_names{i};
    if ~ismember(name, vars)
        continue;
    end
    values = local_col(T, name);
    stat = local_stats(values);
    limit = local_force_limit(name, settings);
    stat.limit_N = limit;
    stat.saturation_fraction = mean(abs(values) >= (limit - settings.saturation_tolerance_N));
    force.(name) = stat;
end
end

function limit = local_force_limit(name, settings)
if contains(name, 'L1') || contains(name, 'R1')
    limit = settings.front_force_limit_N;
else
    limit = settings.rear_force_limit_N;
end
end

function force_diff = local_force_diff_metrics(T, vars)
force_diff = struct();
if all(ismember({'FsExt_L1', 'FsExt_R1'}, vars))
    force_diff.front = local_stats(local_col(T, 'FsExt_L1') - local_col(T, 'FsExt_R1'));
end
if all(ismember({'FsExt_L2', 'FsExt_R2'}, vars))
    force_diff.rear = local_stats(local_col(T, 'FsExt_L2') - local_col(T, 'FsExt_R2'));
end
end

function dynamics = local_dynamics_metrics(T, vars)
names = {'Az_SM', 'Ay_SM', 'Vz_SM', 'Roll', 'Pitch', 'Yaw', 'Yo', ...
    'JncR_L1', 'JncR_R1', 'JncR_L2', 'JncR_R2'};
dynamics = struct();
for i = 1:numel(names)
    name = names{i};
    if ismember(name, vars)
        dynamics.(name) = local_stats(local_col(T, name));
    end
end
end

function final = local_final_metrics(T, vars)
names = {'Time', 'Station', 'Xo', 'Yo', 'Roll', 'Pitch', 'Yaw', ...
    'Vxz_Fwd', 'Rot_L1', 'Rot_R1', 'Rot_L2', 'Rot_R2'};
final = struct();
for i = 1:numel(names)
    name = names{i};
    if ismember(name, vars)
        final.(name) = local_last(T, name);
    end
end
end

function derived = local_derived_metrics(T, vars)
rot_names = {'Rot_L1', 'Rot_R1', 'Rot_L2', 'Rot_R2'};
derived = struct();
derived.min_rot_delta = NaN;
if all(ismember(rot_names, vars))
    deltas = zeros(1, numel(rot_names));
    for i = 1:numel(rot_names)
        values = local_col(T, rot_names{i});
        deltas(i) = values(end) - values(1);
    end
    derived.rot_delta = deltas;
    derived.min_rot_delta = min(deltas);
end
end

function warnings = local_acceptance_warnings(summary, settings)
warnings = {};

preview_names = fieldnames(summary.preview);
for i = 1:numel(preview_names)
    name = preview_names{i};
    item = summary.preview.(name);
    if startsWith(name, 'W1_')
        expected = settings.expected_w1_lead_ms;
    else
        expected = settings.expected_w2_lead_ms;
    end
    if abs(item.lead_ms - expected) > settings.preview_tolerance_ms
        warnings{end+1} = sprintf('%s lead %.3f ms differs from expected %.3f ms.', ...
            name, item.lead_ms, expected); %#ok<AGROW>
    end
end

force_names = fieldnames(summary.force);
for i = 1:numel(force_names)
    name = force_names{i};
    item = summary.force.(name);
    if item.saturation_fraction >= settings.saturation_fraction_limit
        warnings{end+1} = sprintf('%s saturation fraction %.4f exceeds %.4f.', ...
            name, item.saturation_fraction, settings.saturation_fraction_limit); %#ok<AGROW>
    end
end

if isfield(summary.force_diff, 'rear') && ...
        summary.force_diff.rear.max_abs > settings.rear_force_diff_limit_N
    warnings{end+1} = sprintf('Rear left-right force diff %.3f N exceeds %.3f N.', ...
        summary.force_diff.rear.max_abs, settings.rear_force_diff_limit_N); %#ok<AGROW>
end

if isfield(summary.final, 'Roll') && abs(summary.final.Roll) > settings.roll_final_limit_deg
    warnings{end+1} = sprintf('Final Roll %.5f deg exceeds %.5f deg.', ...
        summary.final.Roll, settings.roll_final_limit_deg); %#ok<AGROW>
end

if isfield(summary.final, 'Yo') && abs(summary.final.Yo) > settings.yo_final_limit_m
    warnings{end+1} = sprintf('Final Yo %.5f m exceeds %.5f m.', ...
        summary.final.Yo, settings.yo_final_limit_m); %#ok<AGROW>
end

if settings.require_positive_wheel_rotation && ...
        (~isfield(summary.derived, 'min_rot_delta') || summary.derived.min_rot_delta <= 0)
    warnings{end+1} = 'Wheel rotation did not increase for all wheels.'; %#ok<AGROW>
end
end

function stat = local_stats(values)
stat = struct();
stat.min = min(values);
stat.max = max(values);
stat.mean = mean(values);
stat.max_abs = max(abs(values));
stat.rms = sqrt(mean(values.^2));
end

function values = local_col(T, name)
values = T.(name);
end

function value = local_first(T, name)
if ismember(name, T.Properties.VariableNames)
    values = local_col(T, name);
    value = values(1);
else
    value = NaN;
end
end

function value = local_last(T, name)
if ismember(name, T.Properties.VariableNames)
    values = local_col(T, name);
    value = values(end);
else
    value = NaN;
end
end

function value = local_first_existing(T, names)
value = NaN;
for i = 1:numel(names)
    if ismember(names{i}, T.Properties.VariableNames)
        value = local_first(T, names{i});
        return;
    end
end
end

function value = local_last_existing(T, names)
value = NaN;
for i = 1:numel(names)
    if ismember(names{i}, T.Properties.VariableNames)
        value = local_last(T, names{i});
        return;
    end
end
end

function value = local_mean_existing(T, names)
value = NaN;
for i = 1:numel(names)
    if ismember(names{i}, T.Properties.VariableNames)
        value = mean(local_col(T, names{i}));
        return;
    end
end
end

function value = local_min_existing(T, names)
value = NaN;
for i = 1:numel(names)
    if ismember(names{i}, T.Properties.VariableNames)
        value = min(local_col(T, names{i}));
        return;
    end
end
end

function value = local_max_existing(T, names)
value = NaN;
for i = 1:numel(names)
    if ismember(names{i}, T.Properties.VariableNames)
        value = max(local_col(T, names{i}));
        return;
    end
end
end

function text = local_pass_text(pass)
if pass
    text = 'PASS';
else
    text = 'CHECK';
end
end

function local_write_markdown(output_markdown, summary, settings)
folder = fileparts(output_markdown);
if ~isempty(folder) && exist(folder, 'dir') ~= 7
    mkdir(folder);
end

fid = fopen(output_markdown, 'w');
if fid < 0
    error('Unable to open markdown report for writing: %s', output_markdown);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Road Acceptance Report\n\n');
fprintf(fid, '- Source: `%s`\n', summary.source);
fprintf(fid, '- Status: `%s`\n', local_pass_text(summary.pass));
fprintf(fid, '- Warnings: `%d`\n\n', numel(summary.warnings));

fprintf(fid, '## Sample\n\n');
fprintf(fid, '| Metric | Value |\n|---|---:|\n');
fprintf(fid, '| Rows | %d |\n', summary.sample.rows);
fprintf(fid, '| Time start s | %.6g |\n', summary.sample.time_start_s);
fprintf(fid, '| Time end s | %.6g |\n', summary.sample.time_end_s);
fprintf(fid, '| dt min s | %.6g |\n', summary.sample.dt_min_s);
fprintf(fid, '| dt max s | %.6g |\n', summary.sample.dt_max_s);
fprintf(fid, '| Station end m | %.6g |\n', summary.sample.station_end_m);
fprintf(fid, '| Vxz mean | %.6g |\n\n', summary.sample.vxz_mean);

fprintf(fid, '## Preview Lead\n\n');
fprintf(fid, '| Signal | Lead ms | Z peak m | Preview peak m |\n|---|---:|---:|---:|\n');
preview_names = fieldnames(summary.preview);
for i = 1:numel(preview_names)
    name = preview_names{i};
    item = summary.preview.(name);
    fprintf(fid, '| %s | %.3f | %.9g | %.9g |\n', ...
        name, item.lead_ms, item.z_peak_m, item.preview_peak_m);
end
fprintf(fid, '\nExpected W1/W2 lead: %.1f / %.1f ms, tolerance %.1f ms.\n\n', ...
    settings.expected_w1_lead_ms, settings.expected_w2_lead_ms, settings.preview_tolerance_ms);

fprintf(fid, '## External Force\n\n');
fprintf(fid, '| Signal | Limit N | Min N | Max N | RMS N | Sat fraction |\n|---|---:|---:|---:|---:|---:|\n');
force_names = fieldnames(summary.force);
for i = 1:numel(force_names)
    name = force_names{i};
    item = summary.force.(name);
    fprintf(fid, '| %s | %.0f | %.3f | %.3f | %.3f | %.6f |\n', ...
        name, item.limit_N, item.min, item.max, item.rms, item.saturation_fraction);
end
fprintf(fid, '\n');

fprintf(fid, '## Force Difference\n\n');
fprintf(fid, '| Axle | Min N | Max N | Max abs N | RMS N |\n|---|---:|---:|---:|---:|\n');
if isfield(summary.force_diff, 'front')
    item = summary.force_diff.front;
    fprintf(fid, '| Front L-R | %.3f | %.3f | %.3f | %.3f |\n', ...
        item.min, item.max, item.max_abs, item.rms);
end
if isfield(summary.force_diff, 'rear')
    item = summary.force_diff.rear;
    fprintf(fid, '| Rear L-R | %.3f | %.3f | %.3f | %.3f |\n', ...
        item.min, item.max, item.max_abs, item.rms);
end
fprintf(fid, '\n');

fprintf(fid, '## Dynamics\n\n');
fprintf(fid, '| Signal | Min | Max | RMS | Max abs |\n|---|---:|---:|---:|---:|\n');
dynamics_names = fieldnames(summary.dynamics);
for i = 1:numel(dynamics_names)
    name = dynamics_names{i};
    item = summary.dynamics.(name);
    fprintf(fid, '| %s | %.6g | %.6g | %.6g | %.6g |\n', ...
        name, item.min, item.max, item.rms, item.max_abs);
end
fprintf(fid, '\n');

fprintf(fid, '## Final State\n\n');
fprintf(fid, '| Signal | Value |\n|---|---:|\n');
final_names = fieldnames(summary.final);
for i = 1:numel(final_names)
    name = final_names{i};
    fprintf(fid, '| %s | %.9g |\n', name, summary.final.(name));
end
fprintf(fid, '| min Rot delta | %.9g |\n\n', summary.derived.min_rot_delta);

fprintf(fid, '## Warnings\n\n');
if isempty(summary.warnings)
    fprintf(fid, 'None.\n');
else
    for i = 1:numel(summary.warnings)
        fprintf(fid, '- %s\n', summary.warnings{i});
    end
end
end
