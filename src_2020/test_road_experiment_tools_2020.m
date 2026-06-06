function test_road_experiment_tools_2020()
%TEST_ROAD_EXPERIMENT_TOOLS_2020 Regression checks for road diagnostics.

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

tmp_csv = fullfile(tempdir, 'road_experiment_fixture.csv');
tmp_md = fullfile(tempdir, 'road_experiment_fixture.md');

t = (0:0.001:1.0)';
n = numel(t);
amp = 0.01;
freq_hz = 2.0;
z_now = amp * sin(2*pi*freq_hz*t);
w1 = amp * sin(2*pi*freq_hz*(t + 0.010));
w2 = amp * sin(2*pi*freq_hz*(t + 0.020));

T = table();
T.Time = t;
T.Pitch = 0.2 + zeros(n, 1);
T.Roll = 0.002 + zeros(n, 1);
T.Yaw = zeros(n, 1);
T.Xo = 13.889 * t;
T.Yo = zeros(n, 1);
T.Az_SM = 0.02 * sin(2*pi*freq_hz*t);
T.Ay_SM = zeros(n, 1);
T.Vz_SM = zeros(n, 1);
T.Vx = 50 + zeros(n, 1);
T.Steer_SW = zeros(n, 1);
T.FsExt_L1 = 3000 * (t > 0.40 & t < 0.42);
T.FsExt_R1 = zeros(n, 1);
T.FsExt_L2 = 2000 * (t > 0.50 & t < 0.52);
T.FsExt_R2 = zeros(n, 1);
T.Fs_L1 = 7600 + zeros(n, 1);
T.Fs_R1 = 7600 + zeros(n, 1);
T.Fs_L2 = 3100 + zeros(n, 1);
T.Fs_R2 = 3100 + zeros(n, 1);
T.Jnc_L1 = z_now * 1000;
T.Jnc_R1 = z_now * 1000;
T.Jnc_L2 = z_now * 1000;
T.Jnc_R2 = z_now * 1000;
T.JncR_L1 = 100 * cos(2*pi*freq_hz*t);
T.JncR_R1 = 100 * cos(2*pi*freq_hz*t);
T.JncR_L2 = 100 * cos(2*pi*freq_hz*t);
T.JncR_R2 = 100 * cos(2*pi*freq_hz*t);
T.Zgnd_L1 = z_now;
T.Zgnd_R1 = z_now;
T.Zgnd_L2 = z_now;
T.Zgnd_R2 = z_now;
T.W1_L1 = w1;
T.W1_R1 = w1;
T.W1_L2 = w1;
T.W1_R2 = w1;
T.W2_L1 = w2;
T.W2_R1 = w2;
T.W2_L2 = w2;
T.W2_R2 = w2;
T.Rot_L1 = 10 * t;
T.Rot_R1 = 10 * t;
T.Rot_L2 = 10 * t;
T.Rot_R2 = 10 * t;

writetable(T, tmp_csv);

report = AnalyzeRoadExperiment_2020(tmp_csv, tmp_md);
case_data = report.cases(1);
d = case_data.metrics.derived;

assert(isempty(case_data.missing_required), 'Expected all required road diagnostics to be present.');
assert(case_data.metrics.event.has_event, 'Expected road event window to be detected.');
assert(abs(d.preview.W1_L1.estimated_lead_s - 0.010) <= 0.001, 'Expected W1 lead near 10 ms.');
assert(abs(d.preview.W2_L1.estimated_lead_s - 0.020) <= 0.001, 'Expected W2 lead near 20 ms.');
assert(d.external_force.FsExt_L1.saturation_fraction > 0, 'Expected front saturation to be detected at 3000 N.');
assert(d.external_force.FsExt_L2.saturation_fraction > 0, 'Expected rear saturation to be detected at 2000 N.');
assert(d.wheel_rotation_min_delta > 0, 'Expected all wheel rotations to increase.');

fprintf('test_road_experiment_tools_2020 passed.\n');
end
