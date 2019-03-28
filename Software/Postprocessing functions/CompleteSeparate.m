%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%

function [finalSegments]= CompleteSeparate(seg,AvgArea,minArea)

for n = 1:size(seg,3)
    [paramMask,finalSegments{n}] = separateNeuronsWT(seg(:,:,n),AvgArea,minArea);
    if ~isempty(paramMask)
        maskCOM{n} = paramMask.comSegments;
        maskArea{n} = paramMask.areaSegments;
    end
end

%remove empty cells
finalSegments = finalSegments(~cellfun('isempty',finalSegments)) ;
maskCOM = maskCOM(~cellfun('isempty',maskCOM));
maskArea = maskArea(~cellfun('isempty',maskArea));

if numel(finalSegments)   
    finalSegments = uniqueNeurons(finalSegments,maskCOM,maskArea);
else
    finalSegments = [];
end

end

