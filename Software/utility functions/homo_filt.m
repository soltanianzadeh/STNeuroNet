%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%


function [ img ] =homo_filt( img,sigma )
% Homomorphic filtering

img = log(single(img+1));
for k = 1:size(img,3)
    GlogImg = imgaussfilt(img(:,:,k),sigma,'FilterDomain','spatial','padding','symmetric');
    img(:,:,k) = exp(img(:,:,k)-GlogImg);
end

end

