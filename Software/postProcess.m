%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.

function [finalSegments, MaskCenters,t] = postProcess(DirProbMap,name,SZ,AvgArea,minArea,thresh)
% - DirData is the directory to the .nii.gz file with cropped border
% - DirProbMap is the directory to where STNeuroNet results were saved
% - name is common between data and STNeuroNet probability map 

if isstring(name)
    name = char(name);
elseif ~ischar(name)
    error('Wrong format for name')
end

x = SZ(1); y = SZ(2);

% Read saved STNeuroNet result
probName = [DirProbMap,filesep,name,'_niftynet_out.nii.gz'];
if exist(probName)
    seg = niftiread(probName);
else
    error('Neuron probability map (output of STNeuroNet) not found.')
end
tic
seg = seg(1:x,1:y,:,2);
seg= seg>=thresh;

% Apply instance neuron separation
InitSegments = CompleteSeparate(seg,AvgArea,minArea);
if ~isempty(InitSegments)
    [MaskCenters,finalSegments] = checkSegments(InitSegments,minArea);
else
    disp(['No Neurons were identified.']);
end
t = toc;
end

