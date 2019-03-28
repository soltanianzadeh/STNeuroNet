%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.
%

function [matchRef,matchCheck,matchIndex,DIST] = matchCenters(coord1,coord2,maxDist)
%   This function matches two sets of points using the maxDist as the 
%   maximum separation for matching points.
%
%   in each input, the first columns are the X indices and the second
%   columns are the Y indices.
%   I shows which input was chosen as the reference object:
%          I = 1: reference is input1, otherwise reference is input2
%   matchRef: Coordinates of matched neurons in reference object
%   matchChech: Coordinates of matched neurons in search object
%   matchIndex(:,1): index of matched neurons in reference object
%   matchIndex(:,2): index of matched neurons in search object
%   DIST: minimum distance between nearest neighbors

nNeurons1 = size(coord1,1);
nNeurons2 = size(coord2,1);
matchIndex = [];matchRef = []; matchCheck = []; DIST = [];

I = 1;
N = nNeurons1;
if I == 1   
    ref = coord1;
    checkDay = coord2;
    nNeuronscheck = nNeurons2;
    ptCloud = pointCloud([coord2,ones(nNeurons2,1)]);
else
    ref = coord2;
    checkDay = coord1;
    nNeuronscheck = nNeurons1;
    ptCloud = pointCloud([coord1,ones(nNeurons1,1)]);
end

count = 1;
for n = 1:N
    point = [ref(n,:),1];
    
    [index,D] = findNearestNeighbors(ptCloud,point,1);
    
    if D <= maxDist
        matchRef(count,:) = ref(n,:);
        matchCheck(count,:) = checkDay(index,:);
        matchIndex(count,1) = n;    % first column is index of ref,
        matchIndex(count,2) = index; %second col is matched index of checkDay
        DIST(count,1) = D;
        count = count+1;
    end
          
end

% Postprocessing: getting rid of duplicate assignments
if ~isempty(matchIndex)
    UniqueMatch = unique(matchIndex(:,2));
    for u = 1:numel(UniqueMatch)
        row = find(matchIndex(:,2)== UniqueMatch(u));
        if numel(row) > 1

            index = knnsearch(matchRef(row,:),matchCheck(row,:));

            DiscardIndex = find(row ~= row(index));
            matchIndex = removerows(matchIndex,'ind',row(DiscardIndex));
            matchRef = removerows(matchRef,'ind',row(DiscardIndex));
            matchCheck = removerows(matchCheck,'ind',row(DiscardIndex));
            DIST = removerows(DIST,'ind',row(DiscardIndex));

        end
    end
%--------------------------------------------------------------------------
% Do another round of matching to get possibly missed matching neurons
% -------------------------------------------------------------------------
    idref = find(~ismember(1:N,matchIndex(:,1)));
    ref = ref(idref,:);

    idcheck = find(~ismember(1:nNeuronscheck,matchIndex(:,2)));
    checkDay = checkDay(idcheck,:);
    ptCloud = pointCloud([checkDay,ones(numel(idcheck),1)]);

    count = size(DIST,1)+1;
    for n = 1:numel(idref)
        point = [ref(n,:),1];

        [index,D] = findNearestNeighbors(ptCloud,point,1);

        if D <= maxDist
            matchRef(count,:) = ref(n,:);
            matchCheck(count,:) = checkDay(index,:);
            matchIndex(count,1) = idref(n);    % first column is index of ref,
            matchIndex(count,2) = index; %second col is matched index of checkDay
            DIST(count,1) = D;
            count = count+1;
        end

    end

    % Postprocessing: getting rid of duplicate assignments
    UniqueMatch = unique(matchIndex(:,2));
    for u = 1:numel(UniqueMatch)
        row = find(matchIndex(:,2)== UniqueMatch(u));
        if numel(row) > 1

            index = knnsearch(matchRef(row,:),matchCheck(row,:));

            DiscardIndex = find(row ~= row(index));
            matchIndex = removerows(matchIndex,'ind',row(DiscardIndex));
            matchRef = removerows(matchRef,'ind',row(DiscardIndex));
            matchCheck = removerows(matchCheck,'ind',row(DiscardIndex));
            DIST = removerows(DIST,'ind',row(DiscardIndex));
        end
    end
end

end

