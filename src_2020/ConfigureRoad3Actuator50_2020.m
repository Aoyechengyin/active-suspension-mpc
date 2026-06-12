function backup_file = ConfigureRoad3Actuator50_2020(varargin)
%CONFIGUREROAD3ACTUATOR50_2020 Insert paper actuator dynamics into Road-3 model.
%
%   backup_file = ConfigureRoad3Actuator50_2020('apply', true)
%   updates src_2020/untitled_2020.slx in place after creating a timestamped
%   backup. The script inserts a tau=0.05 s first-order actuator before each
%   IMP_FS output and reconnects the controller u_prev input to the delayed
%   actuator output.
%
%   ConfigureRoad3Actuator50_2020('apply', false) performs structural checks
%   only.

options = local_parse_inputs(varargin{:});
root_dir = fileparts(mfilename('fullpath'));
model_file = fullfile(root_dir, 'untitled_2020.slx');
assert(exist(model_file, 'file') > 0, 'Model file missing: %s', model_file);

model_name = 'untitled_2020';
load_system(model_file);
cleanup = onCleanup(@() bdclose(model_name));

set_param(model_name, 'Solver', 'ode4', 'FixedStep', sprintf('%.3f', options.dt_s));

backup_file = '';
if options.apply
    backup_file = local_backup_model(model_file);
    local_insert_all_actuators(model_name, options);
    local_disable_mux_path_negative_gains(model_name);
    save_system(model_name, model_file);
end

local_check_actuator_structure(model_name, options);

if options.apply
    fprintf('Road-3 ACT50 actuator configured: %s\n', model_file);
    fprintf('Backup written: %s\n', backup_file);
else
    fprintf('Road-3 ACT50 actuator structure check passed for %s\n', model_file);
end
end

function options = local_parse_inputs(varargin)
options = struct();
options.apply = true;
options.dt_s = 0.001;
options.tau_s = 0.05;

if mod(nargin, 2) ~= 0
    error('Arguments must be name/value pairs.');
end

for i = 1:2:nargin
    name = lower(char(varargin{i}));
    value = varargin{i + 1};
    switch name
        case 'apply'
            options.apply = logical(value);
        case 'dt'
            options.dt_s = double(value);
        case 'dt_s'
            options.dt_s = double(value);
        case 'tau'
            options.tau_s = double(value);
        case 'tau_s'
            options.tau_s = double(value);
        otherwise
            error('Unsupported option: %s', name);
    end
end
end

function backup_file = local_backup_model(model_file)
backup_dir = fullfile(fileparts(model_file), 'model_backups');
if exist(backup_dir, 'dir') == 0
    mkdir(backup_dir);
end
[~, name, ext] = fileparts(model_file);
stamp = datestr(now, 'yyyymmdd_HHMMSS');
backup_file = fullfile(backup_dir, [name '_before_ACT50_' stamp ext]);
copyfile(model_file, backup_file);
end

function local_insert_all_actuators(model_name, options)
corner_order = {'L1', 'L2', 'R1', 'R2'};
subsystems = local_root_mux_subsystems(model_name, corner_order);
for i = 1:numel(corner_order)
    local_insert_actuator(subsystems{i}, corner_order{i}, options);
end
end

function subsystems = local_root_mux_subsystems(model_name, corner_order)
mux = [model_name '/Mux'];
line_handles = get_param(mux, 'LineHandles');
assert(numel(line_handles.Inport) == 4, 'Root Mux must expose four IMP_FS inputs.');

subsystems = cell(1, numel(corner_order));
for i = 1:numel(corner_order)
    line = line_handles.Inport(i);
    assert(line > 0, 'Mux input %d is unconnected.', i);
    src_block = get_param(line, 'SrcBlockHandle');
    src_path = getfullname(src_block);
    subsystems{i} = local_find_controller_subsystem(src_path, corner_order{i});
end
end

function subsystem = local_find_controller_subsystem(src_path, corner)
subsystem = local_find_controller_subsystem_upstream(src_path, corner, 0);
if ~isempty(subsystem)
    return;
end
error('Could not locate controller subsystem for IMP_FS_%s from %s.', corner, src_path);
end

function subsystem = local_find_controller_subsystem_upstream(path, corner, depth)
subsystem = '';
if depth > 16 || isempty(path)
    return;
end

if strcmp(get_param(path, 'BlockType'), 'SubSystem') && local_subsystem_calls_corner(path, corner)
    subsystem = path;
    return;
end

ports = get_param(path, 'PortHandles');
for i = 1:numel(ports.Inport)
    line = get_param(ports.Inport(i), 'Line');
    if line <= 0
        continue;
    end
    upstream = getfullname(get_param(line, 'SrcBlockHandle'));
    subsystem = local_find_controller_subsystem_upstream(upstream, corner, depth + 1);
    if ~isempty(subsystem)
        return;
    end
end
end

