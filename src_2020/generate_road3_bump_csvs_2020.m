function specs = generate_road3_bump_csvs_2020(output_dir)
%GENERATE_ROAD3_BUMP_CSVS_2020 Generate Road-3 paper speed-bump CSV files.
%
% Road-3 uses half-sine speed bumps from Theunissen et al.:
% Test 1: 5 cm height, 0.4 m length, approximately 30 km/h.
% Test 2: 15 cm height, 2.5 m length, approximately 50 km/h.

if nargin < 1 || isempty(output_dir)
    project_root = fileparts(fileparts(mfilename('fullpath')));
    output_dir = fullfile(project_root, 'Carsim参数集', '3D路况文件');
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

specs = local_specs(output_dir);
for i = 1:numel(specs)
    local_write_csv(specs(i));
end

fprintf('Generated %d Road-3 bump CSV files in %s\n', numel(specs), output_dir);
end

function specs = local_specs(output_dir)
road_end_m = 210.0;
items = { ...
    'Road3_T1_short_10mm_pilot', 0.010, 0.40, 60.00, 0.02, 30, 'Road3_T1_short_10mm_pilot_210m_0p02m.csv'; ...
    'Road3_T1_short_50mm',       0.050, 0.40, 60.00, 0.02, 30, 'Road3_T1_short_50mm_210m_0p02m.csv'; ...
    'Road3_T2_long_50mm_pilot',  0.050, 2.50, 100.00, 0.05, 50, 'Road3_T2_long_50mm_pilot_210m_0p05m.csv'; ...
    'Road3_T2_long_150mm',       0.150, 2.50, 100.00, 0.05, 50, 'Road3_T2_long_150mm_210m_0p05m.csv' ...
};

specs = repmat(struct( ...
    'dataset_name', '', ...
    'height_m', 0, ...
    'length_m', 0, ...
    'start_m', 0, ...
    'end_m', 0, ...
    'peak_station_m', 0, ...
    'dx_m', 0, ...
    'speed_km_h', 0, ...
    'road_end_m', road_end_m, ...
    'csv_file', ''), size(items, 1), 1);

for i = 1:size(items, 1)
    specs(i).dataset_name = items{i, 1};
    specs(i).height_m = items{i, 2};
    specs(i).length_m = items{i, 3};
    specs(i).start_m = items{i, 4};
    specs(i).end_m = items{i, 4} + items{i, 3};
    specs(i).peak_station_m = items{i, 4} + 0.5 * items{i, 3};
    specs(i).dx_m = items{i, 5};
    specs(i).speed_km_h = items{i, 6};
    specs(i).csv_file = fullfile(output_dir, items{i, 7});
end
end

function local_write_csv(spec)
station = (0:spec.dx_m:spec.road_end_m)';
elevation = zeros(size(station));

in_bump = station >= spec.start_m & station <= spec.end_m;
phase = (station(in_bump) - spec.start_m) ./ spec.length_m;
elevation(in_bump) = spec.height_m * sin(pi * phase);

% Force exact zeros and peak values at key stations to avoid tiny sin(pi)
% roundoff values from being interpreted as non-flat by CarSim.
elevation(abs(station - spec.start_m) < 10*eps) = 0;
elevation(abs(station - spec.end_m) < 10*eps) = 0;
elevation(abs(station - spec.peak_station_m) < 10*eps) = spec.height_m;

fid = fopen(spec.csv_file, 'w');
assert(fid > 0, 'Unable to open Road-3 CSV for writing: %s', spec.csv_file);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Station(m),elevation(m)\n');
for i = 1:numel(station)
    fprintf(fid, '%.2f,%.9f\n', station(i), elevation(i));
end
delete(cleanup);
end
