function test_road3_tools_2020()
%TEST_ROAD3_TOOLS_2020 Regression checks for Road-3 bump assets and reports.

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

tmp_root = fullfile(tempdir, 'road3_tools_fixture');
if exist(tmp_root, 'dir')
    rmdir(tmp_root, 's');
end
mkdir(tmp_root);

specs = generate_road3_bump_csvs_2020(tmp_root);
assert(numel(specs) == 4, 'Expected four Road-3 CSV specifications.');

t1 = local_find_spec(specs, 'Road3_T1_short_10mm_pilot');
t2 = local_find_spec(specs, 'Road3_T2_long_150mm');

local_check_bump_csv(t1.csv_file, 0.010, 0.020, 60.00, 60.20, 60.40);
local_check_bump_csv(t2.csv_file, 0.150, 0.050, 100.00, 101.25, 102.50);
assert(local_is_ascii(t1.dataset_name), 'Dataset name must be ASCII.');
assert(local_is_ascii(t2.dataset_name), 'Dataset name must be ASCII.');

[enabled, u_limit, output_scale] = empc_calibration_settings_2020('L1', 'PASSIVE_ZERO');
assert(~enabled && u_limit == 0 && output_scale == 1, 'PASSIVE_ZERO should disable the front controller at 0 N.');
[enabled, u_limit, output_scale] = empc_calibration_settings_2020('L2', 'PASSIVE_ZERO');
assert(~enabled && u_limit == 0 && output_scale == 1, 'PASSIVE_ZERO should disable the rear controller at 0 N.');

csv_passive = fullfile(tmp_root, 'passive.csv');
csv_no_preview = fullfile(tmp_root, 'no_preview.csv');
csv_preview = fullfile(tmp_root, 'preview.csv');
local_write_case(csv_passive, 0.060, 0.22);
local_write_case(csv_no_preview, 0.045, 0.17);
local_write_case(csv_preview, 0.035, 0.13);

report_file = fullfile(tmp_root, 'road3_report.md');
report = AnalyzeRoad3BumpExperiment_2020( ...
    {csv_passive, csv_no_preview, csv_preview}, report_file);

assert(exist(report_file, 'file') > 0, 'Expected Road-3 Markdown report to be written.');
assert(numel(report.cases) == 3, 'Expected three cases in Road-3 report.');
assert(report.cases(3).metrics.band.Az_SM_m_s2.rms_0_15 < report.cases(2).metrics.band.Az_SM_m_s2.rms_0_15, ...
    'Preview fixture should reduce 0-15 Hz vertical acceleration RMS versus no-preview.');
assert(report.cases(1).metrics.force.max_saturation_fraction == 0, ...
    'Synthetic passive case should not report configured force saturation.');

gap_report_file = fullfile(tmp_root, 'road3_t2_passive_gap.md');
gap_report = AnalyzeRoad3T2PassiveGap_2020(csv_passive, ...
    {csv_no_preview, csv_preview}, gap_report_file);
assert(exist(gap_report_file, 'file') > 0, 'Expected Road-3 T2 passive-gap Markdown report to be written.');
assert(numel(gap_report.comparisons) == 2, 'Expected two active-vs-passive comparisons.');
assert(isfield(gap_report.passive.metrics, 'front_jnc_min'), 'Passive summary should expose front jounce minimum.');
assert(isfield(gap_report.comparisons(1), 'phase'), 'Comparison should expose phase diagnostics.');
assert(isfield(gap_report.comparisons(1).band.Az_SM_m_s2, 'rms_2_4'), ...
    'Comparison should expose 2-4 Hz Az band RMS.');
assert(gap_report.comparisons(2).gap.Az_event_rms < 0, ...
    'Preview fixture should improve Az event RMS relative to passive.');

fprintf('test_road3_tools_2020 passed.\n');
end

function spec = local_find_spec(specs, dataset_name)
idx = find(strcmp({specs.dataset_name}, dataset_name), 1);
assert(~isempty(idx), 'Missing Road-3 spec: %s', dataset_name);
spec = specs(idx);
end

