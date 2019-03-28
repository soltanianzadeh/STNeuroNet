# -*- coding: utf-8 -*-
"""
Demo showing how to get best postprocessing thresholds for all networks that 
were trained through leave-one-out cross-validation

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
import niftynet
import math
import numpy as np
import scipy.io as sio

import STNeuroNetPkg
import matlab 
matlabLib = STNeuroNetPkg.initialize()

# List of data IDs for Layer275 (DO NOT change the current ordering)
# Order is important for correct mapping between test data and the cross-validation-based trained networks
L = ['524691284', '531006860','502608215', '503109347','501484643', '501574836',
     '501729039', '539670003','510214538', '527048992']

## Set parameters
pixSize = 0.78         #um
meanR = 5.85           # neuron radius in um
AvgArea = round(math.pi*(meanR/pixSize)**2)
JThresh = 0.5
SZ = matlab.double([487,487])

# Hyperparameters
thresh = matlab.double([0.5])
minArea =  matlab.double([50])    #in pixels


saveTag = True
minA = np.zeros(len(L)+1)
ProbThresh = np.zeros(len(L)+1)

## Set directories
dirpath = os.getcwd()
DirData = os.path.join(dirpath,'Dataset','ABO')
DirSaveData = os.path.join(dirpath,'Results','ABO','data')
DirSave = os.path.join(dirpath,'Results','ABO','Probability map')
DirSaveMask = os.path.join(dirpath,'Results','ABO','Train Masks')
DirThresh = os.path.join(dirpath,'Results','ABO','Thresholds')


#%%

for loo in [0]: # range(len(L)):
    name = ['524691284', '531006860']
    if loo<len(L):
        name.remove(name[loo])
        LayerType = 'Layer275'
    else:
        LayerType = 'Layer175'
        
    if LayerType == 'Layer275':
        dataType = 'Cross Validation'
        endFile = str(loo+1)
    else:
        dataType = 'All'
        endFile = ''
        
    DirModel = os.path.join(dirpath,'models','ABO','Trained Network Weights',dataType,endFile)
    DirMask = os.path.join(dirpath,'Markings','ABO','Layer275','Grader1')

    
        
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
    DirSave_N = os.path.join(DirSave,str(loo+1))
    os.mkdir(DirSave_N)
    mystr = "".join(mystr[:-1]+ list(DirSave_N) + list('\n'))
    mylist[indSave[0]] = mystr
    #write where model is located
    mystr = list(mylist[indModel[0]])
    mystr = "".join(mystr[:-1]+ list(DirModel) + list('\n'))
    mylist[indModel[0]] = mystr
    # Write to a new config file
    f = open('config_inf.ini','w')
    f.write(''.join(mylist))
    f.close()
    
    sys.argv=['','inference','-a','net_segment','--conf',os.path.join('config_inf.ini'),'--batch_size','1']
    niftynet.main()

#
## Postprocess to get individual neurons
    F1All = np.zeros([len(name),thresh.size[-1],minArea.size[-1]])
    if DirMask is not None:
        for ind in range(len(name)):
            recall,precision,F1 = matlabLib.multiple_postProcessJaccard(SZ,DirSave_N,DirMask,name[ind],AvgArea,minArea,thresh,JThresh,nargout=3)
            F1All[ind,:,:] = np.array(F1)
    
        # Compute average F1 across data to get best hyperparameters            
        F1mean = np.mean(F1All,axis=0)  
        ind = np.argmax(F1mean.flatten())
        ind = np.unravel_index(ind,(thresh.size[-1],minArea.size[-1]))
        indA = ind[1]
        indT = ind[0]
        
        # save best thresholds
        minA[loo] = minArea[0][indA]
        ProbThresh[loo] = thresh[0][indT]
        
        print('Best thresh: %f , minArea: %f:'%(np.array(thresh)[:,indT],np.array(minArea)[:,indA]))
    

sio.savemat(os.path.join(DirThresh,'OptParam_Final.mat'),{'minA': minA, 'ProbThresh':ProbThresh})

matlabLib.terminate()



