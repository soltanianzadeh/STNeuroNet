%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function binnedVideo = binTraces_temporal( traces, scale )

[n,T] = size(traces);
nT = floor(T/scale);
binnedVideo = zeros(n,nT);

for i = 1:nT
    binnedVideo(:,i) = sum(traces(:,scale*(i-1)+1:scale*i),2);
end
end

