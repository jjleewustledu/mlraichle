classdef (Sealed) StudyRegistry < handle & mlnipet.StudyRegistry
	%% STUDYREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties
        ignoredExperiments = {'52823' '53317' '53343'}
    end
    
    properties (Dependent)
        rawdataDir
        subjectsJson
    end
    
    methods (Static)
        function this = instance(varargin)
            %% INSTANCE
            %  @param optional qualifier is char \in {'initialize' ''}
            
            ip = inputParser;
            addOptional(ip, 'qualifier', '', @ischar)
            parse(ip, varargin{:})
            
            persistent uniqueInstance
            if (strcmp(ip.Results.qualifier, 'initialize'))
                uniqueInstance = [];
            end          
            if (isempty(uniqueInstance))
                this = mlraichle.StudyRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end  
    
    methods
        
        %% GET
        
        function x = get.rawdataDir(~)
            x = fullfile(getenv('PPG'), 'rawdata', '');
        end
        function g = get.subjectsJson(~)
            g = jsondecode( ...
                fileread(fullfile(getenv('SUBJECTS_DIR'), 'constructed_20190725.json')));
        end
    end
    
    %% PRIVATE
    
	methods (Access = private)		  
 		function this = StudyRegistry(varargin)
            this = this@mlnipet.StudyRegistry(varargin{:});
            setenv('CCIR_RAD_MEASUREMENTS_DIR',  ...
                   fullfile(getenv('HOME'), 'Documents', 'private', ''));
            this.referenceTracer = 'FDG';
            this.umapType = 'ct';
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

