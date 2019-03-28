%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  normalizeValues.m
%
%  Normalizes the input values to range between the minValue and maxValue
%  provided. Returns the values in type 'double'
%
%--------------------------------------------------------------------------
%
%  function values = normalizeValues(values, minValue, maxValue)
%
%  INPUT PARAMETERS:
%
%       values - A vector or matrix of values to be normalized
%
%       minValue - (Optional) The minimum normalized value [default = 0]
%
%       maxValue - (Optional) The maximum normalized value [default = 1]
%
%  OUTPUT VARIABLES:
%
%       values - The same vector or matrix, but with each of the values
%                normalized
%
%--------------------------------------------------------------------------
%
%  Author:          Stephanie Chiu
%  Institution:     Duke University
%  Date Created:    2010.01.26
%
%  Date Modified:   2011.08.23 - Reorganize code
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function values = normalizeValues(values, minValue, maxValue)

    %----------------------------------------------------------------------
    %  Initialize missing parameters
    %----------------------------------------------------------------------

    if nargin < 2
        minValue = 0;
    end
    
    if nargin < 3
        maxValue = 1;
    end

    %----------------------------------------------------------------------
    %  Validate input parameters
    %----------------------------------------------------------------------
    
    if minValue > maxValue
        error('''minValue'' must be <= ''maxValue''');
    end

    %----------------------------------------------------------------------
    %  Normalize the values
    %----------------------------------------------------------------------
    
    %
    %  Convert values to double for more accurate results
    %
    values = double(values);
    
    %
    %  If the new minima and maxima are the same value, then set the whole
    %  matrix to that value
    %
    if minValue == maxValue
        values(:) = minValue;
        return;
    end
    
    %
    %  Find old minima and maxima
    %
    oldMinValue = min(values(:));
    oldMaxValue = max(values(:));
    
    %
    %  If the new minima and maxima are same as the old ones, then just
    %  return the existing matrix
    %    
    if (oldMinValue == minValue && oldMaxValue == maxValue)
        return;
    end
    
    %
    %  If all old values are the same, just return the new minimum value
    %
    if (oldMinValue == oldMaxValue)
        values(:) = minValue;
        return;
    end
    
    %
    %  Perform normalization
    values = ((values - oldMinValue) ./ (oldMaxValue - oldMinValue) .* (maxValue - minValue)) + minValue;
end