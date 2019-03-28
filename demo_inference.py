#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
shows how to apply a trained network on a dataset from Allen

@author: Somayyeh Soltanian-Zadeh
%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast and robust  
% active neuron segmentation in two-photon calcium imaging using spatio-temporal
% deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.

"""
import os
import sys
import niftynet
import math
import numpy as np
from pathlib import Path
import scipy.io as sio

import STNeuroNetPkg
import matlab

matlabLib = STNeuroNetPkg.initialize()

# List of data IDs for Layer275 (DO NOT change the current ordering)
# Order is important for correct mapping between test data and the cross-validation-based trained networks
L = ['524691284', '531006860','502608215', '503109347','501484643', '501574836',
     '501729039', '539670003','510214538', '527048992']

# Data to process
name = ['524691284']
# dataType should be either 'Cross Validation' for data from Layer275, or 
# 'All' for Layer175 recordings
LayerType = 'Layer275'

if LayerType == 'Layer275':
    dataType = 'Cross Validation'
    endFile = str(L.index(name[0])+1)
    ind = L.index(name[0])
    ThreshFile = 'OptParam_Final_JaccardNew_LOO_whitened.mat'
    AreaName = 'minArea'
else:
    dataType = 'All'
    endFile = ''
    ind = 0
    ThreshFile = 'OptParam_Jaccard_ABO_all275Whitened.mat'
    AreaName = 'minA'

## Set directories
dirpath = os.getcwd()
DirData = os.path.join(dirpath,'Dataset','ABO')
DirSaveData = os.path.join(dirpath,'Results','ABO','data')
DirSave = os.path.join(dirpath,'Results','ABO','Probability map')
DirModel = os.path.join(dirpath,'models','ABO','Trained Network Weights',dataType,endFile)
DirMask = os.path.join(dirpath,'Markings','ABO',LayerType,'Grader1')
DirSaveMask = os.path.join(dirpath,'Results','ABO','Test Masks')
DirThresh = os.path.join(dirpath,'Results','ABO','Thresholds')

#% Set parameters
pixSize = 0.78         #um
meanR = 5.85           # neuron radius in um
AvgArea = round(math.pi*(meanR/pixSize)**2)
Thresh = 0.5           # IoU threshold for matching
SZ = matlab.double([487,487])        #x and y dimension of data

## read saved threshold values
optThresh = sio.loadmat(os.path.join(DirThresh,ThreshFile))
thresh = matlab.single([optThresh['ProbThresh'][0][ind]])
minArea = matlab.single([optThresh[AreaName][0][ind]])

## Check if HomoFiltered downsampled data is available
data_file = Path(os.path.join(DirSaveData, name[0]+'_dsCropped_HomoNorm.nii.gz'))
if not data_file.exists():
    data_file = os.path.join(DirData, name[0]+'_processed.nii.gz')
    s = 30
    matlabLib.HomoFilt_Normalize(data_file,DirSaveData,name[0],s,nargout=0)
#%%
## Run data through the trained network
# first create a new config file based on the current data
f = open("demo_config_empty.ini")
mylist = f.readlines()
f.close()

indPath = []
indName = []
indNoName = []
indSave = []
indModel = []
for ind in range(len(mylist)):
    if mylist[ind].find('path_to_search')>-1:
        indPath.append(ind)
    if mylist[ind].find('filename_contains')>-1:
        indName.append(ind)
    if mylist[ind].find('filename_not_contains')>-1:
        indNoName.append(ind)        
    if mylist[ind].find('save_seg_dir')>-1:
        indSave.append(ind)    
    if mylist[ind].find('model_dir')>-1:
        indModel.append(ind) 
        
# write path of data
mystr = list(mylist[indPath[0]])
mystr = "".join(mystr[:-1]+ list(DirSaveData) + list('\n'))
mylist[indPath[0]] = mystr

# write name of data
mystr = list(mylist[indName[0]])
#temp = mystr[:-1]
#for ind in range(len(name)):
#    temp = temp + list(name[ind]) + list(',')
mystr = "".join(mystr[:-1]+ list('_dsCropped_HomoNorm') + list('\n'))
mylist[indName[0]] = mystr

# exclude any other data not listed in names
AllFiles = os.listdir(DirSaveData)
AllNames = []
for ind in range(len(AllFiles)):
    if AllFiles[ind].find('_dsCropped_HomoNorm')>-1:
        AllNames.append(AllFiles[ind][:AllFiles[ind].find('_dsCropped_HomoNorm')])
        
excludeNames = [c for c in AllNames if c not in name]    
if len(excludeNames):   
    mystr = list(mylist[indNoName[0]])
    temp = mystr[:-1] 
    for ind in range(len(excludeNames)):
        temp = temp + list(excludeNames[ind]) + list(',')
    mystr = "".join(temp[:-1]+ list('\n'))
    mylist[indNoName[0]] = mystr

#write where to save result
mystr = list(mylist[indSave[0]])
mystr = "".join(mystr[:-1]+ list(DirSave) + list('\n'))
mylist[indSave[0]] = mystr
#write where model is located
mystr = list(mylist[indModel[0]])
mystr = "".join(mystr[:-1]+ list(DirModel) + list('\n'))
mylist[indModel[0]] = mystr
# Write to a new config file
f = open('config_inf.ini','w')
f.write(''.join(mylist))
f.close()

#%%
sys.argv=['','inference','-a','net_segment','--conf',os.path.join('config_inf.ini'),'--batch_size','1']
niftynet.main()

#%%
## Postprocess to get individual neurons
saveTag = True
for ind in range(len(name)):
    print('Postprocessing data {} ...'.format(name[ind]))
    Neurons = matlabLib.postProcess(DirSave,name[ind],SZ,AvgArea,minArea,thresh,nargout=2)
    if saveTag:
        print('Saving results of {} ...'.format(name[ind]))
        sio.savemat(os.path.join(DirSaveMask,name[ind]+'_neurons.mat'),{'finalSegments': np.array(Neurons[0],dtype=int),'MaskCenters':np.array(Neurons[1])})
    ## Compare performance to GT Masks if available
    if DirMask is not None:
        print('Getting performance metrics for {} ...'.format(name[ind]))
        scores = matlabLib.GetPerformance_Jaccard(DirMask,name[ind],Neurons[0],Thresh,nargout=3)
        print('data: {} -> recall: {}, precision: {}, and F1 {}:'.format(name[ind],int(10000*scores[0])/100,int(10000*scores[1])/100,int(10000*scores[2])/100))

matlabLib.terminate()



