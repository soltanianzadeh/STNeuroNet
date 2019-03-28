%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.


function [Recall, Precision, F1] = multiple_postProcessJaccard(SZ,DirProbMap,DirGTMasks,name,AvgArea,minArea,thresh,maxDist)

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
seg = seg(1:x,1:y,:,2);

Recall = zeros(numel(thresh),numel(minArea));
Precision = Recall; F1 = Recall;
for t = 1:numel(thresh)
    segThresh = seg>=thresh(t);

    % Apply instance neuron separation
    InitSegments = CompleteSeparate(segThresh,AvgArea,minArea(1));
    for a = 1:numel(minArea)
       
        if ~isempty(InitSegments)
            [MaskCenters,Masks] = checkSegments(InitSegments,minArea(a));
        else
            disp('No Neurons were identified.');
        end
        
        [Recall(t,a),Precision(t,a),F1(t,a)] = GetPerformance_Jaccard(DirGTMasks,name,Masks,maxDist);
    end
    
end

end

