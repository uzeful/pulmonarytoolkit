classdef PTKImageSliceParameters < CoreBaseClass
    % PTKImageSliceParameters. Parameters for extracting a 2D slice from a
    % 3D volume
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    events
        OrientationChanged
        SliceNumberChanged
    end
    
    properties (SetObservable)
        Orientation = PTKImageOrientation.Coronal
        SliceNumber = [1, 1, 1] % The currently shown slice in 3 dimensions
    end
end