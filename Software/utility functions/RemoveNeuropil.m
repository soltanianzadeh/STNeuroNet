%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function [FinalTraces] = RemoveNeuropil(video,masks,traces,startInd,pxsize)
    % Remove neuropil contamination of newly added masks, which start from startInd.
    % Neuropil signal is the average in annulus of 5um around the cellular ROI, 
    % excluding pixels from any other ROIs
    
    h = ceil(5/pxsize);    %in pixels
       
    FinalTraces = traces;
    N = size(FinalTraces,3);
    for k = startInd:size(masks,3)
        temp = masks(:,:,k);
        CC = regionprops(temp,'Centroid','BoundingBox');
        cent = round(CC.Centroid);
        bbox = CC.BoundingBox;
        hNeuron = round(max(bbox(3:4))/2);
        
        %Get neuropil mask
        hT = h+hNeuron;
        r1 = max(1,cent(2)-hT); r2 = min(cent(2)+hT,size(masks,1));
        c1 = max(1,cent(1)-hT); c2 = min(cent(1)+hT,size(masks,2));
        
        y1 = hT-sign(r1-cent(2)+hT)*(r1-cent(2)+hT);
        y2 = hT-(-r2+cent(2)+hT);
        x1 = hT-sign(c1-cent(1)+hT)*(c1-cent(1)+hT);
        x2 = hT-(-c2+cent(1)+hT);
        
        [x,y] = meshgrid(-x1:x2,-y1:y2);
        NeuropilMask = (x.^2+y.^2) <=hT.^2;
        allMasks = max(masks(r1:r2,c1:c2,:),[],3);
        NeuropilMask(allMasks==1) = 0;
        
        %Get neuropil signal
        NeuropilMask = cast(NeuropilMask,'like',video);
        tempvideo = video(r1:r2,c1:c2,:);
        neuropilSig = bsxfun(@times,reshape(tempvideo,[],size(video,3)),NeuropilMask(:));
        if nnz(NeuropilMask)
            neuropilSig = sum(neuropilSig,1)/nnz(NeuropilMask);
        else
            neuropilSig = 0;
        end
        
        %Get neuron signal
        temp = cast(temp(r1:r2,c1:c2),'like',video);
        tempT = bsxfun(@times,reshape(tempvideo,[],size(video,3)),temp(:));
        FinalTraces(k,:) = sum(tempT,1)/nnz(temp);

        %Subtract neuropil signal
        FinalTraces(k,:) = FinalTraces(k,:)-0.75*neuropilSig;
        
        %Scale back to photon counts
        FinalTraces(k,:) = FinalTraces(k,:)*nnz(masks(:,:,k));
    end
    
end

