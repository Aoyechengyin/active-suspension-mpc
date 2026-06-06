function [u_opt, exitflag, active_idx] = regionless_mpc_eval_2020(x, active_sets, invH, invH_Ft, H, F, P, M1, M2)
%REGIONLESS_MPC_EVAL_2020 Regionless e-MPC online evaluation for scripts.

u_opt = 0;
exitflag = 0;
active_idx = 0;

b = M1 + M2 * x;
U_base = -invH_Ft * x;

best_obj = inf;
if all(P * U_base <= b + 1e-6)
    u_opt = U_base(1);
    best_obj = local_objective(U_base, H, F, x);
    exitflag = 1;
end

for i = 1:numel(active_sets)
    Ai = active_sets{i}.A;
    if isempty(Ai)
        continue;
    end

    lambda = active_sets{i}.Q * x + active_sets{i}.q;
    if any(lambda < -1e-6)
        continue;
    end

    U_candidate = U_base - invH * active_sets{i}.PA' * lambda;
    if all(P * U_candidate <= b + 1e-6)
        obj = local_objective(U_candidate, H, F, x);
        if obj < best_obj
            best_obj = obj;
            u_opt = U_candidate(1);
            exitflag = 1;
            active_idx = i;
        end
    end
end

if exitflag == 0
    u_opt = max(-M1(1), min(M1(1), U_base(1)));
end
end

function obj = local_objective(U, H, F, x)
obj = 0.5 * (U' * H * U) + x' * F * U;
end
