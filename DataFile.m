classdef DataFile < handle
    %DATAFILE Helper class for data logging, intended to create CSVs
    %   TODO Detailed explanation goes here
    
    properties
        data
        fileHandle
    end
    
    properties(Constant)
        DEFAULT_SUBFOLDER = 'data\';
        DEFAULT_FILENAME = 'data.csv';
    end
    
    methods(Static)
        function path = defaultPath(trialName)
            % Current time in standard format: 'yyyymmddTHHMMSS' (ISO 8601)
            curdate = datestr(now, 30); 
            
            if nargin < 1 || isempty(trialName)
                subfolder = curdate;
            else
                subfolder = [curdate ' ' trialName];
            end
            path = [DataFile.DEFAULT_SUBFOLDER subfolder filesep ...
                DataFile.DEFAULT_FILENAME];
        end
    end
    
    methods
        function df = DataFile(path, columns)
            % Check inputs
            if isempty(path)
                path = defaultPath();
            end
            
            if exist(path, 'file')
                warning('File %s already exists! Will append to end.', path);
            end
            
            % if isempty(columns) ... throw exception?
            
            % Intialize properties
            df.data = [];
            
            [folderName, ~, ~] = fileparts(path);
            if ~isempty(folderName)
                mkdir(folderName);
            end
            df.fileHandle = fopen(path, 'a');
            if length(columns) > 1
                fprintf(df.fileHandle, '%s,', columns{1:end-1});
            end
            fprintf(df.fileHandle, '%s\n', columns{end});
        end
        
        function append(df, newData)
            df.data = [df.data; newData];
            if length(newData) > 1
                fprintf(df.fileHandle, '%i,', newData(1:end-1));
            end
            fprintf(df.fileHandle, '%i\n', newData(end));
        end
        
        function delete(df) % for deleting this handle, not the file!
            if df.isvalid && strcmpi(get(df.fileHandle, 'status'), 'open')
                fclose(df.fileHandle);
            end
        end
    end
    
end

