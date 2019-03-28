#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Script to run trained networks on all Layer275 data

@author: Somayyeh Soltanian-Zadeh
%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast and robust  
% active neuron segmentation in two-photon calcium imaging using spatio-temporal
% deep learning," Proceedings of the National Academy of Sciences (PNAS), 2019.
%
% Released under a GPL v2 license."""
import os
import sys
import niftynet
import math
import numpy as np
from pathlib import Path
import scipy.io as sio
import matplotlib.pyplot as plt

import STNeuroNetPkg
import matlab
matlabLib = STNeuroNetPkg.initialize()

#%% Fields to be determined by user:
# Which network to use: 'ABO', or 'Neurofinder'
networkType = 'ABO'

#%%
# List of data IDs for Layer275 (DO NOT change the current ordering)
# Order is important for correct mapping between test data and the cross-validation-based trained networks
L = ['524691284', '531006860','502608215', '503109347','501484643', '501574836',
     '501729039', '539670003','510214538', '527048992']

## Set parameters
pixSize = 0.78         #um
meanR = 5.85           # neuron radius in um
AvgArea = round(math.pi*(meanR/pixSize)**2)
Thresh = 0.5           # IoU threshold for matching
SZ = matlab.double([487,487])        #x and y dimension of data

# Data to process
name = L


saveTag = True
recall = np.zeros(len(name))
precision = np.zeros(len(name))
F1 = np.zeros(len(name))

if networkType == 'ABO':
    dataType = 'Cross Validation'
    ThreshFile = 'OptParam_Final_JaccardNew_LOO_whitened.mat'
    AreaName = 'minArea'
elif networkType == 'Neurofinder':
    dataType = 'Grader1'
    endFile = ''
    ThreshFile = 'OptParam_JaccardNew_G1_All.mat'
    AreaName = 'minA'
    
## Set directories
dirpath = os.getcwd()
DirData = os.path.join(dirpath,'Dataset','ABO')
DirSaveData = os.path.join(dirpath,'Results','ABO','data')
DirSave = os.path.join(dirpath,'Results','ABO','Probability map')
DirMask = os.path.join(dirpath,'Markings','ABO','Layer275','FinalGT')
DirSaveMask = os.path.join(dirpath,'Results','ABO','Test Masks')
DirThresh = os.path.join(dirpath,'Results',networkType,'Thresholds')


optThresh = sio.loadmat(os.path.join(DirThresh,ThreshFile))

## Check if direcotries exist
if not os.path.exists(DirSaveMask):
    os.mkdir(DirSaveMask)
if not os.path.exists(DirSaveData):
    os.mkdir(DirSaveData)
    
#%%
for num in range(len(name)):  
        
    if networkType=='ABO':
        endFile = str(L.index(name[num])+1)
        ind = L.index(name[num])

    DirModel = os.path.join(dirpath,'models',networkType,'Trained Network Weights',dataType,endFile)

    ## read saved threshold values
    thresh = matlab.double([optThresh['ProbThresh'][0][ind]])
    if networkType == 'Neurofinder':
        minArea = matlab.single([optThresh[AreaName][0][0]*0.78**2])
    else:
        minArea = matlab.single([optThresh[AreaName][0][ind]])
    
    ## Check if HomoFiltered downsampled data is available
    data_file = Path(os.path.join(DirSaveData,name[num]+'_dsCropped_HomoNorm.nii.gz'))
    if not data_file.exists():
        print('Preparing data {} for network...'.format(name[num]))
        data_file = os.path.join(DirData, name[num]+'_processed.nii.gz')
        s = 30
        matlabLib.HomoFilt_Normalize(data_file,DirSaveData,name[ind],s,nargout=0)
        
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
    mystr = "".join(mystr[:-1]+ list('_dsCropped_HomoNorm') + list('\n'))
    mylist[indName[0]] = mystr
    
    # exclude any other data not listed in names
    AllFiles = os.listdir(DirSaveData)
    AllNames = []
    for ind in range(len(AllFiles)):
        if AllFiles[ind].find('_dsCropped_HomoNorm')>-1:
            AllNames.append(AllFiles[ind][:AllFiles[ind].find('_dsCropped_HomoNorm')])
            
    excludeNames = [c for c in AllNames if c not in name[num]]    
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
    
    sys.argv=['','inference','-a','net_segment','--conf',os.path.join('config_inf.ini'),'--batch_size','1']
    niftynet.main()

    #%%
    ## Postprocess to get individual neurons 
    print('Postprocessing data {} ...'.format(name[num]))
    Neurons = matlabLib.postProcess(DirSave,name[num],SZ,AvgArea,minArea,thresh,nargout=2)
    if saveTag:
        print('Saving results of {} ...'.format(name[num]))
        sio.savemat(os.path.join(DirSaveMask,name[num]+'_neurons.mat'),{'finalSegments': np.array(Neurons[0],dtype=int)})
    ## Compare performance to GT Masks if available
    if DirMask is not None:
        print('Getting performance metrics for {} ...'.format(name[num]))
        scores = matlabLib.GetPerformance_Jaccard(DirMask,name[num],Neurons[0],Thresh,nargout=3)
        recall[num] = int(10000*scores[0])/100
        precision[num] = int(10000*scores[1])/100
        F1[num] = int(10000*scores[2])/100
        print('data: {} -> recall: {}, precision: {}, and F1 {}:'.format(name[num],recall[num],precision[num],F1[num]))

sio.savemat(os.path.join(DirSaveMask,'Layer275_performance.mat'),{'recall': recall,'precision':precision, 'F1': F1})

matlabLib.terminate()
#%%
## Plot results
fig,ax = plt.subplots(1,1)
x = [1,2,3]
y = [sum(recall)/len(recall),sum(precision)/len(precision),sum(F1)/len(F1)]
ye = [np.array([0,0,0]),
      np.array([np.std(recall,ddof=1),np.std(precision,ddof=1),np.std(F1,ddof=1)])]
ax.bar(x,y,width=0.5,align='center',zorder = 0)
ax.errorbar(x,y,yerr = ye,ecolor='black',
       elinewidth=2, fmt = 'None',zorder = 2)

ax.autoscale(False)
ax.scatter(np.ones(len(recall)),recall, s = 80,c = 'gray',zorder=1)
ax.scatter(2*np.ones(len(precision)),precision, s = 80,c = 'gray',zorder=1)
ax.scatter(3*np.ones(len(F1)),F1, s = 80,c = 'gray',zorder=1)
plt.xticks(x,["Recall","Precision","F1"])
plt.show()