function tf = local_subsystem_calls_corner(subsystem, corner)
rt = sfroot;
charts = rt.find('-isa', 'Stateflow.EMChart');
token = ['per_corner_mpc_' corner '_2020'];
tf = false;
for i = 1:numel(charts)
    if startsWith(charts(i).Path, [subsystem '/']) && contains(charts(i).Script, token)
        tf = true;
        return;
    end
end
end

function local_insert_actuator(subsystem, corner, options)
chart_path = local_find_corner_chart(subsystem, corner);
outport = local_single_block(subsystem, 'Outport');
act_name = ['Road3_ACT50_' corner];
act_path = [subsystem '/' act_name];
delay_name = ['Road3_ACT50_u_prev_' corner];
delay_path = [subsystem '/' delay_name];

if ~local_block_exists(act_path)
    pos = local_block_position(outport);
    add_block('simulink/Discrete/Discrete Transfer Fcn', act_path, ...
        'Position', [pos(1) - 145, pos(2) - 10, pos(1) - 55, pos(2) + 25], ...
        'Numerator', sprintf('[%.17g]', 1 - exp(-options.dt_s / options.tau_s)), ...
        'Denominator', sprintf('[1 %.17g]', -exp(-options.dt_s / options.tau_s)), ...
        'SampleTime', sprintf('%.17g', options.dt_s), ...
        'InitialStates', '0');
end

if ~local_block_exists(delay_path)
    pos = local_block_position(chart_path);
    add_block('simulink/Discrete/Unit Delay', delay_path, ...
        'Position', [pos(1) - 115, pos(2) + 130, pos(1) - 70, pos(2) + 165], ...
        'SampleTime', sprintf('%.17g', options.dt_s), ...
        'InitialCondition', '0');
end

local_wire_output_through_actuator(subsystem, outport, act_path);
local_wire_actuator_feedback(subsystem, chart_path, act_path, delay_path);
end

function chart_path = local_find_corner_chart(subsystem, corner)
rt = sfroot;
charts = rt.find('-isa', 'Stateflow.EMChart');
token = ['per_corner_mpc_' corner '_2020'];
for i = 1:numel(charts)
    if startsWith(charts(i).Path, [subsystem '/']) && contains(charts(i).Script, token)
        chart_path = charts(i).Path;
        return;
    end
end
error('Could not find MATLAB Function chart for %s under %s.', corner, subsystem);
end

function block = local_single_block(parent, block_type)
blocks = find_system(parent, 'SearchDepth', 1, 'BlockType', block_type);
assert(numel(blocks) == 1, 'Expected one %s in %s, found %d.', block_type, parent, numel(blocks));
block = blocks{1};
end

function local_wire_output_through_actuator(subsystem, outport, act_path)
out_ports = get_param(outport, 'PortHandles');
out_line = get_param(out_ports.Inport(1), 'Line');

if out_line > 0
    src_block = get_param(out_line, 'SrcBlockHandle');
    if strcmp(getfullname(src_block), act_path)
        return;
    end
    if strcmp(get_param(src_block, 'BlockType'), 'Gain') && local_is_minus_one_gain(getfullname(src_block))
        set_param(src_block, 'Gain', '1');
    end
    src_port = get_param(out_line, 'SrcPortHandle');
    delete_line(out_line);
    add_line(subsystem, src_port, get_param(act_path, 'PortHandles').Inport(1), 'autorouting', 'on');
end

act_ports = get_param(act_path, 'PortHandles');
add_line(subsystem, act_ports.Outport(1), out_ports.Inport(1), 'autorouting', 'on');
end

function local_wire_actuator_feedback(subsystem, chart_path, act_path, delay_path)
chart_ports = get_param(chart_path, 'PortHandles');
assert(numel(chart_ports.Inport) >= 8, '%s must expose u_prev as input port 8.', chart_path);
u_prev_port = chart_ports.Inport(8);

old_line = get_param(u_prev_port, 'Line');
if old_line > 0
    src_block = get_param(old_line, 'SrcBlockHandle');
    if ~strcmp(getfullname(src_block), delay_path)
        delete_line(old_line);
    end
end

act_ports = get_param(act_path, 'PortHandles');
delay_ports = get_param(delay_path, 'PortHandles');
local_add_line_by_handle(subsystem, act_ports.Outport(1), delay_ports.Inport(1));
local_add_line_by_handle(subsystem, delay_ports.Outport(1), u_prev_port);
end

function local_disable_mux_path_negative_gains(model_name)
mux = [model_name '/Mux'];
line_handles = get_param(mux, 'LineHandles');
for i = 1:numel(line_handles.Inport)
    line = line_handles.Inport(i);
    if line > 0
        src = get_param(line, 'SrcBlockHandle');
        local_disable_upstream_negative_gain(src, 0);
    end
end
end

function local_disable_upstream_negative_gain(block, depth)
if depth > 16 || block <= 0
    return;
end
path = getfullname(block);
block_type = get_param(path, 'BlockType');
if strcmp(block_type, 'Gain') && local_is_minus_one_gain(path)
    set_param(path, 'Gain', '1');
