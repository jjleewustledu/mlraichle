classdef (Sealed) StudyRegistry < handle & mlnipet.StudyRegistry
	%% STUDYREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties
        blurTag = ''
        Ddatetime0 % seconds
        dicomExtension = '.dcm'
        ignoredExperiments = {'52823' '53317' '53343' '178378' '186470'}
        normalizationFactor = 1
        referenceTracer = 'FDG'
        scatterFraction = 0
        T = 10 % sec at the start of artery_interpolated used for model but not described by scanner frames
        tracerList = {'oc' 'oo' 'ho' 'fdg'}
        umapType = 'ct'
        stableToInterpolation = true
    end
    
    properties (Dependent)
        projectsDir
        rawdataDir
        subjectsDir
        subjectsJson
        tBuffer
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
        
        function g = get.projectsDir(~)
            g = getenv('PROJECTS_DIR');
        end 
        function     set.projectsDir(~, s)
            assert(isfolder(s));
            setenv('PROJECTS_DIR', s);
        end  
        function x = get.rawdataDir(~)
            x = fullfile(getenv('PPG'), 'rawdata', '');
        end
        function g = get.subjectsDir(~)
            g = getenv('SUBJECTS_DIR');
        end        
        function     set.subjectsDir(~, s)
            assert(isfolder(s));
            setenv('SUBJECTS_DIR', s);
        end
        function g = get.subjectsJson(~)
            g = jsondecode( ...
                fileread(fullfile(getenv('SUBJECTS_DIR'), 'constructed_20190725.json')));
        end
        function g = get.tBuffer(this)
            g = max(0, -this.Ddatetime0) + this.T;
        end
    end
    
    %% PRIVATE
    
	methods (Access = private)		  
 		function this = StudyRegistry(varargin)
            this = this@mlnipet.StudyRegistry(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

