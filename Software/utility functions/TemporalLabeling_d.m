%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

function [Label,stat] = TemporalLabeling_d(masks,traces,initSpikeTimes, stat, opt)
fs = opt.fs;
tau = opt.tau;

win = 30*fs;
amp = 0.15;
t = 0:1/fs:1-1/fs;
dFF = (exp(1/(tau*fs))-1)*exp(-t/tau);
dFF = dFF/dFF(1)*amp;

[x,y,N] = size(masks);
T = size(traces,2);
Label = zeros(x,y,T);

tracesExtended = cat(2,flip(traces(:,1:win/2),2),traces,flip(traces(:,T-win/2:T),2));
   
for t = 1:T
    backTrace(:,t) = median(tracesExtended(:,t:t+win),2);
    stdTrace(:,t) = std(tracesExtended(:,t:t+win),1,2);
end

tracesExtended = cat(2,traces,flip(traces(:,T-length(dFF):T),2));
backTraceExtended = cat(2,backTrace,flip(backTrace(:,T-length(dFF):T),2));

traces =(tracesExtended-backTraceExtended);
F0 = median(backTrace,2);

dprime = traces./median(stdTrace,2)*sqrt(0.5*tau*fs);

thresh = stat.thresh+0.2;
Pd = stat.Pd;
mu = 0.5*(amp^2)./F0*tanh(0.5/(tau*fs))*(1-exp(-2*(2*numel(dFF)+1)/(tau*fs)));
st = sqrt(2*mu);
lc = mu+st*norminv(1-Pd);

%get filtered trace
T = size(traces,2);
activation = zeros(N,T);
for k = 1:N
     for i = 1:(T-length(dFF))
        L(k,i) = F0(k)*sum(-dFF+(traces(k,i:i+length(dFF)-1)/F0(k)+1).*(log(dFF+1)));
     end
     thresh = stat.thresh+0.2;
    %Check if empty, lower the threshold
    while nnz(activation(k,:))==0
        thresh = thresh-0.2;
        for i = 7:length(L)-7
            if L(k,i) == max(L(k,i-6:i+6)) && dprime(k,i)>=thresh
                actTimes = i;
                for jj = 0:2    %keep active until 0.5s after spike
                    actTimes = [actTimes,min(T,i+jj)];
                end
                activation(k,actTimes) =1;
            end
        end
   
    end
end

%overwrite with previously determined spike times
if ~isempty(initSpikeTimes)
    Spike = ~cellfun('isempty',initSpikeTimes);
    if nnz(Spike)
        
        activation(Spike==1,:) = 0;
        indS = find(Spike);
        for k = 1:nnz(Spike)
            actTimes = [];
            initSpikeTimes{indS(k)} = round(initSpikeTimes{indS(k)});
            for jj = 0:2    %keep active until 0.5s after spike
                actTimes = [actTimes,min(T,initSpikeTimes{indS(k)}+jj)];
            end
            actTimes = unique(actTimes);
            activation(indS(k),actTimes) = 1;
        end
        
    end
end

%Temporal Labels
for k = 1:N
    ind = find(activation(k,:));
    Label(:,:,ind) = masks(:,:,k) + Label(:,:,ind);
    stat(k).indNeuron = k;
    stat(k).indTime = ind;   
end
Label = uint8(logical(Label));

end

