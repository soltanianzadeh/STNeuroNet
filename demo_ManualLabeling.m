%% Demo script on how to use the manual marking software
addpath(genpath('Software'));

% name of file to read
name = '501484643';

vid = niftiread(['Dataset',filesep,'ABO',filesep,name,'_processed.nii.gz']);

% If there is an initial marking available, define it here. Otherwise,
% leave mask empty (mask = []).
mask = load(['Markings',filesep,'ABO',filesep,'Layer275',filesep,'Allen',filesep,'Masks_',name,'.mat'],'FinalMasks');

%Directory to save results
DirSave = 'Results';

main_SelectNeuron(vid,mask.FinalMasks,DirSave,name)
