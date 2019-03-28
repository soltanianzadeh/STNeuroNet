%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.

function imgs = prepareNeurofinder(opt,DirData,DirSave)

ID = ['0',opt.ID(1),'.',opt.ID(2:end)];

% Crop borders used to eliminate black borders
borderx = [4,24,0,48]; 
bordery = [4,4,0,16];

       
if strcmp(opt.type,'test')
    name = ['neurofinder.',ID,'.',opt.type];
else
    name = ['neurofinder.',ID];
end
    
if exist([DirData,name])

    files = dir([DirData,name,filesep,'images',filesep,'*.tiff']);

    for i = 1:length(files)
        fname = strcat([DirData,name,filesep,'images',filesep, files(i).name]);
        imgs(:,:,i) = imread(fname);
    end

    %Crop border
    ind = str2num(opt.ID(1));
    if ismember(ind,[1,2,4])
        imgs = imgs(bordery(ind)+1:end-bordery(ind),borderx(ind)+1:end-borderx(ind),:);    
    else
      error('Unknown data ID.');
    end
    
    % downsamling 
    imgs = binVideo_temporal(imgs,opt.ds);

    %save cropped and downsampled data
    if ~exist(DirSave)
        mkdir(DirSave)
    end

    niftiwrite(imgs,[DirSave,opt.ID,'_processed'],'compressed',true)
else
    error('Data not available.');
end

end

