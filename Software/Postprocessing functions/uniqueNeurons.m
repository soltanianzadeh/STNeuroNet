%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%

function [finalMasks] = uniqueNeurons(masks,COMs,Areas)
%This function identifies unique neurons form a set of maska obtained 
%at different time intervals.

%% check overlap:  
% 1. COM overlap
% 2. Area overlap of components that were not matched in prev step

if iscell(masks)
    temp = cell2mat(cellfun(@(x) size(x,3),masks,'UniformOutput' ,false));
    maxN = max(temp);
    A = zeros(length(masks),maxN);
    
    for ii = 1:length(masks)
        numMasks(ii) = size(masks{ii},3);
        A(ii,1:numMasks(ii)) = Areas{ii};
    end
else
    error('Masks should be saved in a cell')
end

%%%%%%%%%%%%%%%%% 1. Check COMs
uniqueMasks = [];
minD = 5;
for ii = 1:length(COMs)
    matchedComps{ii} = [];
    n = size(COMs{ii},1);
    matchedTo{ii} = zeros(n,length(COMs));
    
    K = removerows([1:length(COMs)]','ind',ii);
    for k = 1:numel(K)
        c1 = COMs{ii}; c2 = COMs{K(k)};
        [~,~,matchIndex,~] = matchCenters(c1,c2,minD);
        if ~isempty(matchIndex)
            matchedComps{ii} = unique([matchedComps{ii},matchIndex(:,1)']); 
            matchedTo{ii}(ismember([1:n]',matchIndex(:,1)),K(k)) = matchIndex(:,2);
        end
    end
    uniqueCOMs{ii} = removerows(COMs{ii},'ind',matchedComps{ii});
    
    uniqueMasks = cat( 3,uniqueMasks,...
        masks{ii}(:,:,~ismember(1:numMasks(ii),matchedComps{ii})) );
end

%%%% From matched neurons, keep the one with mean area size
numNeurons = 1;
finalMasks = zeros(size(masks{1}(:,:,1)));
ind_selectedNeurons = [];   % To avoid saving the same neuron (or the overlapping ones) multiple times
for ii = 1:length(COMs)-1
    
    matchedIndex = matchedTo{ii};
    
    if nnz(matchedIndex) ~=0     %if there is any match
        rowInd = find(sum(matchedIndex,2));
        
        for jj = 1:numel(rowInd)
            selectedA = A(ii,rowInd(jj));
            cols = find(matchedIndex(rowInd(jj),:));
            cc = matchedIndex(rowInd(jj),cols);
            IND = sub2ind(size(A),ii,rowInd(jj));   %index in the total set of neurons
            
            for k = 1:numel(cols)
                selectedA = [selectedA,A(cols(k),cc(k))];
%                 tempSelected = [tempSelected,sub2ind(size(A),cols(k),cc(k))];
                IND = [IND,sub2ind(size(A),cols(k),cc(k))];
            end  
           meanA = mean(selectedA);
           [~,ind] = min(abs(selectedA-meanA)); %index within the subselected neurons
           
           if ~ismember(IND(ind),ind_selectedNeurons)
                [r,c] = ind2sub(size(A),IND(ind));
                finalMasks(:,:,numNeurons) = masks{r}(:,:,c);
                numNeurons = numNeurons+1;
                ind_selectedNeurons = unique([ind_selectedNeurons,IND]);
           else           %Check the next candidate to avoid cases where a selected mask is shared among different iterations
               selectedA(ind)=0;
               [~,ind] = min(abs(selectedA-meanA));
                if ~ismember(IND(ind),ind_selectedNeurons)
                    [r,c] = ind2sub(size(A),IND(ind));
                    finalMasks(:,:,numNeurons) = masks{r}(:,:,c);
                    numNeurons = numNeurons+1;
                    ind_selectedNeurons = unique([ind_selectedNeurons,IND]);  
                end
           end
           
        end
    end
end

%%%%%%%%%%%%%%%%% 1. Check area overlap of uniqueCOMs+the already analysed
%%%%%%%%%%%%%%%%% neurons
minOverlapThresh = 0.75; %if overlapping is not significant, it's unique neurons

uniqueMasks = cat(3,uniqueMasks,finalMasks);
uniqueMasks = reshape(uniqueMasks,[],size(uniqueMasks,3));

% ------------ calculate overlaps
OverlapArea = (uniqueMasks'*uniqueMasks);
nr = size(uniqueMasks,2);
OverlapArea(1:nr+1:nr^2) = 0;

% make percentage overlap matrix: Row i is the %overlap area of neuron i
% with other neurons
NeuronAreas = sum(uniqueMasks,1)';
OverlapP = bsxfun(@rdivide,OverlapArea,NeuronAreas);
OverlapP(1:size(uniqueMasks,3)+1:size(uniqueMasks,3)^2) = 0;

  % find overlapping neurons
FF = OverlapP > minOverlapThresh;        

%%  % 1.find cases where a mask encompasses multiple masks. These will be
  % entirely removed
indBigMask = find(sum(FF,1)>1);

%%  % 2.find cases which a mask is highly overlapped with only one other mask.
  % If the percentage overlap of two neurons is high, the one with less 
  % overlap will be kept. -> new: the one with higher %overlap is kept
FF2 = FF;
FF2(:,indBigMask) = 0; 

% [indTwoMasks,matchTwoMasks] = find(and(triu(FF2),tril(FF2)') + and(triu(FF2)',tril(FF2)));
% FF3 = FF2;
% FF3(and(triu(FF2),tril(FF2)') + and(triu(FF2)',tril(FF2))==1) = 0;

%revised 10/26/2018
FF2(indBigMask,:) = 0;
[indTwoMasks,matchTwoMasks] = find(FF2);

 % keep unique pairs
 uniquePairs = [];
 cnt = 1;
while ~isempty(matchTwoMasks)
    ind = find(indTwoMasks==matchTwoMasks(cnt));
    uniquePairs = [uniquePairs,[indTwoMasks(cnt);matchTwoMasks(cnt)]];
    indTwoMasks([ind,cnt])=[];
    matchTwoMasks([ind,cnt])=[];
%     cnt = cnt+1;
end

if ~isempty(uniquePairs)
    compAreas = [NeuronAreas(uniquePairs(1,:))';
             NeuronAreas(uniquePairs(2,:))'];
%     [~,ind] = min(compAreas,[],1);
    intersectA = sum(uniqueMasks(:,uniquePairs(1,:)).*uniqueMasks(:,uniquePairs(2,:)),1);
    compAreas = compAreas./intersectA;
    [~,ind] = max(compAreas,[],1);
    ind2mRemove = uniquePairs(sub2ind( size(uniquePairs),ind,1:size(uniquePairs,2) ));
else
    ind2mRemove = [];
end

%% % Remove the candidate masks to get the final masks
finalMasks = removerows(uniqueMasks',[indBigMask,ind2mRemove])';
finalMasks(:,sum(finalMasks,1)==0) = [];
finalMasks = reshape(finalMasks,size(masks{1},1),size(masks{1},2),[]);

% remove any potential small areas due to the subtraction in step3
cnt = 1;
for ii = 1:size(finalMasks,3)
    temp = bwareaopen(finalMasks(:,:,ii),10);
    if nnz(temp)
        fMasks(:,:,cnt) = temp;
        CC = regionprops(temp,'Centroid','Area');
        newCOM(cnt,:) = CC.Centroid;
        cnt=cnt+1;
    end
end
finalMasks=fMasks;

%% check COMs 
discardInd = [];
for ii = 1:length(newCOM)
    comDist = bsxfun(@minus,newCOM(ii,:),newCOM);
    comDist = sum(comDist.^2,2);
    ind = find(comDist<minD);
    if numel(ind>1)
        Areas = nnz(finalMasks(:,:,ind));
        [~,keepInd] = min(abs(Areas-mean(Areas)));
        discardInd = [discardInd,removerows(ind,'ind',keepInd)'];
    end
end
finalMasks(:,:,discardInd) = [];
%% Check again for overlaps 
uniqueMasks = reshape(double(finalMasks),size(finalMasks,1)*size(finalMasks,2),[]);
OverlapArea = (uniqueMasks'*uniqueMasks);
nr = size(uniqueMasks,2);
OverlapArea(1:nr+1:nr^2) = 0;

% make percentage overlap matrix: Row i is the %overlap area of neuron i
% with other neurons
NeuronAreas = sum(uniqueMasks,1)';
OverlapP = bsxfun(@rdivide,OverlapArea,NeuronAreas);
  % find overlapping neurons
FF = OverlapP > minOverlapThresh;   

%remove the smaller masks
[indS,~] = find(FF);
finalMasks = removerows(uniqueMasks',indS)';
finalMasks = reshape(finalMasks,size(masks{1},1),size(masks{1},2),[]);
 
end
