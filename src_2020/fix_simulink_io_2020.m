function fix_simulink_io_2020()
%FIX_SIMULINK_IO_2020 Repair CarSim import ordering for untitled_2020.slx.
%
% Required CarSim import order:
%   IMP_FS_L1, IMP_FS_L2, IMP_FS_R1, IMP_FS_R2

root_dir = fileparts(mfilename('fullpath'));
model_file = fullfile(root_dir, 'untitled_2020.slx');
model_name = 'untitled_2020';

load_system(model_file);
cleanup = onCleanup(@() close_system(model_name, 0));

% Mux input 2 is L2. Keep the L2 controller block, but feed L2 signals.
local_reconnect(model_name, 'Subsystem', { ...
    'From26/1', ... % W0_L2
    'From22/1', ... % Sus_vel_L2
    'From2/1',  ... % W1_L2
    'From6/1',  ... % W2_L2
    'From14/1', ... % Az_SM
    'From11/1', ... % Vz_SM
    'From18/1', ... % Sus_def_L2
    'Demux/24'  ... % Pitch
});

% Mux input 3 is R1. Keep the R1 controller block, but feed R1 signals.
local_reconnect(model_name, 'Subsystem1', { ...
    'From17/1', ... % Sus_def_R1
    'From13/1', ... % Az_SM
    'From10/1', ... % Vz_SM
    'From25/1', ... % W0_R1
    'From21/1', ... % Sus_vel_R1
    'From1/1',  ... % W1_R1
    'From7/1',  ... % W2_R1
    'Demux/24'  ... % Pitch
});

local_rename_if_exists([model_name '/Subsystem/右前路面高程'], '左后路面高程');
local_rename_if_exists([model_name '/Subsystem1/左后路面高程'], '右前路面高程');

save_system(model_name, model_file);
fprintf('Fixed Simulink IO mapping in %s\n', model_file);
end

function local_reconnect(model_name, subsystem_name, sources)
subsystem_path = [model_name '/' subsystem_name];
port_handles = get_param(subsystem_path, 'PortHandles');
assert(numel(port_handles.Inport) >= numel(sources), ...
    '%s has fewer input ports than expected', subsystem_path);

for i = 1:numel(sources)
    line = get_param(port_handles.Inport(i), 'Line');
    if line > 0
        delete_line(line);
    end
    add_line(model_name, sources{i}, [subsystem_name '/' num2str(i)], 'autorouting', 'on');
end
end

function local_rename_if_exists(block_path, new_name)
if getSimulinkBlockHandle(block_path) > 0
    set_param(block_path, 'Name', new_name);
end
end
