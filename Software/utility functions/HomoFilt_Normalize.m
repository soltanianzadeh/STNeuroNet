%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function [imgFinal] = HomoFilt_Normalize(vid,DirSave,name,s,NormVals)
% - vid can be either the directory pointing to the data or the video
% itself (for use within matlab)
% - DirSave is the directory to save processed data
% - name is the name of data used for both read and write
% - s is the standard deviation (in pixels) for the gaussian filter used in the filtering
% process
% - NormVals is 1 1x2 vector of mean and standard deviation to use for data
% normalziation. Set the second element to 0 to use its own standard
% deviation

%%  Initialize missing parameters
if nargin < 5
    NormVals = [0,0];
end

if nargin < 4
    s = 30;
end

if nargin <3
    error('Not enough input variable.')
end

if isstring(name)
    name = char(name);
elseif ~ischar(name)
    error('Wrong format for name.')
end
%% Check which type vid is. If it's a char, then it's pointing to the video 
% file location and name (saved in .nii format)
if isa(vid,'char') || isstring(vid)
    if isstring(vid)
        vid = char(vid);
    end
    vid = niftiread(vid);
end

%%
% Apply homorphic filtering
imgFinal = homo_filt(vid,s);

% Standardize by the standard deviation
stData = std(imgFinal(:));
imgFinal = imgFinal - NormVals(1);
if NormVals(2)== 0
    imgFinal = imgFinal/stData;
else
    imgFinal = imgFinal/NormVals(2);
end

%% save data for later use
if ~exist(DirSave)
    mkdir(DirSave)
end

niftiwrite(imgFinal,[DirSave,filesep,name,'_dsCropped_HomoNorm'],'compressed',true);

end

