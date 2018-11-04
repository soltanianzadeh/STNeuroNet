# STNeuroNet

NiftyNet is a [TensorFlow][tf]-based open-source convolutional neural networks (CNN) platform for research in medical image analysis and image-guided therapy.
NiftyNet's modular structure is designed for sharing networks and pre-trained models.
Using this modular structure you can:

* Get started with established pre-trained networks using built-in tools
* Adapt existing networks to your imaging data
* Quickly build new solutions to your own image analysis problems


### Features

* 
*


### Installation

1. Please install the appropriate [TensorFlow][tf] package*:
   * [`pip install tensorflow-gpu==1.4`][tf-pypi-gpu] for TensorFlow with GPU support
   * [`pip install tensorflow==1.4`][tf-pypi] for CPU-only TensorFlow
2. [`pip install stneuronet`](https://pypi.org/project/STNeuroNet/)

 <sup>All other STNeuroNet dependencies are installed automatically as part of the pip installation process.

To install from the source repository, please checkout [the instructions](http://niftynet.readthedocs.io/en/dev/installation.html).</sup>

[tf-pypi-gpu]: https://pypi.org/project/tensorflow-gpu/
[tf-pypi]: https://pypi.org/project/tensorflow/


### Documentation
The API reference and how-to guides are available on [Read the Docs][rtd-niftynet].

[rtd-niftynet]: https://github.com/soltanianzadeh/STNeuroNet

### Useful links

[NiftyNet website][niftynet-io]

[NiftyNet source code on GitHub][niftynet-github]

[niftynet-io]: http://niftynet.io/
[niftynet-github]: https://github.com/NifTK/NiftyNet


### Citing STNeuroNet

If yo use STNeuroNet in your work, please cite Soltanian-Zadeh et al. 2018:

* S. SOltanian-Zadeh,et al., "Fast and robust active neuron
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

NiftyNet is released under [the Apache License, Version 2.0](https://github.com/NifTK/NiftyNet/blob/dev/LICENSE).

Copyright 2018 the NiftyNet Consortium.

### Acknowledgements
