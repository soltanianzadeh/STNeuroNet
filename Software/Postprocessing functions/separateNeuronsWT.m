%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%

function [paramSegments,finalSegments] = separateNeuronsWT(seg,avgA,minArea)

if max(seg(:))==1
    CC = bwlabel(seg,4);    
else
    CC = seg;
end

cnt=1;
if max(CC(:))>1
    neuronSegments = [];
    for k = 1:max(CC(:))
        A = regionprops(CC==k,'Area');
        Kmax = (A.Area/avgA);

        if A.Area>avgA %Kmax>1
            BW = (CC==k);
            D = -bwdist(~BW); 
            D = imfilter(D,fspecial('average',5),'same');
            D(~BW) = -Inf;
            L = watershed(D);
            for n=2:max(L(:))
                if nnz(L==n)>minArea
                neuronSegments(:,:,cnt) = L==n;
                cnt=cnt+1;
                end
            end
        else
            if nnz(CC==k)>minArea
            neuronSegments(:,:,cnt) = CC==k;
            cnt=cnt+1;
            end
        end

    end

finalSegments = neuronSegments;
if ~isempty(finalSegments)
    [paramSegments.comSegments,paramSegments.areaSegments] = MaskCOM(finalSegments);
else
    paramSegments = [];
end
    
else
    comSegments = [];
    finalSegments = [];
    paramSegments = [];
end

end

