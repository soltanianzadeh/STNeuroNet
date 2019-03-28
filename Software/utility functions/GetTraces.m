%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function FinalTraces = GetTraces(vid, FinalMasks)

    N = size(FinalMasks,3);
    finalSegments = reshape(FinalMasks,[],N);
    [~,~,T] = size(vid);
    vid = reshape(vid,[],T);

    traces = zeros(N,T);
    for kk = 1:N
         traces(kk,:) = double(sum(vid(finalSegments(:,kk)==1,:),1));
    end
    
    %Final demixed-fluorescnece traces
    FinalTraces = demixTraces_small(traces,vid,FinalMasks);

    % Cases that have negative traces replace with original traces
    indNegative = find(sum(FinalTraces,2)<0);
    if ~isempty(indNegative)
        FinalTraces(indNegative,:) = traces(indNegative,:);
    end
    
    % Traces are scaled: Scale back to original values
    Fbefore  = median(traces,2);
    Fafter = median(FinalTraces,2);
    ScaleBack = Fbefore./Fafter;
    FinalTraces = bsxfun(@times,FinalTraces,ScaleBack);    
    
end

