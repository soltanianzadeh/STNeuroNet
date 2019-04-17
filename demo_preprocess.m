%% Demo script that pre-processes an ABO data for training.
addpath(genpath('Software'))

%% Set directories
opt.ID = '501271265';
DirData = ['Dataset',filesep,'ABO',filesep];
DirSaveData =['Results',filesep,'ABO',filesep,'data',filesep];
DirMask = ['Markings',filesep,'ABO',filesep,'Layer175',filesep,'FinalGT',filesep];
DirSaveMask = ['Results',filesep,'ABO',filesep,'data',filesep,'TempMask',filesep];

%% Set parameters. Border crop values are set as default.
opt.s = 30;                     % pixels, size of the gaussian filter used in filtering
opt.ds = 5;                     % downsampling factor

%% run pre-processing 
dataFile = [DirData,opt.ID,'_processed.nii.gz'];
if ~exist(dataFile)
    Y = prepareAllen(opt, DirData, DirData);
    vid = Y.video; clear Y
else
    vid = dataFile; 
end

HomoFilt_Normalize(vid,DirSaveData,opt.ID,opt.s);

%% Create the temporal labeling data (for training)
is_training = 0;

if is_training
    lam = 2.9;          %spikes/s
    Pd = 1- 0.035;      % Probability of detection
    tau = 0.2;          % decay time in seconds
    fs = 6;             % recording speed, Hz
    if ~exist(DirSaveMask)
        mkdir(DirSaveMask)
    end

    prepareTemporalMask(DirData,DirMask,DirSaveMask,opt.ID,tau,fs,lam,Pd);

    %% Create overlapping sub-volumes from data and labeling for training
    Wt = 120;   %Cropping window in temporal dimension, frames
    Ws = 144;   %Cropping window in spatial domain, pixels
    tag = 0;
    if tag
        DirSubImages = ['Results',filesep,'ABO',filesep,'subImages'];
        if ~exist(DirSubImages)
            mkdir(DirSubImages)
        end
        SaveSubVolumes(DirSaveData,DirSaveMask,DirSubImages,opt.ID,Ws,Wt);
    end
end
