clear; close all

%% Get system data
mpc=eval('mcase9');
mpc=runopf(mpc,mpoption('verbose',0,'out.all',0));

%% get plot data
mesh_intensity=20; plot_bus=[5 7]; mesh_axis=[-2 0 -2 0];
[u1_plot,u2_plot,mesh_all,mesh_feasibility,u_base]=get_plot_data(mpc,plot_bus,mesh_axis,mesh_intensity);

%% Plot figure
fig=figure; box on; grid on; hold all; set(fig, 'Position', [100, 100, 450, 350]);
caxis([0 400]); colormap([0.7461 0.832 0.9062 ;0.875*0.9 0.9492*0.9 0.6875*0.9; 0.875 0.9492 0.6875; 1 1 1]);
contourf(-u1_plot,-u2_plot,mesh_feasibility,[0 0])

pcolor_meshall=[0.25 0.25 0.25; ones(2,1)*[0 0.447 0.7410]; ones(4,1)*[0.929 0.694 0.125]; 0.494 0.184 0.556; ones(2,1)*[0.635 0.078 0.184]];
ptype_meshall={'-','-','--','-','--','-','--','-','--','-'};
for i=1:size(mesh_all,2)
    if size(mesh_all{i},1)~=1
        for j=1:size(mesh_all{i},3)
            if max(max(mesh_all{i}(:,:,j)))>0
                contour(-u1_plot,-u2_plot,mesh_all{i}(:,:,j),[0 0],ptype_meshall{i},'color',pcolor_meshall(i,:),'LineWidth',2);
            end
        end
    end
end

x_label=xlabel(['$p_{d,' num2str(plot_bus(1)) '}$ (p.u.)']); set(x_label, 'Interpreter', 'latex','FontSize',15,'FontName','Times New Roman');
y_label=ylabel(['$p_{d,' num2str(plot_bus(2)) '}$ (p.u.)']); set(y_label, 'Interpreter', 'latex','FontSize',15,'FontName','Times New Roman');
set(gca,'fontsize',15,'FontName','Times New Roman')
