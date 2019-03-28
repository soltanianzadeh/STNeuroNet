%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function FinalTraces = demixTraces_small(traces, vid, masks)

% This function iteratively applies the demixing function to overlapping neurons
% which reduces the computational time compared to applyin the demix
% function to all neurons at once

[N, T] = size(traces);
[x, y,~] = size(masks);
P = x * y;

 if ndims(vid)== 2
     vid = reshape(vid,x,y,T);
 end

 tic
 mask_flatten = reshape(masks,P,[]);
 
 mask_overlap = triu(mask_flatten'*mask_flatten);
 mask_overlap(1:N+1:N^2) =  0;
 mask_overlap = mask_overlap>0;

 FinalTraces = traces;
 cnt = 1;
 while nnz(mask_overlap)

     overlap_indeces = find(mask_overlap(cnt,:));
          
     if ~isempty(overlap_indeces)
         mask_overlap(cnt,:) = 0;
         for k = 1:numel(overlap_indeces)
             newInd = find(mask_overlap(overlap_indeces(k),:));
             overlap_indeces = [overlap_indeces,newInd];
             
             mask_overlap(overlap_indeces(k),:) = 0;
         end
         overlap_indeces = unique(overlap_indeces);
                 
         
         tempMask = masks(:,:,[cnt,overlap_indeces]);
         
        temp = regionprops(max(tempMask,[],3),'boundingbox');
        ux = max(round(temp.BoundingBox(1)),1); uy = max(round(temp.BoundingBox(2)),1);
        wx = floor(temp.BoundingBox(3))-1; wy = floor(temp.BoundingBox(4))-1;   
        
        tempvid = vid(uy:uy+wy,ux:ux+wx,:);
        [FinalTraces([cnt,overlap_indeces],:),~] = ...
            demixTraces(traces([cnt,overlap_indeces],:),tempvid,tempMask(uy:uy+wy,ux:ux+wx,:));        
     end
     
     cnt = find(sum(mask_overlap,2),1,'first');
 end
 
toc
end

