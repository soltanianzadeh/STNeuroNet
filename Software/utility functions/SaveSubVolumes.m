%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function SaveSubVolumes(DataDir,MaskDir,DirSave,name,Ws,Wt)
% Ws ans Wt are the spatial and temporal window lenghts

% create the candidate window locations with %50 overlap spatially, 75%
% temporally
stepS = Ws/2; stepT = Wt/4;

if exist([MaskDir,filesep,'TemporalMask_',name,'.nii.gz']) && exist([DataDir,filesep,name,'_dsCropped_HomoNorm.nii.gz'])
    
    label = niftiread([MaskDir,filesep,'TemporalMask_',name,'.nii.gz']);
    vid = niftiread([DataDir,filesep,name,'_dsCropped_HomoNorm.nii.gz']);
    
    [x,y,T] = size(vid);
    rp = [1:stepS:x-Ws, x-Ws]; %last element is to cover all the image
    cp = [1:stepS:y-Ws, y-Ws]; 
    tp = [1:stepT:T-Wt];
    
    count = 1;
    nameVid = ['HomoVid_',name];
    nameMask = ['TempMask_',name];
    for jj = 0:2
        count = randWinSave(rot90(vid,jj),rot90(label,jj),...
             DirSave,nameVid,nameMask,Ws,Wt,rp,cp,tp,count,jj);
    end
    clear vid label
else
    error('Normalized data or Mask not found.')
end

end

