%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%

function [MaskCenters,finalMasks] = checkSegments(masks,minA)
%This function removes any masks with area less than minA

finalMasks = [];
numMasks = zeros(size(masks,1),size(masks,2));
count = 1;
for k = 1:size(masks,3)
    CC = bwlabel(masks(:,:,k));
    for ii = 1:max(CC(:))
        if nnz(CC==ii)>minA
            finalMasks(:,:,count) = (CC==ii);
            temp = regionprops(CC==ii,'Centroid');
            MaskCenters(count,:) = [temp.Centroid];
            numMasks(CC==ii) = count;
            count = count+1;
        end
    end
end

end

