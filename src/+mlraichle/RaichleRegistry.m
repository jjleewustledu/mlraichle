classdef RaichleRegistry < handle
	%% RAICHLEREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties 
        comments
    end
    
    properties (Dependent)
        dicomExtension
        projectsPath
        rawdataDir
        subjectsPath
        subjectsDir
        subjectsFolder
        testSessionPath
        YeoDir
    end
    
    methods 
        
        %% GET
        
        function g = get.dicomExtension(~)
            g = '.dcm';
        end
        function x = get.projectsPath(this)
            x = this.projectsPath_;
        end
        function     set.projectsPath(this, x)
            assert(ischar(x));
            this.projectsPath_ = x;
        end
        function x = get.rawdataDir(~)
            x = fullfile(getenv('PPG'), 'rawdata', '');
        end
        function x = get.subjectsPath(this)
            x = this.subjectsDir;
        end
        function     set.subjectsPath(this, x)
            this.subjectsDir = x;
        end
        function x = get.subjectsDir(this)
            x = this.subjectsDir_;
        end
        function     set.subjectsDir(this, x)
            assert(ischar(x));
            this.subjectsDir_ = x;
        end
        function x = get.subjectsFolder(this)
            x = mybasename(this.subjectsDir_);
        end
        function     set.subjectsFolder(this, x)
            assert(ischar(x));
            this.subjectsDir_ = fullfile(fileparts(this.subjectsDir_), x, '');
        end
        function x = get.testSessionPath(~)
            x = fullfile(getenv('MLUNIT_TEST_PATH'), 'HYGLY28', '');
        end
        function x = get.YeoDir(this)
            x = this.subjectsDir;
        end        
        
        %%
        
        function       diaryOff(~)
            diary off;
        end
        function       diaryOn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.subjectsDir, @isdir);
            parse(ip, varargin{:});
            
            diary(fullfile(ip.Results.path, sprintf('%s_diary_%s.log', mfilename, datestr(now, 30))));
        end
        function tf  = isChpcHostname(~)
            [~,hn] = mlbash('hostname');
            tf = lstrfind(hn, 'gpu') || lstrfind(hn, 'node') || lstrfind(hn, 'login');
        end
        function loc = loggingLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'type', 'path', @isLocationType);
            parse(ip, varargin{:});
            
            switch (ip.Results.type)
                case 'folder'
                    [~,loc] = fileparts(this.subjectsDir);
                case 'path'
                    loc = this.subjectsDir;
                otherwise
                    error('mlpipeline:unsupportedSwitchCase', ...
                          'StudyData.loggingLocation.ip.Results.type->%s', ip.Results.type);
            end
        end
        function loc = saveWorkspace(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.subjectsDir, @isdir);
            parse(ip, varargin{:});
            
            loc = fullfile(ip.Results.path, sprintf('%s_workspace_%s.mat', mfilename, datestr(now, 30)));
            if (this.isChpcHostname)
                save(loc, '-v7.3');
                return
            end
            save(loc);
        end
    end
    
    methods (Static)
        function this = instance(qualifier)
            %% INSTANCE uses string qualifiers to implement registry behavior that
            %  requires access to the persistent uniqueInstance
            persistent uniqueInstance
            
            if (exist('qualifier','var') && ischar(qualifier))
                if (strcmp(qualifier, 'initialize'))
                    uniqueInstance = [];
                end
            end
            
            if (isempty(uniqueInstance))
                this = mlraichle.RaichleRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end  
    
    %% PRIVATE
    
    properties (Access = 'private')
        projectsPath_
        subjectsDir_
    end
    
	methods (Access = 'private')		  
 		function this = RaichleRegistry(varargin)
            this.projectsPath_ = getenv('SINGULARITY_HOME');
            this.subjectsDir_ = getenv('PPG_SUBJECTS_DIR');
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

