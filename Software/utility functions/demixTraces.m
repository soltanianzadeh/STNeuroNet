%% Adapted from AllenSDK python function demixer.py
% # Allen Institute Software License - This software license is the 2-clause BSD
% # license plus a third clause that prohibits redistribution for commercial
% # purposes without further permission.
% #
% # Copyright 2017. Allen Institute. All rights reserved.
% 
% # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% # ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% # LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% # CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% # POSSIBILITY OF SUCH DAMAGE.
%
% Date: 4/30/2018
% modified by: Somayyeh Soltanian-Zadeh
%%

function [demix_traces, drop_frames] = demixTraces(traces,vid,masks)

[N, T] = size(traces);
[x, y,~] = size(masks);
P = x * y;

if ndims(vid)== 3
    vid = reshape(vid,P,T);
end


flat_masks = reshape(masks,P,[]);
num_pixels_in_mask = sum(flat_masks,1);
F = bsxfun(@times,traces, num_pixels_in_mask'); 

drop_frames = [];
demix_traces = zeros(N, T);

for t = 1:T
    weighted_mask_sum = F(:, t);
    drop_test = (weighted_mask_sum == 0);

    if sum(drop_test == 0)>0
        norm_mat = diag(num_pixels_in_mask./ weighted_mask_sum');
        stack_t = single(vid(:,t)); 
        
        flat_weighted_masks = norm_mat*(bsxfun(@times,flat_masks',stack_t'));

        overlap = flat_masks'*flat_weighted_masks'; %(N,N) 
        try
            demix_traces(:, t) = linsolve(overlap, F(:, t));
        catch
            disp('singular matrix, using least squares');
            demix_traces(:, t) = lsqlin(overlap, F(:, t));
        end
        drop_frames = [drop_frames,0];

    else
        drop_frames = [drop_frames,1];
    end
end

end


