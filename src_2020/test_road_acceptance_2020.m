function test_road_acceptance_2020()
%TEST_ROAD_ACCEPTANCE_2020 Regression checks for road acceptance summaries.

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

tmp_csv = fullfile(tempdir, 'road_acceptance_fixture.csv');
tmp_md = fullfile(tempdir, 'road_acceptance_fixture.md');

t = (0:0.001:1.0)';
n = numel(t);
z = 0.005 * exp(-((t - 0.50) / 0.06).^2);
w1 = 0.005 * exp(-((t + 0.010 - 0.50) / 0.06).^2);
w2 = 0.005 * exp(-((t + 0.020 - 0.50) / 0.06).^2);

T = table();
T.Time = t;
T.Station = 13.889 * t;
T.Xo = T.Station;
T.Yo = 0.01 * t;
T.Vxz_Fwd = 50 + zeros(n, 1);
T.Pitch = 0.24 + 0.01 * z / max(z);
T.Roll = 0.002 + zeros(n, 1);
T.Yaw = -0.01 * t;
T.Az_SM = 0.1 * z / max(z);
T.Ay_SM = zeros(n, 1);
T.Vz_SM = 0.02 * sin(2*pi*2*t);

T.FsExt_L1 = 1000 * z / max(z);
T.FsExt_R1 = 980 * z / max(z);
T.FsExt_L2 = 300 * z / max(z);
T.FsExt_R2 = 305 * z / max(z);
T.JncR_L1 = 50 * z / max(z);
T.JncR_R1 = 51 * z / max(z);
T.JncR_L2 = 30 * z / max(z);
T.JncR_R2 = 31 * z / max(z);

for name = ["L1", "R1", "L2", "R2"]
    T.("Zgnd_" + name) = z;
    T.("W1_" + name) = w1;
    T.("W2_" + name) = w2;
    T.("Rot_" + name) = 20 * t;
end

writetable(T, tmp_csv);

summary = AnalyzeRoadAcceptance_2020(tmp_csv, tmp_md);

assert(summary.sample.rows == n, 'Unexpected row count.');
assert(abs(summary.preview.W1_L1.lead_ms - 10) <= 1, 'Expected W1 lead near 10 ms.');
assert(abs(summary.preview.W2_L1.lead_ms - 20) <= 1, 'Expected W2 lead near 20 ms.');
assert(summary.force.FsExt_L1.saturation_fraction == 0, 'Unexpected front saturation.');
assert(summary.force.FsExt_L2.saturation_fraction == 0, 'Unexpected rear saturation.');
assert(summary.derived.min_rot_delta > 0, 'Expected all wheel rotations to increase.');
assert(exist(tmp_md, 'file') == 2, 'Expected markdown report to be written.');

fprintf('test_road_acceptance_2020 passed.\n');
end
