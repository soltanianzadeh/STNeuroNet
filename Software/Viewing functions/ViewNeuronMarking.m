%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function ViewNeuronMarking(imgs,opt)
        
    %% Load GT Markings
    if strcmp(opt.type,'test') || strcmp(opt.type,'train')
        MaskDir = ['Markings',filesep,'Neurofinder',filesep,opt.type,filesep,opt.marking];
    else
      error('Unknown data type.');
    end
    
    f = dir([MaskDir,filesep,'*_',opt.ID,'.mat']);
    if ~isempty(f)
        MaskName = [f.folder,filesep,f.name];
        load(MaskName,'FinalMasks');
    else
        error('Mask not found.')
    end
    

    if size(imgs,1) ~= size(FinalMasks,1) || size(imgs,2)~= size(FinalMasks,2)
        error('Size mismatch between video and masks.')
    end
    
    guitrace = zeros(size(FinalMasks,3),size(imgs,3));
    guitrace = RemoveNeuropil(imgs,FinalMasks,guitrace,1,1);

    
    %% Open full FOV video overlaind with masks GUI
    ViewFullFOV(imgs,FinalMasks);
    
    %% Open individual neuron inspection GUI
        % Set global variables
        global gui; global data1;
        global result;       result = ones(size(FinalMasks,3),1);
        global resultString; resultString = cell(size(FinalMasks,3),1); 
        for j = 1:size(FinalMasks,3) 
            resultString{j} = sprintf('%d Yes',j); 
        end    

        ViewNeurons(imgs,FinalMasks,guitrace);
        waitfor(gui.Window)
        
        clear gui Y FinalMasks guitrace    
end

