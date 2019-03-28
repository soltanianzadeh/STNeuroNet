%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function prepareTemporalMask(DirData,DirMask,DirSave,name,tau,fs,lam,Pd)
% create temporal labeling of neurons

opt.tau = tau;
opt.fs = fs;
stat.thresh = norminv(Pd)-norminv(lam/(fs-lam)*(1-Pd));
stat.Pd = Pd;

%% If data is already processed, display message and don't do anything
if exist([DirSave,filesep,'TemporalMask_',name,'.nii.gz'])
    disp('Temporal label already exists.')
else
    f = dir([DirMask,filesep,'*_',name,'.mat']);
    if ~isempty(f)
        MaskName = [f.folder,filesep,f.name];        
    else
        error('Mask not found.')
    end    
    
    matObj = matfile(MaskName);
    details = whos(matObj);
    
    if ~contains([details.name],'FinalMasks')
        error('Neuron Masks not found in Mask file. It should be named FinalMasks.')
    end
    
    load(MaskName,'FinalMasks');
    
    if ~contains([details.name],'FinalTimes')
        FinalTimes = [];
    else
        load(MaskName,'FinalTimes');
    end
    
    if ~exist([DirData,filesep,name,'_processed.nii.gz'])
        error('Downsampled, Cropped Data not found.')
    else
        vid = niftiread([DirData,filesep,name,'_processed.nii.gz']);
    end
    % get neural traces: demixes the traces for overlapping neurons
    FinalTraces = GetTraces(vid,FinalMasks);
    
    % neuropil correction.
    tag = 1;
    if tag
        FinalTraces = RemoveNeuropil(vid,FinalMasks,FinalTraces,1,0.78);
    end
    
    % Temporal Labeling based on d'
    [Label,~] = TemporalLabeling_d(FinalMasks,FinalTraces,FinalTimes,stat,opt);

    % save result
    Savename = [DirSave,filesep,'TemporalMask_',name];
    niftiwrite(Label,[Savename],'Compressed',true);
    
end

end

