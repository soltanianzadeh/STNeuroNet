%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function [cen_masks,cen_area] = MaskCOM(masks)

cen_masks = zeros(size(masks,3),2);
for i = 1:size(masks,3)
    if nnz(masks(:,:,i))
        temp =  regionprops(masks(:,:,i),'Centroid','Area');
        [cen_area(i),ind] = max([temp.Area]);
        cen_masks(i,:) = [temp(ind).Centroid];    
    end
end
cen_masks(cen_masks(:,1)==0,:) = [];

end

