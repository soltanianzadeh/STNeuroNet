# -*- coding: utf-8 -*-
"""
Demo showing how to train stneuronet from selected data from Allen Brain Observatory dataset

@author: Somayyeh Soltanian-Zadeh
%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license.
"""
import os
import sys
import numpy as np
import math
from pathlib import Path
import scipy.io as sio

import niftynet

import STNeuroNetPkg
import matlab 
matlabLib = STNeuroNetPkg.initialize()

## Set directories
dirpath = os.getcwd()
DataDir = os.path.join(dirpath,'Dataset','ABO')
DirSaveData = os.path.join(dirpath,'Results','ABO','data')
DirSaveTempMask = os.path.join(dirpath,'Results','ABO','data','TempMask')
DirSave = os.path.join(dirpath,'Results','ABO','Probability map')
DirModel = os.path.join(dirpath,'models','ABO','Network','1')
DirMask = os.path.join(dirpath,'Markings','ABO','Layer275','Grader1')

## Set parameters
fs = matlab.double([6])              #recording speed after temporal downsampling, Hz
SZ = matlab.double([487,487])
fNeuron = matlab.double([2.9])           # firing rate of neurons, Hz
Pd = matlab.double([1-0.035])         #Probability of detection
tau = 0.2               # decay rate of calcium sensor, seconds
pixSize = 0.78         #um
meanR = 5.85           # neuron radius in um
AvgArea = round(math.pi*(meanR/pixSize)**2)
maxDist = 5/pixSize    # 5 um -> pixels
ds = 5
border = 13
s = 30
Wt = matlab.double([200])     #length of temporal window for subsampling training data
Ws = matlab.double([144])     # length of spatial window
flag = 0                      # If tag is one, then overlapping patches from the video will be saved
                              # in a directory to be used during training (along with their rotations).
                              # Make sure to have enough memory to save the data. If flag is zero, small
                              # patches will be randomly cropped during training on the fly. However
                              # if the data is very large, this will be very slow.

# Hyperparameters
thresh = matlab.double(np.concatenate((np.arange(.50,.95,.05),np.arange(.96,1,.02))).tolist())
minArea =  matlab.double(np.concatenate(([15,20],np.arange(25,100,15))).tolist())    #in pixels

## Preprocess Train data specified by name. Note that any data name
## in the data directory that is not included in "name" will be ignored in training
name = ['501484643']

NormVals = matlab.double([0,0])
#%
for ind in range(len(name)):
    data_file = Path(DataDir+'//'+ name[ind]+'_processed.nii.gz')
    if not data_file.exists():
        raise ValueError('Downsampled, cropped data file in .nii.gz format not found.')
    my_file = Path(DirSaveData+'//'+ name[ind]+'_dsCropped_HomoNorm.nii.gz')
    if not my_file.exists():
        data_file = os.path.join(DataDir, name[ind]+'_processed.nii.gz')
        matlabLib.HomoFilt_Normalize(data_file,DirSaveData,name[ind],s,nargout=0)
    my_file = Path(DirSaveTempMask+'//TemporalMask_'+ name[ind]+'.nii.gz')
    if not my_file.exists():
        if not os.path.isdir(DirSaveTempMask):
            os.mkdir(DirSaveTempMask)
        matlabLib.prepareTemporalMask(DataDir,DirMask,DirSaveTempMask,name[ind],tau,fs,fNeuron,Pd,nargout=0)
    if flag:
        TrainDirData = os.path.join(dirpath,'Results','ABO','subImages')
        TrainDirMask = TrainDirData
        if not os.path.isdir(TrainDirData):
            os.mkdir(TrainDirData)
        matlabLib.SaveSubVolumes(DirSaveData,DirSaveTempMask,TrainDirData,name[ind],Ws,Wt,nargout=0)
        Nmask = 'TempMask_'     #train Mask names contains
        Nvid = 'HomoVid_'       #train video names contains
    else:
         TrainDirData = DirSaveData
         TrainDirMask = DirSaveTempMask
         Nmask = 'TemporalMask_'
         Nvid = '_dsCropped_HomoNorm'

#%%
## train the network
# first create a new config file based on the current data
f = open("demo_config_empty.ini")
mylist = f.readlines()
f.close()

mylistInf = mylist

