%% Demo script that processes the neuron probability map inferred by STNeuroNet

addpath(genpath('Software'))

%% Set directories
name = '524691284';
DirProbMap = ['Results',filesep,'ABO',filesep,'Probability map',filesep];
DirData = ['Dataset',filesep,'ABO',filesep];
DirGTMasks = ['Markings',filesep,'ABO',filesep,'Layer275',filesep,'Grader1',filesep];
DirThresh = ['Results',filesep,'ABO',filesep,'Thresholds',filesep];

%% Data order (DO NOT change)
id = [524691284, 531006860,502608215, 503109347,501484643, 501574836,...
501729039, 539670003,510214538, 527048992];

ind = find(id == str2num(name));
%% Set parameters
pixSize = 0.78;         %um
meanR = 5.85;           % neuron radius in um
AvgArea = round(pi*(meanR/pixSize)^2);
ThreshJ = 0.5;

load([DirThresh,'OptParam_Final_JaccardNew_LOO_whitened.mat']);
minArea = minArea(ind);
thresh = ProbThresh(ind);
%% run postprocessing and performance evaluation

[finalSegments,MCOM] = postProcess(DirProbMap,name,[487,487],...
                                        AvgArea,minArea,thresh);
if ~isempty(DirGTMasks)                                    
    [Recall,Precision,F1] = GetPerformance_Jaccard(DirGTMasks,name,finalSegments,ThreshJ);
end

