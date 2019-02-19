%% Main script to view the markings of either the Allen Brain Observatory 
%  data or the Neurofinder data. Given the description for every field,
%  please set appropriate vlaues to each field for the data.
%
%  Note that the data should be in the correct format. Please refer the README
%  file for details.
%
% Author: Somayyeh Soltanian-Zadeh
% Date: 6-10-2018
%

addpath(genpath('Software'))

opt.dataset = 'Allen';          %Choose between 'Allen' and 'Neurofinder'

opt.ID = '501484643';           % If dataset is 'Allen', ID is a 9-digit number 
                                % as written in Table 1 of the manuscript (e.g., '501484643').
                                % If dataset is 'Neurofinder', ID is from the
                                % following: '100','101', '200', '201', 
                                % '400', and '401'.
                        
opt.type = 'Layer275';          % Type of data. For the 'Allen' data, this is either 
                                % 'Layer275' or 'Layer175', denoting from which 
                                % cortical layer the data was recorded from (Details 
                                % can be found in Table 1 of the manuscript).   
                                % For the 'Neurofinder' data, this is either 'test'
                                % or 'train'. 

opt.marking = 'Allen';        % Type of marking to show. For the 'Allen' data, this is either 
                                % 'Allen' or 'Grader1', denoting Allen's initial marking or 
                                % the final curated masks. For 'Neurofinder' this is
                                % 'neurofinder' or 'Grader1'. Not that if 'test' is selected   
                                % for the 'Neurofinder' data, there is no 'neurofinder' mask.

RunViewMarking(opt);



                        