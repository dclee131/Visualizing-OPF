function [u1_plot,u2_plot,mesh_all,mesh_feasibility,u_base]=plot_FeasibleRegion(mpc,plot_bus,mesh_axis,resolution)
limit_mode='vpqla';

%% Compute data for plotting
num_bus=size(mpc.bus,1);
num_gen=size(mpc.gen,1);
num_line=size(mpc.branch,1);
gen_status=mpc.gen(:,8);
pg_base=diag(gen_status)*mpc.gen(:,2)/mpc.baseMVA;
pl_base=mpc.bus(:,3)/mpc.baseMVA;
ql_base=mpc.bus(:,4)/mpc.baseMVA;

v_min=mpc.bus(:,13);
v_max=mpc.bus(:,12);
pg_max=diag(gen_status)*mpc.gen(:,9)/mpc.baseMVA;
pg_min=diag(gen_status)*mpc.gen(:,10)/mpc.baseMVA;
qg_max=diag(gen_status)*mpc.gen(:,4)/mpc.baseMVA;
qg_min=diag(gen_status)*mpc.gen(:,5)/mpc.baseMVA;
sline_max=mpc.branch(:,6)/mpc.baseMVA; sline_max(sline_max==0)=1e10;
Etheta_max=mpc.branch(:,13)*pi/180;
Etheta_min=mpc.branch(:,12)*pi/180;

name2idx=sparse(1,mpc.bus(:,1),1:num_bus);
idx_fr=name2idx(mpc.branch(:,1))';
idx_to=name2idx(mpc.branch(:,2))';
[Ybus, Yf, Yt]=makeYbus(mpc.baseMVA, mpc.bus, mpc.branch);

Cg = sparse(name2idx(mpc.gen(:,1)), (1:num_gen), ones(num_gen,1), num_bus, num_gen);
p_base=Cg*pg_base-pl_base;

u_base=p_base(plot_bus);

[u1_plot,u2_plot]=meshgrid(linspace(mesh_axis(1),mesh_axis(2),resolution),linspace(mesh_axis(3),mesh_axis(4),resolution));

mesh_all=cell(1,9); mesh_all(1,:)={0};
solve_mesh=ones(resolution);
V_max_mesh=-ones(resolution,resolution,num_bus);
V_min_mesh=-ones(resolution,resolution,num_bus);
Pg_max_mesh=-ones(resolution,resolution,num_gen);
Pg_min_mesh=-ones(resolution,resolution,num_gen);
Qg_max_mesh=-ones(resolution,resolution,num_gen);
Qg_min_mesh=-ones(resolution,resolution,num_gen);
Sline_mesh=-ones(resolution,resolution,num_line);
Etheta_max_mesh=-ones(resolution,resolution,num_line);
Etheta_min_mesh=-ones(resolution,resolution,num_line);

for i=1:resolution
    for j=1:resolution
        mpc_run=mpc;
        u_plot=[u1_plot(i,j); u2_plot(i,j)];
        
        mpc_run.bus(plot_bus,3)=(Cg(plot_bus(1),:)*pg_base-u1_plot(i,j))*mpc.baseMVA;
        mpc_run.bus(plot_bus,3)=-u_plot*mpc.baseMVA;
        
        mpc_result=runpf(mpc_run,mpoption('verbose',0,'out.all',0));
        vmag_cur=mpc_result.bus(:,8);
        Pg_cur=mpc_result.gen(:,2)/mpc_result.baseMVA;
        Qg_cur=mpc_result.gen(:,3)/mpc_result.baseMVA;
        v_cplx=mpc_result.bus(:,8).*exp(1i*mpc_result.bus(:,9)*pi/180);
        
        Sline_fr=v_cplx(idx_fr).*conj(Yf*v_cplx); Sline_to=v_cplx(idx_to).*conj(Yt*v_cplx);
        Sline_cur=max(abs(Sline_fr),abs(Sline_to));
        Etheta_cur=(mpc_result.bus(idx_fr,9)-mpc_result.bus(idx_to,9))*pi/180;
        
        if mpc_result.success==0
            solve_mesh(i,j)=-1;
        else
            V_max_mesh(i,j,:)=v_max'-vmag_cur';
            V_min_mesh(i,j,:)=vmag_cur'-v_min';
            Pg_max_mesh(i,j,:)=pg_max'-Pg_cur';
            Pg_min_mesh(i,j,:)=Pg_cur'-pg_min';
            Qg_max_mesh(i,j,:)=qg_max'-Qg_cur';
            Qg_min_mesh(i,j,:)=Qg_cur'-qg_min';
            Sline_mesh(i,j,:)=sline_max'-Sline_cur';
            Etheta_max_mesh(i,j,:)=Etheta_max'-Etheta_cur';
            Etheta_min_mesh(i,j,:)=Etheta_cur'-Etheta_min';
        end
    end
end

mesh_feasibility=solve_mesh; mesh_all{1}=-solve_mesh; % minus sign to avoid warning: mesh_all{1} encloses unsolvable region
if sum(limit_mode=='v'); mesh_feasibility=min(min(min(V_max_mesh,[],3),min(V_min_mesh,[],3)),mesh_feasibility); mesh_all{2}=V_max_mesh; mesh_all{3}=V_min_mesh; end
if sum(limit_mode=='p'); mesh_feasibility=min(min(min(Pg_max_mesh,[],3),min(Pg_min_mesh,[],3)),mesh_feasibility);mesh_all{4}=Pg_max_mesh; mesh_all{5}=Pg_min_mesh; end
if sum(limit_mode=='q'); mesh_feasibility=min(min(min(Qg_max_mesh,[],3),min(Qg_min_mesh,[],3)),mesh_feasibility); mesh_all{6}=Qg_max_mesh; mesh_all{7}=Qg_min_mesh; end
if sum(limit_mode=='l'); mesh_feasibility=min(min(Sline_mesh,[],3),mesh_feasibility); mesh_all{8}=Sline_mesh; end
if sum(limit_mode=='a'); mesh_feasibility=min(min(min(Etheta_max_mesh,[],3),min(Etheta_min_mesh,[],3)),mesh_feasibility); mesh_all{9}=Etheta_max_mesh; mesh_all{10}=Etheta_min_mesh; end


