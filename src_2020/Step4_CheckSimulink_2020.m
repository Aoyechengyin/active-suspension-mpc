function Step4_CheckSimulink_2020(update_model)
%STEP4_CHECKSIMULINK_2020 Copy/update and check the CarSim 2020 Simulink model.
%
%   Step4_CheckSimulink_2020(true) updates untitled_2020.slx in place.
%   Step4_CheckSimulink_2020(false) only checks structural assumptions.

if nargin < 1
    update_model = true;
end

root_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(root_dir);
src_model = fullfile(project_root, 'src', 'untitled.slx');
model_file = fullfile(root_dir, 'untitled_2020.slx');
assert(exist(src_model, 'file') > 0, 'Source model missing: %s', src_model);
if exist(model_file, 'file') == 0
    copyfile(src_model, model_file);
end

addpath(root_dir);
model_name = 'untitled_2020';
load_system(model_file);
cleanup = onCleanup(@() bdclose(model_name));

if update_model
    set_param(model_name, 'Solver', 'ode4', 'FixedStep', '0.001', 'StopTime', '15');
    local_update_chart_scripts(model_name);
    local_add_pitch_paths(model_name);
    save_system(model_name, model_file);
end

local_check_model(model_name);
fprintf('Step4_CheckSimulink_2020 passed for %s\n', model_file);
end

function local_update_chart_scripts(model_name)
mapping = { ...
    'per_corner_mpc_L1', 'per_corner_mpc_L1_2020'; ...
    'per_corner_mpc_R1', 'per_corner_mpc_R1_2020'; ...
    'per_corner_mpc_L2', 'per_corner_mpc_L2_2020'; ...
    'per_corner_mpc_R2', 'per_corner_mpc_R2_2020' ...
};

rt = sfroot;
for i = 1:size(mapping, 1)
    charts = rt.find('-isa', 'Stateflow.EMChart');
    chart = [];
    for j = 1:numel(charts)
        if contains(charts(j).Script, ['function u_cmd = ' mapping{i, 1}])
            chart = charts(j);
            break;
        end
    end
    assert(~isempty(chart), 'Stateflow chart not found: %s', mapping{i, 1});
    chart.Script = sprintf([ ...
        'function u_cmd = %s(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg)\n', ...
        '%%#codegen\n', ...
        'u_cmd = %s(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg);\n', ...
        'end\n'], mapping{i, 1}, mapping{i, 2});
end
local_update_without_carsim(model_name);
end

function local_update_without_carsim(model_name)
carsim_block = [model_name '/CarSim S-Function'];
old_state = '';
try
    old_state = get_param(carsim_block, 'Commented');
    set_param(carsim_block, 'Commented', 'on');
catch
end
try
    set_param(model_name, 'SimulationCommand', 'Update');
catch err
    if ~isempty(old_state)
        set_param(carsim_block, 'Commented', old_state);
    end
    rethrow(err);
end
if ~isempty(old_state)
    set_param(carsim_block, 'Commented', old_state);
end
end

function local_add_pitch_paths(model_name)
% Direct-controller subsystems.
local_ensure_pitch_to_function(model_name, 'Subsystem', 'MATLAB Function4');
local_ensure_pitch_to_function(model_name, 'Subsystem1', 'MATLAB Function2');
local_ensure_pitch_to_function(model_name, 'Subsystem2', 'MATLAB Function1');
local_ensure_pitch_to_function(model_name, 'Subsystem3', 'MATLAB Function3');

% Branch root Pitch signal to each top-level controller subsystem.
local_add_line_if_missing(model_name, 'Demux/24', 'Subsystem/8');
local_add_line_if_missing(model_name, 'Demux/24', 'Subsystem1/8');
local_add_line_if_missing(model_name, 'Demux/24', 'Subsystem2/8');
local_add_line_if_missing(model_name, 'Demux/24', 'Subsystem3/8');
end

function local_ensure_pitch_to_function(model_name, subsystem_name, function_block)
subsys = [model_name '/' subsystem_name];
local_ensure_block(subsys, 'Inport', 'pitch_deg', [20 245 50 259]);
local_set_port(subsys, 'pitch_deg', '8');
local_add_line_if_missing(subsys, 'pitch_deg/1', [function_block '/9']);
end

function local_ensure_block(parent, block_type, name, position)
path = [parent '/' name];
if exist_block(path)
    return;
end
if strcmp(block_type, 'Inport')
    lib_path = 'simulink/Sources/In1';
else
    lib_path = ['simulink/Sources/' block_type];
end
add_block(lib_path, path, 'Position', position);
end

function local_set_port(parent, name, port_num)
path = [parent '/' name];
if exist_block(path)
    set_param(path, 'Port', port_num);
end
end

function local_add_line_if_missing(parent, src, dst)
try
    add_line(parent, src, dst, 'autorouting', 'on');
catch err
    if ~contains(err.message, 'already') && ~contains(err.message, 'Invalid line')
        rethrow(err);
    end
end
end

