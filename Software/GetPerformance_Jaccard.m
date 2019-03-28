%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.


function [Recall, Precision, F1] = GetPerformance_Jaccard(DirGTMasks,name,Masks,Thresh)
% - Masks is a d1xd2xN scalar matrix of inferred masks
% - Thresh is vector for Jaccard values used to determine if two overlapping masks
% match

if isstring(name)
    name = char(name);
elseif ~ischar(name)
    error('Wrong format for name')
end

% Load GT Masks and get their COM. GT Masks are assumed to have been saved
% as binary P1xP2xN matrices, where each N neuron's masks is saved as
% separate dimension
f = dir([DirGTMasks,filesep,'*_',name,'.mat']);
if ~isempty(f)
    MaskName = [f.folder,filesep,f.name];
else
    error('GT Mask not found.');
end

load(MaskName,'FinalMasks'); 
NGT = size(FinalMasks,3);
NMask = size(Masks,3);

% match Neurons
Dmat = JaccardDist(FinalMasks,Masks);
Recall = zeros(1,numel(Thresh));
Precision = Recall;
for t = 1 :numel(Thresh)
    D = Dmat;
    D(D> 1- Thresh(t)) = Inf;   % no connection between cases with IoU<thresh or equavalantly, dist>1-JaccardThresh
    [m,~] = Hungarian(D);
    [match_1,match_2] = find(m);
    Recall(t) = numel(match_1)/NGT;
    Precision(t) = numel(match_1)/NMask;
end

F1 = 2*Recall.*Precision./(Recall+Precision);

end

