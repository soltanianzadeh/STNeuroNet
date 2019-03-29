# -*- coding: utf-8 -*-
"""
windows aggregator decode sampling grid coordinates and image id from
batch data, forms image level output and write to hard drive


Modified by Somayyeh Soltanian-Zadeh for the use with STNeuroNet

S. Soltanian-Zadeh et al., "Fast and robust active neuron segmentation in two-photon
calcium imaging using spatio-temporal deep-learning"
"""
from __future__ import absolute_import, print_function, division

import os

import numpy as np
import math
import niftynet.io.misc_io as misc_io
from niftynet.engine.windows_aggregator_base import ImageWindowsAggregator
from niftynet.layer.discrete_label_normalisation import \
    DiscreteLabelNormalisationLayer
from niftynet.layer.pad import PadLayer


class GridSamplesAggregator(ImageWindowsAggregator):
    """
    This class keeps record of the currently cached image,
    initialised as all zeros, and the values are replaced
    by image window data decoded from batch
    """
    def __init__(self,
                 image_reader,
                 name='image',
                 output_path=os.path.join('.', 'output'),
                 window_border=(),
                 interp_order=0):
        ImageWindowsAggregator.__init__(self, image_reader=image_reader)
        self.name = name
        self.image_out = None
        self.output_path = os.path.abspath(output_path)
        self.window_border = window_border
        self.output_interp_order = interp_order

    def decode_batch(self, window, location):
        n_samples = location.shape[0]
        window, location = self.crop_batch(window, location, self.window_border) 
        
        for batch_id in range(n_samples):
            image_id, x_start, y_start, z_start, x_end, y_end, z_end = \
                location[batch_id, :]
            
            if image_id != self.image_id:
                # image name changed:
                #    save current image and create an empty image
                self._save_current_image()
                if self._is_stopping_signal(location[batch_id]):
                    return False
                # Changed on 3/12/2018
                self.image_out, self.n_frames = self._initialise_empty_image(
                    image_id=image_id,
                    n_channels=window.shape[-1],
                    n_minibatch = (z_end-z_start),
                    dtype=window.dtype)
            # Changed on 3/12/2018 to output 2d image per temporal minibatch.
			# Only suitable for STNeuroNet (S.Soltanian-Zadeh et al.)
            if z_end == self.n_frames:
                z_start_prev = math.floor(z_end/(z_end-z_start))
            else:
                z_start_prev = int(z_end/(z_end-z_start) -1)
            self.image_out[x_start:x_end,
                           y_start:y_end,
                           z_start_prev:z_start_prev+1, ...] = window[batch_id, ...]
            
        return True

    def _initialise_empty_image(self, image_id, n_channels, n_minibatch, dtype=np.float):
        self.image_id = image_id
        # Changed on 3/12/2018
        spatial_shape = self.input_image[self.name].shape[:2]
        n_frames = math.ceil(self.input_image[self.name].shape[2]/n_minibatch)
        output_image_shape = spatial_shape + (n_frames,)+ (n_channels,)
        print('output image shape is {}'.format(output_image_shape))
        empty_image = np.zeros(output_image_shape, dtype=dtype)

        for layer in self.reader.preprocessors:
            if isinstance(layer, PadLayer):
                empty_image, _ = layer(empty_image)
        return empty_image, self.input_image[self.name].shape[2]

    def _save_current_image(self):
        if self.input_image is None:
            return

        for layer in reversed(self.reader.preprocessors):
            if isinstance(layer, PadLayer):
                self.image_out, _ = layer.inverse_op(self.image_out)
            if isinstance(layer, DiscreteLabelNormalisationLayer):
                self.image_out, _ = layer.inverse_op(self.image_out)
        subject_name = self.reader.get_subject_id(self.image_id)
        filename = "{}_niftynet_out.nii.gz".format(subject_name)
        source_image_obj = self.input_image[self.name]
        misc_io.save_data_array(self.output_path,
                                filename,
                                self.image_out,
                                source_image_obj,
                                self.output_interp_order)
        return
