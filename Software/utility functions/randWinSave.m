%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function [count] = randWinSave(vid,mask,Dir,name,nameM,Ws,Wt,rp,cp,tp,count,R)

numPatches = numel(rp)*numel(cp)*numel(tp);
% if r = 1, swith row and column indices
if R==1
    tempMat =  rp;
    rp = cp;
    cp = tempMat;
end

% To save ordering of patches. The field 'stat' indicates if the patch was
% saved. Patches with low number of neuron pixels are not saved.
OrderMat = struct('winStart',zeros(1,3),'stat',cell(numPatches,1));
thresh = 50; 
indPatch = 1;

randInd_rp = randperm(numel(rp));
for i = 1:numel(rp)
    rSelected = rp(randInd_rp(i));
    randInd_cp = randperm(numel(cp));
    for j = 1:numel(cp)
        cSelected = cp(randInd_cp(j));
        randInd_tp = randperm(numel(tp));
        for t=1:numel(tp)
            
            tSelected = tp(randInd_tp(t));
            OrderMat(indPatch).winStart = [rSelected,cSelected,tSelected];
            
            winr = [rSelected:rSelected+Ws-1];
            winc = [cSelected:cSelected+Ws-1];
            wint = [tSelected:tSelected+Wt-1];
            tempMask = mask(winr,winc,wint);
            if nnz(max(tempMask,[],3))>thresh
                OrderMat(indPatch).stat = 'true';
                tempVid = vid(winr,winc,wint);
                niftiwrite(tempVid,[Dir,filesep,name,'_',num2str(count),'.nii'],'Compressed',true);
                niftiwrite(tempMask,[Dir,filesep,nameM,'_',num2str(count),'.nii'],'Compressed',true);
                count = count+1;
            else
                OrderMat(indPatch).stat = 'false';
            end
            indPatch = indPatch+1;
            
        end
    end
end
save([Dir,filesep,'OrderMat','_R',num2str(R),'.mat'],'OrderMat');

end
