classdef PTKDicomUtilities
    % PTKDicomUtilities. Utility functions related to Dicom files
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)

        function is_dicom = IsDicom(file_path, file_name)
            % Returns true if this is a Dicom file
    
            if strcmp(file_name, 'DICOMDIR')
                is_dicom = false;
                return
            end
            
            full_file_name = [file_path, filesep, file_name];
            
            is_dicom = PTKDicomFallbackLibrary.getLibrary.isdicom(full_file_name);
        end
        
        function dicom_series_uid = DMGetDicomSeriesUid(fileName, dictionary)
            % Gets the series UID for a Dicom file
            
            if isempty(dictionary)
                dictionary = DMDicomDictionary.GroupingDictionary;
            end
            
            header = PTKDicomFallbackLibrary.getLibrary.dicominfo(fileName, dictionary);
            
            if isempty(header)
                dicom_series_uid = [];
            else
                % If no SeriesInstanceUID tag then this is not a valid Dicom image (it
                % might be a DICOMDIR)
                if isfield(header, 'SeriesInstanceUID')
                    dicom_series_uid = header.SeriesInstanceUID;
                else
                    dicom_series_uid = [];
                end
            end
        end
        
        function metadata = ReadMetadata(fileName, dictionary, reporting)
            % Reads in Dicom metadata from the specified file
            try
                metadata = PTKDicomFallbackLibrary.getLibrary.dicominfo(fileName, dictionary);
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        function metadata = ReadGroupingMetadata(fileName, reporting)
            % Reads in Dicom metadata from the specified file
            try
                metadata = PTKDicomFallbackLibrary.getLibrary.dicominfo(fileName, DMDicomDictionary.GroupingDictionary);
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        function metadata = ReadEssentialMetadata(fileName, reporting)
            % Reads in Dicom metadata from the specified file
            try
                metadata = PTKDicomFallbackLibrary.getLibrary.dicominfo(fileName);
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        function image_data = ReadDicomImageFromMetadata(metadata, reporting)
            % Reads in Dicom image data from the specified metadata

            try
                image_data = PTKDicomFallbackLibrary.getLibrary.dicomread(metadata);
            catch exception
                reporting.Error('PTKDicomUtilities:DicomReadError', ['Error while reading the Dicom file. Error:' exception.message]);
            end
        end
        
        function ReadDicomImageIntoWrapperFromMetadata(metadata, image_wrapper, slice_index, reporting)
            % Reads in Dicom image data from the specified metadata. The image data
            % is stored directly into the RawImage matrix of a PTKWrapper object
            try
                image_wrapper.RawImage(:, :, slice_index, :) = PTKDicomFallbackLibrary.getLibrary.dicomread(metadata);
                
            catch exception
                reporting.Error('PTKDicomUtilities:DicomReadError', ['Error while reading the Dicom file. Error:' exception.message]);
            end
        end
        
        function match = AreImageLocationsConsistent(first_metadata, second_metadata, third_metadata)
            % Returns true if three images lie approximately on a straight line (determined
            % by the coordinates in the ImagePositionPatient Dicom tags)
            
            % If the ImagePositionPatient tag is not present, assume it is
            % consistent
            if (~isfield(first_metadata, 'ImagePositionPatient')) && (~isfield(second_metadata, 'ImagePositionPatient'))  && (~isfield(third_metadata, 'ImagePositionPatient'))
                match = true;
                return;
            end
            
            % First get the image position
            first_position = first_metadata.ImagePositionPatient;
            second_position = second_metadata.ImagePositionPatient;
            third_position = third_metadata.ImagePositionPatient;
            
            % Next, compute direction vectors between the points
            direction_vector_1 = second_position - first_position;
            direction_vector_2 = third_position - first_position;
            
            % Find a scaling between the direction vectors
            [max_1, scale_index_1] = max(abs(direction_vector_1));
            [max_2, scale_index_2] = max(abs(direction_vector_2));
            
            if max_1 > max_2
                scale_1 = 1;
                scale_2 = direction_vector_1(scale_index_2)/direction_vector_2(scale_index_2);
            else
                scale_1 = direction_vector_2(scale_index_1)/direction_vector_1(scale_index_1);
                scale_2 = 1;
            end
            
            % Scale
            scaled_direction_vector_1 = direction_vector_1*scale_1;
            scaled_direction_vector_2 = direction_vector_2*scale_2;
            
            % Find the maximum absolute difference between the normalised vectors
            difference = abs(scaled_direction_vector_2 - scaled_direction_vector_1);
            max_difference = max(difference);
            
            tolerance_mm = 10;
            match = max_difference <= tolerance_mm;
        end
        
        function [name, short_name] = PatientNameToString(patient_name)
            if ischar(patient_name)
                name = patient_name;
            else
                name = '';
                short_name = '';
                if isstruct(patient_name)
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'FamilyName', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'GivenName', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'MiddleName', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'NamePrefix', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'NameSuffix', false);
                    
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'FamilyName', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'GivenName', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'MiddleName', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'NamePrefix', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'NameSuffix', true);
                end
            end
        end
        
        function new_text = AddOptionalField(text, struct_name, field_name, only_if_nonempty)
            if isempty(text) || ~only_if_nonempty
                new_text = text;
                if isfield(struct_name, field_name) && ~isempty(struct_name.(field_name))
                    if isempty(text)
                        prefix = '';
                    else
                        prefix = ', ';
                    end
                    new_text = [text, prefix, struct_name.(field_name)];
                end
            else
                new_text = text;
            end
        end
        
        function uid = GetIdentifierFromFilename(file_name)
            [~, uid, ~] = fileparts(file_name);
        end
        
        function dicom_filenames = RemoveNonDicomFiles(image_path, filenames)
            dicom_filenames = [];
            for index = 1 : length(filenames)
                if (PTKDicomUtilities.IsDicom(image_path, filenames{index}))
                    dicom_filenames{end + 1} = filenames{index};
                end
            end
        end
        
        function image_info = GetListOfDicomFiles(image_path)
            filenames = PTKTextUtilities.SortFilenames(CoreDiskUtilities.GetDirectoryFileList(image_path, '*'));
            filenames = PTKDicomUtilities.RemoveNonDicomFiles(image_path, filenames);
            image_type = PTKImageFileFormat.Dicom;            
            image_info = PTKImageInfo(image_path, filenames, image_type, [], [], []);
        end        
    end
end

