#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Demo to run inference on neurofinder test data
%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

@author: Somayyeh Soltanian-Zadeh

"""
import os
import sys
import niftynet
import numpy as np
from pathlib import Path
import scipy.io as sio

import STNeuroNetPkg
import matlab
matlabLib = STNeuroNetPkg.initialize()

#%% Fields to be determined by user:
# Data to process. Choose from '100', '101', '200', '201', '400', and '401'
n = '400'

# dataType should be either 'test' or 'train'
datatype ='test'

# Which network to use: 'neurofinder', 'Grader1', 'Allen', 'All_Allen', or 'ABO_Neuro'
networkType = 'Grader1'

# Which marking used for training: 'neurofinder' or 'Grader1'
# (only applicable to 'neurofinder' and 'Grader1' networkTypes)
markingType = 'Grader1'

#%% Setting parameters
Thresh = 0.5           # IoU threshold for matching

IDmap = {'100': 0,
         '101': 1,
         '200': 2,
         '201': 3,
         '400': 4,
         '401': 5
         }

meanArea ={'100': 200,
         '101': 200,
         '200': 120,
         '201': 120,
         '400': 100,
         '401': 100
         }

sp_window = {'100': (504,504,120),
             '101': (504,504,120),
             '200': (504,464,120),
             '201': (504,464,120),
             '400': (480,416,120),
             '401': (480,416,120)
             }

scale_factor = {'100': 1,
                '101': 1,
                '200': 1.17,
                '201': 1.17,
                '400': 1,
                '401': 1.3
                }      #needed for difference in pixel size between data

name = [n]
AvgArea = meanArea[n] #pixels
SW = str(sp_window[n])


if networkType == 'Allen':
    subDir = 'ABO'
    subDir2 = 'All'
    threshFile = 'OptParam_Jaccard_ABO_all275Whitened.mat'
    AreaName = 'minA'
elif networkType == 'All_Allen':
    subDir = 'ABO'
    subDir2 = 'AllABO'
    threshFile = 'OptParam_Jaccard_ABO_allWhitened.mat'
    AreaName = 'minAreaNF'       
elif networkType == 'ABO_Neuro':
    subDir = networkType
    subDir2 = ''
    threshFile = 'OptParam_Jaccard_AllenNeuro.mat'
    AreaName = 'minAreaNF'
else:
    subDir = 'Neurofinder'
    subDir2 = markingType
    AreaName = 'minA'
    if markingType == 'neurofinder':
        threshFile = 'OptParam_JaccardNew_nf_All.mat'
    else:
        threshFile = 'OptParam_JaccardNew_G1_All.mat'
        
## Set directories
dirpath = os.getcwd()
DirData = os.path.join(dirpath,'Dataset','Neurofinder',datatype)
DirSaveData = os.path.join(dirpath,'Results','Neurofinder','data',datatype)
DirSave = os.path.join(dirpath,'Results','Neurofinder','Probability map')
DirModel = os.path.join(dirpath,'models',subDir,'Trained Network Weights',subDir2)
DirMask = os.path.join(dirpath,'Markings','Neurofinder',datatype,'Grader1')
DirSaveMask = os.path.join(dirpath,'Results','Neurofinder','Test Masks')
DirThresh = os.path.join(dirpath,'Results',subDir,'Thresholds')

## Check if save direcotries exist
if not os.path.exists(DirSaveMask):
    os.mkdir(DirSaveMask)
if not os.path.exists(DirSaveData):
    os.mkdir(DirSaveData)
    

## read saved threshold values
optThresh = sio.loadmat(os.path.join(DirThresh,threshFile))
thresh = matlab.double([optThresh['ProbThresh'][0][0]])
if networkType=='ABO_Neuro':
    # min area from um**2 -> pixels
    minArea = matlab.double([((1/scale_factor[n])**2)*optThresh[AreaName][0][0]])
elif networkType == 'Allen':
    # min area from 0.78 um/pixels to pixels for each dataset
    minArea = matlab.double([((0.78/scale_factor[n])**2)*optThresh[AreaName][0][0]])
else:
    minArea = matlab.double([optThresh[AreaName][0][IDmap[n]]])

#%% Check if HomoFiltered downsampled data is available
data_file = Path(os.path.join(DirSaveData, name[0]+'_dsCropped_HomoNorm.nii.gz'))
NormVals = matlab.double([0,0])
s = 35
if not data_file.exists():
    print('Preparing data {} for network...'.format(name[0]))
    data_file = os.path.join(DirData, name[0]+'_processed.nii.gz')
    if n == '100' and datatype == 'test':
        NormVals = matlab.double([0,1.32])
    matlabLib.HomoFilt_Normalize(data_file,DirSaveData,name[0],s,NormVals,nargout=0)
#%%
## Run data through the trained network
# first create a new config file based on the current data
f = open("demo_config_empty_neuro.ini")
mylist = f.readlines()
f.close()

indPath = []
indName = []
indNoName = []
indSave = []
indModel = []
indWindow = []
indIter = []
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
    if mylist[ind].find('spatial_window_size')>-1:
        indWindow.append(ind) 
    if mylist[ind].find('inference_iter')>-1:
        indIter.append(ind)
        
# write path of data
mystr = list(mylist[indPath[0]])
mystr = "".join(mystr[:-1]+ list(DirSaveData) + list('\n'))
mylist[indPath[0]] = mystr

# write name of data
mystr = list(mylist[indName[0]])
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

#write inference iteration to use
mystr = list(mylist[indIter[0]])
if networkType =='All_Allen':
    mystr = "".join(mystr[:-1]+ list('39999') + list('\n'))
else:
     mystr = "".join(mystr[:-1]+ list('-1') + list('\n'))   
mylist[indIter[0]] = mystr

#write the spatial size of data under Inference section (should be the last entry)
mystr = list(mylist[indWindow[-1]])
mystr = "".join(mystr[:-1]+ list(SW) + list('\n'))
mylist[indWindow[-1]] = mystr

# Write to a new config file
f = open('config_inf_neuro.ini','w')
f.write(''.join(mylist))
f.close()


sys.argv=['','inference','-a','net_segment','--conf',os.path.join('config_inf_neuro.ini'),'--batch_size','1']
niftynet.main()

#%%
# Postprocess to get individual neurons
saveTag = True
SZ = matlab.double(list(sp_window[n][:2]))
for ind in range(len(name)): 
    print('Postprocessing data {} ...'.format(name[ind]))
    Neurons = matlabLib.postProcess(DirSave,name[ind],SZ,AvgArea,minArea,thresh,nargout=2)
    if saveTag:
        print('Saving results for {} ...'.format(name[ind]))
        sio.savemat(os.path.join(DirSaveMask,name[ind]+'_neurons.mat'),{'finalSegments': np.array(Neurons[0],dtype=int)})
    ## Compare performance to GT Masks if available
    if DirMask is not None:
        print('Getting performance metrics for {} ...'.format(name[ind]))
        scores = matlabLib.GetPerformance_Jaccard(DirMask,name[ind],Neurons[0],Thresh,nargout=3)
        print('data: {} -> recall: {}, precision: {}, and F1 {}:'.format(name[ind],int(10000*scores[0])/100,int(10000*scores[1])/100,int(10000*scores[2])/100))

matlabLib.terminate()



