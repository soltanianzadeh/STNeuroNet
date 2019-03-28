%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.

function [Y] = prepareAllen(opt,DirData,DirSave)

% read data from h5 files, temporally bin and save files for the first
% 1/5th of the recordings
if exist(DirData)
    % read dimension of data
    infoVid = h5info(DirData);
    Nx = infoVid.Datasets.Dataspace.Size(1); 
    Ny = infoVid.Datasets.Dataspace.Size(2);
    Nframes = infoVid.Datasets.Dataspace.Size(3);
    
    % Process the entire data in 5 intervals
    startT = [1,floor(Nframes/5)*[1:4]+1];
    
    for ii = 1:1
        startS = [1,1,startT(ii)];
        Y.video = h5read(DirData,...
            '/data',startS,[Nx,Ny,floor(Nframes/5)],[1,1,1]); 
        %Crop border
        pixSize = 0.78; %um
        border = round(10/pixSize);
        Y.video = Y.video(border:end-border,border:end-border,:); 
        
        %Temporal binarization by summation
        Y.video = uint16(binVideo_temporal(Y.video,opt.ds));
        
        %Save cropped downsampled data
        if ~exist(DirSave)
            mkdir(DirSave);
        end
        
        niftiwrite(Y.video,[DirSave,opt.ID,'_processed'],'compressed',true);
    end    
else
    error('Data Unavailable')
end

end

