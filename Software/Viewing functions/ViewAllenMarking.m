%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.

function ViewAllenMarking(Y,opt)  

    %% Load GT Markings
    if strcmp(opt.type,'Layer275') || strcmp(opt.type,'Layer175')
        MaskDir = ['Markings',filesep,'ABO',filesep,opt.type,filesep,opt.marking];
    else
      error('Unknown Layer.');
    end
    
    f = dir([MaskDir,filesep,'*_',opt.ID,'.mat']);
    if ~isempty(f)
        MaskName = [f.folder,filesep,f.name];
        load(MaskName,'FinalMasks');
    else
        error('Mask not found.')
    end
    
    %% crop 10um border to remove motion-induced errors in neuron signals
    % if the sizes don't match, it shows that the uncropped video was
    % loaded
    pixSize = 0.78; %um

    if size(Y.video,1) ~= size(FinalMasks,1) || size(Y.video,2) ~= size(FinalMasks,2)
        error('Size mismatch between video and masks.')
    end
  
  
    % Remove potential empty masks
    ind_empty= sum(reshape(FinalMasks,[],size(FinalMasks,3)),1)==0;
    FinalMasks(:,:,ind_empty) = [];
  
    guitrace = zeros(size(FinalMasks,3),size(Y.video,3));
    guitrace = RemoveNeuropil(Y.video,FinalMasks,guitrace,1,pixSize);
    
    %Convert traces to dff
    fs = 6;         %Hz, downsampled data
    win = 60* fs;
    T = size(guitrace,2);
    tracesExtended = cat(2,flip(guitrace(:,1:win/2),2),guitrace,flip(guitrace(:,T-win/2:T),2));
    for t = 1:T
        backTrace(:,t) = median(tracesExtended(:,t:t+win),2);
    end

    F0 = median(backTrace,2);
    guitrace =(guitrace-backTrace)./F0;
    
    
    %% Open full FOV video overlaind with masks GUI
    ViewFullFOV(Y.video,FinalMasks);
    
    %% Open individual neuron inspection GUI
        % Set global variables
        global gui; global data1;
        global result;       result = ones(size(FinalMasks,3),1);
        global resultString; resultString = cell(size(FinalMasks,3),1); 
        for j = 1:size(FinalMasks,3) 
            resultString{j} = sprintf('%d Yes',j); 
        end    

        ViewNeurons(Y.video,FinalMasks,guitrace);
        waitfor(gui.Window)
        
        clear gui Y FinalMasks guitrace
end

