%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function RunViewMarking(opt)

% check all fielad are present
tf = isfield(opt, {'dataset','ID','type','marking'});
if nnz(tf) ~=4
    error('Input structure is missing one or more required fields.')
end

switch opt.dataset
    case 'Allen'
        %%%%%ckeck fields
        if ~(strcmp(opt.type,'Layer275') || strcmp(opt.type,'Layer175'))
            error('Unknown Layer.');
        end
        if ~(strcmp(opt.marking,'Allen') || strcmp(opt.marking,'Grader1') || strcmp(opt.marking,'Grader3'))
            error('Unknown marking type.');
        end        
        %%%%%Read data
        DataDir = ['Dataset',filesep,'ABO',filesep,opt.ID,'_processed.nii.gz'];
        if ~exist(DataDir)
            opt.ds = 5;
            DirSave = ['Dataset',filesep,'ABO',filesep];
            DirData = ['Dataset',filesep,'ABO',filesep,'ophys_experiment_',opt.ID,'.h5'];
            Y = prepareAllen(opt,DirData,DirSave);
        else
            Y.video = niftiread(DataDir);
        end
        ViewAllenMarking(Y,opt);
        
        
    case 'Neurofinder'
        %%%%%ckeck fields
        if ~(strcmp(opt.type,'train') || strcmp(opt.type,'test'))
            error('Unknown data type.');
        end
        if ~(strcmp(opt.marking,'neurofinder') || strcmp(opt.marking,'Grader1'))
            error('Unknown marking type.');
        end
        DataDir = ['Dataset',filesep,'Neurofinder',filesep,opt.type,filesep,opt.ID,'_processed.nii.gz'];
        if ~exist(DataDir)
            opt.ds = 3;
            DirSave = ['Dataset',filesep,'Neurofinder',filesep,opt.type,filesep];
            DirData = ['Dataset',filesep,'Neurofinder',filesep];
            imgs = prepareNeurofinder(opt,DirData,DirSave);
        else
            imgs = niftiread(DataDir);
        end
        ViewNeuronMarking(imgs,opt);
        
    otherwise
        error('Unknown dataset name. Plese choose between Neurofinder and Allen.')
        
end


end

