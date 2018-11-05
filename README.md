# STNeuroNet

STNeuroNet is 3-dimensional convolutional neural network (CNN) for segmenting "active" neurons from calcium imaging data. The network was implemented through NiftyNet, a TensorFlow-based open-source CNN platform.
You can adapt the existing network to your imaging data.


### Features

* Pre- and post-processing steps for segmenting active neurons
* A 3D CNN for batch-processing of calcium imaging data
* MATLAB GUI for manual marking of calcium imaging data

### System Requirements
* python 3.6
* MATLAB 2017b and MATLAB Runtime version 9.3
  * Neural Network Toolbox, Image Processing Toolbox, and the [GUI Layout Toolbox][gui-toolbox]
* Tensorflow
* CUDA and cuDNN
* NiftyNet

[gui-toolbox]: https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox

### Installation

1. Please install the appropriate TensorFlow package:
   * [`pip install tensorflow-gpu==1.4`][tf-pypi-gpu] for TensorFlow with GPU support
   * [`pip install tensorflow==1.4`][tf-pypi] for CPU-only TensorFlow
   
   For further details, please refer to [Tensorflow website][tf-install]
2. [`pip install stneuronet`](https://pypi.org/project/STNeuroNet/)
3. MATLAB engine API:
   ```
   # For Windows OS
   cd <matlabroot>\extern\engines\python
   python setup.py install
   
   # For macOS or Linux OS
   cd <matlabroot>/extern/engines/python
   python setup.py install   
   ```
4. If the MATLAB Runtime is not installed, you can run the MATLAB Runtime installer.
	  To find its location, enter
   ```
    >>mcrinstaller
   ```
   
   at the MATLAB prompt. Alternatively, download and install the Windows version of the MATLAB Runtime for R2017b 
   from the following link on the [MathWorks website][matlab-runtime]

5. pip install stneuronet_dependencies (alternative: cd <coderoot>, python setup.py install)

 <sup>Note for Tensorflow 1.4 you need CUDA Toolkit 8.0 and cuDNN v7.0
 
 <sup>All other STNeuroNet dependencies are installed automatically as part of the pip installation process.

[tf-install]: https://www.tensorflow.org/install/pip
[tf-pypi-gpu]: https://pypi.org/project/tensorflow-gpu/
[tf-pypi]: https://pypi.org/project/tensorflow/
[matlab-runtime]: http://www.mathworks.com/products/compiler/mcr/index.html

### Documentation
The how-to guides are available on [the Wiki][wiki-link].

[wiki-link]: https://github.com/soltanianzadeh/STNeuroNet/wiki

### Useful links
[Allen Brain Observatory dataset][Allen-github]

[Neurofinder Challenge website][nf-website]

[NiftyNet source code on GitHub][niftynet-github]

[Allen-github]: https://github.com/AllenInstitute/AllenSDK/wiki/Use-the-Allen-Brain-Observatory-%E2%80%93-Visual-Coding-on-AWS
[niftynet-github]: https://github.com/NifTK/NiftyNet
[nf-website]: http://neurofinder.codeneuro.org/

### Citing 

If yo use any part of this software in your work, please cite Soltanian-Zadeh et al. 2018:

* S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast and robust active neuron
segmentation in two-photon calcium imaging using spatio-temporal deep-learning," 2018.


If you use NiftyNet in your work, please cite [Gibson and Li, et al. 2018][cmpb2018]:

* E. Gibson\*, W. Li\*, C. Sudre, L. Fidon, D. I. Shakir, G. Wang, Z. Eaton-Rosen, R. Gray, T. Doel, Y. Hu, T. Whyntie, P. Nachev, M. Modat, D. C. Barratt, S. Ourselin, M. J. Cardoso\^ and T. Vercauteren\^ (2018)
[NiftyNet: a deep-learning platform for medical imaging][cmpb2018], _Computer Methods and Programs in Biomedicine_.
DOI: [10.1016/j.cmpb.2018.01.025][cmpb2018]

* Li W., Wang G., Fidon L., Ourselin S., Cardoso M.J., Vercauteren T. (2017)
[On the Compactness, Efficiency, and Representation of 3D Convolutional Networks: Brain Parcellation as a Pretext Task.][ipmi2017]
In: Niethammer M. et al. (eds) Information Processing in Medical Imaging. IPMI 2017.
Lecture Notes in Computer Science, vol 10265. Springer, Cham.
DOI: [10.1007/978-3-319-59050-9_28][ipmi2017]


[ipmi2017]: https://doi.org/10.1007/978-3-319-59050-9_28
[cmpb2018]: https://doi.org/10.1016/j.cmpb.2018.01.025


### Licensing and Copyright

STNeuroNet is released under [the GNU License, Version 2.0](https://github.com/soltanianzadeh/STNeuroNet/LICENSE).

### Acknowledgements
We thank David Feng and Jerome Lecoq from the Allen Institute for providing the ABO data, Saskia de Vries and David Feng from the Allen Institute for useful discussions, and Hao Zhao for the initial implementation of the GUI. 