function tf = exist_block(path)
try
    get_param(path, 'Handle');
    tf = true;
catch
    tf = false;
end
end

function local_check_model(model_name)
assert(strcmp(get_param(model_name, 'Solver'), 'ode4'), 'Solver must be ode4');
assert(strcmp(get_param(model_name, 'FixedStep'), '0.001'), 'FixedStep must be 0.001');
assert(strcmp(get_param(model_name, 'StopTime'), '15'), 'StopTime must be 15');

demux_outputs = get_param([model_name '/Demux'], 'Outputs');
assert(strcmp(demux_outputs, '24'), 'Root Demux must have 24 outputs');

for block = {'Subsystem', 'Subsystem1', 'Subsystem2', 'Subsystem3'}
    ports = get_param([model_name '/' block{1}], 'Ports');
    assert(ports(1) >= 8, '%s must expose pitch_deg as input 8', block{1});
end

rt = sfroot;
for name = {'per_corner_mpc_L1','per_corner_mpc_R1','per_corner_mpc_L2','per_corner_mpc_R2'}
    charts = rt.find('-isa', 'Stateflow.EMChart');
    chart = [];
    for j = 1:numel(charts)
        if contains(charts(j).Script, [name{1} '_2020'])
            chart = charts(j);
            break;
        end
    end
    assert(~isempty(chart), 'Missing chart %s', name{1});
    assert(contains(chart.Script, 'pitch_deg'), 'Chart %s does not include pitch_deg', name{1});
    assert(contains(chart.Script, [name{1} '_2020']), 'Chart %s does not call 2020 wrapper', name{1});
end

local_check_mux_and_corner_sources(model_name);
end

function local_check_mux_and_corner_sources(model_name)
expected_corners = {'L1', 'L2', 'R1', 'R2'};
mux = [model_name '/Mux'];
line_handles = get_param(mux, 'LineHandles');
assert(numel(line_handles.Inport) == 4, 'Root Mux must expose 4 CarSim import signals');

for i = 1:4
    line = line_handles.Inport(i);
    assert(line > 0, 'Mux input %d is unconnected', i);
    src_block = get_param(line, 'SrcBlockHandle');
    src_path = getfullname(src_block);
    corner = expected_corners{i};
    wrapper = local_subsystem_wrapper(src_path);
    assert(contains(wrapper, ['per_corner_mpc_' corner '_2020']), ...
        'Mux input %d must be IMP_FS_%s but is driven by %s', i, corner, wrapper);
    local_check_corner_input_tags(src_path, corner);
end
end

function wrapper = local_subsystem_wrapper(subsystem_path)
rt = sfroot;
charts = rt.find('-isa', 'Stateflow.EMChart');
wrapper = '';
for i = 1:numel(charts)
    if startsWith(charts(i).Path, [subsystem_path '/'])
        token = regexp(charts(i).Script, 'per_corner_mpc_[LR][12]_2020', 'match', 'once');
        if ~isempty(token)
            wrapper = token;
            return;
        end
    end
end
error('No 2020 per-corner wrapper found under %s', subsystem_path);
end

function local_check_corner_input_tags(subsystem_path, corner)
tags = local_subsystem_source_tags(subsystem_path);
required = { ...
    ['W0_' corner], ['W1_' corner], ['W2_' corner], ...
    ['Sus_def_' corner], ['Sus_vel_' corner], ...
    'Az_SM', 'Vz_SM', 'Pitch' ...
};
for i = 1:numel(required)
    assert(any(strcmp(tags, required{i})), ...
        'Subsystem %s for %s is missing source tag %s. Actual tags: %s', ...
        subsystem_path, corner, required{i}, strjoin(tags, ', '));
end
end

function tags = local_subsystem_source_tags(subsystem_path)
tags = {};
port_handles = get_param(subsystem_path, 'PortHandles');
for i = 1:numel(port_handles.Inport)
    line = get_param(port_handles.Inport(i), 'Line');
    if line <= 0
        continue;
    end
    src_block = get_param(line, 'SrcBlockHandle');
    tag = local_source_tag(src_block, line);
    if ~isempty(tag)
        tags{end+1} = tag; %#ok<AGROW>
    end
end
end

function tag = local_source_tag(src_block, line)
src_path = getfullname(src_block);
block_type = get_param(src_path, 'BlockType');
switch block_type
    case 'From'
        tag = get_param(src_path, 'GotoTag');
    case 'Demux'
        src_port = get_param(line, 'SrcPortHandle');
        port_handles = get_param(src_path, 'PortHandles');
        tag = '';
        for i = 1:numel(port_handles.Outport)
            if port_handles.Outport(i) == src_port && i == 24
                tag = 'Pitch';
                return;
            end
        end
    case 'Gain'
        in_line = get_param(get_param(src_block, 'PortHandles').Inport(1), 'Line');
        if in_line > 0
            upstream = get_param(in_line, 'SrcBlockHandle');
            tag = local_source_tag(upstream, in_line);
        else
            tag = '';
        end
    otherwise
        tag = '';
end
end
