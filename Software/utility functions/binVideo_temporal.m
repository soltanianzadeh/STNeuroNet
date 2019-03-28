%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function binnedVideo = binVideo_temporal( vid, scale )

[x,y,T] = size(vid);
nT = floor(T/scale);

vid = reshape(vid(:,:,1:nT*scale),x,y,scale,[]);
binnedVideo = squeeze(sum(vid,3));

end