indPath = []
indName = []
indNoName = []
indModel = []
indSave = []
for ind in range(len(mylist)):
    if mylist[ind].find('path_to_search')>-1:
        indPath.append(ind)
    if mylist[ind].find('filename_contains')>-1:
        indName.append(ind)
    if mylist[ind].find('filename_not_contains')>-1:
        indNoName.append(ind)          
    if mylist[ind].find('model_dir')>-1:
        indModel.append(ind) 
    if mylist[ind].find('save_seg_dir')>-1:
        indSave.append(ind)            
        
# write path of data
mystr = list(mylist[indPath[0]])
mystr = "".join(mystr[:-1]+ list(TrainDirData) + list('\n'))
mylist[indPath[0]] = mystr
# write name of data
mystr = list(mylist[indName[0]])
mystr = "".join(mystr[:-1]+ list(Nvid) + list('\n'))
mylist[indName[0]] = mystr

# write information for labels
mystr = list(mylist[indPath[1]])
mystr = "".join(mystr[:-1]+ list(TrainDirMask) + list('\n'))
mylist[indPath[1]] = mystr
# write name of data
mystr = list(mylist[indName[1]])
mystr = "".join(mystr[:-1]+ list(Nmask) + list('\n'))
mylist[indName[1]] = mystr

# exclude any other data not listed in names
AllFiles = os.listdir(TrainDirMask)
AllNames = []
for ind in range(len(AllFiles)):
    if AllFiles[ind].find(Nmask)>-1:
        ind1 =AllFiles[ind].find(Nmask)+len(Nmask)
        ind2 = ind1+9
        AllNames.append(AllFiles[ind][ind1:ind2])
        
excludeNames = [c for c in AllNames if c not in name]    
if len(excludeNames):   
    mystr = list(mylist[indNoName[0]])
    temp = mystr[:-1] + list(',')
    for ind in range(len(excludeNames)):
        temp = temp + list(excludeNames[ind]) + list(',')
    mystr = "".join(temp[:-1]+ list('\n'))
    mylist[indNoName[0]] = mystr
    mylist[indNoName[1]] = mystr

#write where model is located
mystr = list(mylist[indModel[0]])
mystr = "".join(mystr[:-1]+ list(DirModel) + list('\n'))
mylist[indModel[0]] = mystr


# Write to a new config file
f = open('config_train.ini','w')
f.write(''.join(mylist))
f.close()


sys.argv=['','train','-a','net_segment','--conf',os.path.join('config_train.ini'),'--batch_size','3']
niftynet.main()

#%%
# inference config file
f = open("demo_config_empty.ini")
mylistInf = f.readlines()
f.close()
# write path of data
mystr = list(mylistInf[indPath[0]])
mystr = "".join(mystr[:-1]+ list(DirSaveData) + list('\n'))
mylistInf[indPath[0]] = mystr
# write name of data
mystr = list(mylistInf[indName[0]])
mystr = "".join(mystr[:-1]+ list('_dsCropped_HomoNorm') + list('\n'))
mylistInf[indName[0]] = mystr

mylistInf[indNoName[0]] = mylist[indNoName[0]]
mylistInf[indModel[0]] = mylist[indModel[0]]
mylistInf[indNoName[1]] = mylist[indNoName[1]]

#write where model is located
mystr = list(mylist[indModel[0]])
mystr = "".join(mystr[:-1]+ list(DirModel) + list('\n'))
mylist[indModel[0]] = mystr

#write where to save result
mystr = list(mylistInf[indSave[0]])
mystr = "".join(mystr[:-1]+ list(DirSave) + list('\n'))
mylistInf[indSave[0]] = mystr

# Write to a new config file
f = open('config_inf.ini','w')
f.write(''.join(mylistInf))
f.close()

## Apply the trained network to train data for further processing
sys.argv=['','inference','-a','net_segment','--conf','config_inf.ini','--batch_size','1']
niftynet.main()

#%%
## Postprocess to get individual neurons
F1All = np.zeros([len(name),thresh.size[-1],minArea.size[-1]])
if DirMask is not None:
    for ind in range(len(name)):
        recall,precision,F1 = matlabLib.multiple_postProcess(SZ,DirSave,DirMask,name[ind],AvgArea,minArea,thresh,0.5,nargout=3)
        F1All[ind,:,:] = np.array(F1)

    # Compute average F1 across data to get best hyperparameters            
    F1mean = np.mean(F1All,axis=0)  
    ind = np.argmax(F1mean.flatten())
    indA = math.floor(ind/minArea.size[-1])
    indT = ind - minArea.size[-1]*indA 
    
    print('Best thresh: %f , minArea: %f:'%(np.array(thresh)[:,indT],np.array(minArea)[:,indA]))

#%%
matlabLib.terminate()