function local_check_bump_csv(csv_file, expected_peak, expected_dx, start_m, peak_m, end_m)
assert(exist(csv_file, 'file') > 0, 'Missing generated CSV: %s', csv_file);
T = readtable(csv_file, 'VariableNamingRule', 'preserve');
s = T.('Station(m)');
z = T.('elevation(m)');
assert(abs(s(2) - s(1) - expected_dx) < 1e-12, 'Unexpected station spacing in %s', csv_file);
assert(all(isfinite(s)) && all(isfinite(z)), 'CSV contains non-finite values: %s', csv_file);
assert(abs(local_value_at(s, z, start_m)) < 1e-12, 'Bump start should be zero.');
assert(abs(local_value_at(s, z, end_m)) < 1e-12, 'Bump end should be zero.');
assert(abs(local_value_at(s, z, peak_m) - expected_peak) < 1e-10, 'Unexpected bump peak height.');
end

function value = local_value_at(station, elevation, target)
[err, idx] = min(abs(station - target));
assert(err < 1e-10, 'Target station %.6f is not represented in CSV.', target);
value = elevation(idx);
end

function tf = local_is_ascii(text)
tf = all(double(char(text)) < 128);
end

function local_write_case(csv_file, az_amp_g, pitch_amp)
t = (0:0.001:2.0)';
n = numel(t);
bump = zeros(n, 1);
active = t >= 0.7 & t <= 1.0;
bump(active) = 0.05 * sin(pi * (t(active) - 0.7) / 0.3);

T = table();
T.Time = t;
T.Pitch = pitch_amp * sin(2*pi*2*t);
T.Roll = 0.002 * sin(2*pi*1.2*t);
T.Yaw = zeros(n, 1);
T.Xo = 13.889 * t;
T.Yo = zeros(n, 1);
T.Vxz_Fwd = 50 + zeros(n, 1);
T.Steer_SW = zeros(n, 1);
T.Az_SM = az_amp_g * sin(2*pi*2*t);
T.Ay_SM = zeros(n, 1);
T.Vz_SM = zeros(n, 1);
T.Zcg_SM = 0.72 + 0.01 * sin(2*pi*2*t);
T.AV_P = 2 * pitch_amp * cos(2*pi*2*t);
T.AA_P = 0.7 * sin(2*pi*2*t);
T.AV_R = 0.01 * cos(2*pi*1.2*t);
T.AA_R = 0.03 * sin(2*pi*1.2*t);
T.FsExt_L1 = 100 * sin(2*pi*2*t);
T.FsExt_R1 = 90 * sin(2*pi*2*t);
T.FsExt_L2 = 80 * sin(2*pi*2*t);
T.FsExt_R2 = 75 * sin(2*pi*2*t);
T.Fs_L1 = 7000 + zeros(n, 1);
T.Fs_R1 = 7000 + zeros(n, 1);
T.Fs_L2 = 3000 + zeros(n, 1);
T.Fs_R2 = 3000 + zeros(n, 1);
T.Jnc_L1 = 1000 * bump;
T.Jnc_R1 = 1000 * bump;
T.Jnc_L2 = 1000 * bump;
T.Jnc_R2 = 1000 * bump;
T.JncR_L1 = 100 * cos(2*pi*2*t);
T.JncR_R1 = 100 * cos(2*pi*2*t);
T.JncR_L2 = 80 * cos(2*pi*2*t);
T.JncR_R2 = 80 * cos(2*pi*2*t);
T.Zgnd_L1 = bump;
T.Zgnd_R1 = bump;
T.Zgnd_L2 = bump;
T.Zgnd_R2 = bump;
T.W1_L1 = [bump(11:end); zeros(10, 1)];
T.W1_R1 = T.W1_L1;
T.W1_L2 = T.W1_L1;
T.W1_R2 = T.W1_L1;
T.W2_L1 = [bump(21:end); zeros(20, 1)];
T.W2_R1 = T.W2_L1;
T.W2_L2 = T.W2_L1;
T.W2_R2 = T.W2_L1;
T.Rot_L1 = 10 * t;
T.Rot_R1 = 10 * t;
T.Rot_L2 = 10 * t;
T.Rot_R2 = 10 * t;

writetable(T, csv_file);
end
