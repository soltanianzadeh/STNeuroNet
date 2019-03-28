%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%
%% USed to run the marking software

function main_SelectNeuron(vid,guimask,DirSave,name)
   
    [x,y,T] = size(vid);
    v = reshape(vid,[],T);
    % If there is no initial mask, starst from scratch
    if isempty(guimask)
        guimask = zeros(x,y);
        guitrace = zeros(1,T);
    else
           %% Get traces for each mask
        guitrace = zeros(size(guimask,3),T);        
        for k = 1:size(guimask,3)
            guitrace(k,:) = sum(v(reshape(guimask(:,:,k),[],1)==1,:),1);
        end
    end
    
    %% Manually add missing neurons
    saveName = [DirSave,filesep,'Added_',name,'.mat'];
    AddROI(vid,saveName, guimask);
    fig = gcf;
    waitfor(fig);

    %% Load results and add traces from added masks    
    numMasksOrig =size(guimask,3);
    load(saveName,'FinalMasks');
    guimask = FinalMasks;
    clear FinalMasks;

    if size(guimask,3)>numMasksOrig
        for k = numMasksOrig+1:size(guimask,3)
            guitrace(k,:) = sum(v(reshape(guimask(:,:,k),[],1)==1,:),1);
        end
    end

    %% Check for all zero masks
    m = reshape(guimask,[],size(guimask,3));
    guimask(:,:,find(sum(m,1)==0)) = [];
    guitrace(find(sum(m,1)==0),:) = [];
    
    %% rough estimate of dff
    guitrace = guitrace./median(guitrace,2) - 1;
    clear v
    %% Set global variables
    global gui; global data1;
    global result;       result = ones(size(guimask,3),1)*2;
    global resultString; resultString = cell(size(guimask,3),1); 
    global resultSpTimes; resultSpTimes = cell(size(guimask,3),1);
    for j = 1:size(guimask,3) 
        resultString{j} = num2str(j); 
    end

    %% GUI main
    saveName = [DirSave,filesep,'FinalMasks_',name,'.mat'];
    SelectNeuron_Allen(vid,guimask,guitrace)
    waitfor(gui.Window)

    FinalMasks = guimask(:,:,find(result==1));
    FinalTimes = resultSpTimes(find(result==1));

    save(saveName,'FinalMasks','FinalTimes');

    saveName = [DirSave,filesep,'ManualIDs_traces_',name,'.mat'];
    save(saveName,'result','resultString','resultSpTimes','guitrace')

    clear gui finalMask Y guimask guitrace result resultSpTimes

end