end
ports = get_param(path, 'PortHandles');
for i = 1:numel(ports.Inport)
    line = get_param(ports.Inport(i), 'Line');
    if line > 0
        upstream = get_param(line, 'SrcBlockHandle');
        local_disable_upstream_negative_gain(upstream, depth + 1);
    end
end
end

function tf = local_is_minus_one_gain(path)
gain = strtrim(get_param(path, 'Gain'));
tf = strcmp(gain, '-1') || strcmp(gain, '-1.0') || strcmp(gain, '(-1)');
end

function local_check_actuator_structure(model_name, options)
assert(strcmp(get_param(model_name, 'FixedStep'), sprintf('%.3f', options.dt_s)), ...
    'FixedStep must be %.3f s for ACT50 verification.', options.dt_s);

corner_order = {'L1', 'L2', 'R1', 'R2'};
subsystems = local_root_mux_subsystems(model_name, corner_order);
for i = 1:numel(corner_order)
    corner = corner_order{i};
    subsystem = subsystems{i};
    act_path = [subsystem '/Road3_ACT50_' corner];
    delay_path = [subsystem '/Road3_ACT50_u_prev_' corner];
    assert(local_block_exists(act_path), 'Missing actuator block: %s', act_path);
    assert(local_block_exists(delay_path), 'Missing u_prev delay block: %s', delay_path);
    local_check_actuator_params(act_path, options);
    local_check_actuator_input_no_minus_one(act_path);
    local_check_u_prev_feedback(subsystem, corner, act_path, delay_path);
end
local_assert_no_mux_path_minus_one_gain(model_name);
end

function local_check_actuator_params(act_path, options)
alpha = exp(-options.dt_s / options.tau_s);
num = str2num(get_param(act_path, 'Numerator')); %#ok<ST2NM>
den = str2num(get_param(act_path, 'Denominator')); %#ok<ST2NM>
assert(abs(num(1) - (1 - alpha)) < 1e-12, '%s numerator does not match ACT50.', act_path);
assert(numel(den) >= 2 && abs(den(2) + alpha) < 1e-12, '%s denominator does not match ACT50.', act_path);
end

function local_check_actuator_input_no_minus_one(act_path)
ports = get_param(act_path, 'PortHandles');
line = get_param(ports.Inport(1), 'Line');
assert(line > 0, '%s input is unconnected.', act_path);
src = getfullname(get_param(line, 'SrcBlockHandle'));
if strcmp(get_param(src, 'BlockType'), 'Gain')
    assert(~local_is_minus_one_gain(src), 'Strict ACT50 actuator input still contains Gain=-1: %s', src);
end
end

function local_check_u_prev_feedback(subsystem, corner, act_path, delay_path)
chart_path = local_find_corner_chart(subsystem, corner);
chart_ports = get_param(chart_path, 'PortHandles');
line = get_param(chart_ports.Inport(8), 'Line');
assert(line > 0, '%s u_prev input is unconnected.', chart_path);
src_block = getfullname(get_param(line, 'SrcBlockHandle'));
assert(strcmp(src_block, delay_path), '%s u_prev must be driven by %s, got %s.', chart_path, delay_path, src_block);

delay_ports = get_param(delay_path, 'PortHandles');
delay_line = get_param(delay_ports.Inport(1), 'Line');
assert(delay_line > 0, '%s input is unconnected.', delay_path);
delay_src = getfullname(get_param(delay_line, 'SrcBlockHandle'));
assert(strcmp(delay_src, act_path), '%s input must be driven by %s, got %s.', delay_path, act_path, delay_src);
end

function local_assert_no_mux_path_minus_one_gain(model_name)
mux = [model_name '/Mux'];
line_handles = get_param(mux, 'LineHandles');
for i = 1:numel(line_handles.Inport)
    if line_handles.Inport(i) > 0
        local_assert_no_upstream_minus_one_gain(get_param(line_handles.Inport(i), 'SrcBlockHandle'), 0);
    end
end
end

function local_assert_no_upstream_minus_one_gain(block, depth)
if depth > 16 || block <= 0
    return;
end
path = getfullname(block);
if strcmp(get_param(path, 'BlockType'), 'Gain')
    assert(~local_is_minus_one_gain(path), 'Strict ACT50 force path still contains Gain=-1: %s', path);
end
ports = get_param(path, 'PortHandles');
for i = 1:numel(ports.Inport)
    line = get_param(ports.Inport(i), 'Line');
    if line > 0
        local_assert_no_upstream_minus_one_gain(get_param(line, 'SrcBlockHandle'), depth + 1);
    end
end
end

function pos = local_block_position(path)
pos = get_param(path, 'Position');
end

function tf = local_block_exists(path)
try
    get_param(path, 'Handle');
    tf = true;
catch
    tf = false;
end
end

function local_add_line_by_handle(parent, src_port, dst_port)
try
    add_line(parent, src_port, dst_port, 'autorouting', 'on');
catch err
    if ~contains(err.message, 'already') && ~contains(err.message, 'Invalid line')
        rethrow(err);
    end
end
end
