classdef RaichleRegistry < handle
	%% RAICHLEREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    
    properties (Dependent)
        rawdataDir
        subjectsDir
        subjectsFolder
        testSessionPath
        YeoDir
    end
    
    methods %% GET
        function x = get.rawdataDir(this)
            x = this.subjectsDir;
        end
        function x = get.subjectsDir(this)
            x = this.subjectsDir_;
        end
        function x = get.subjectsFolder(this)
            [~,x] = fileparts(this.subjectsDir_);
        end
        function x = get.testSessionPath(~)
            x = fullfile(getenv('MLUNIT_TEST_PATH'), 'HYGLY28', '');
        end
        function x = get.YeoDir(this)
            x = this.subjectsDir;
        end
        
        function set.subjectsDir(this, x)
            assert(ischar(x));
            this.subjectsDir_ = x;
        end
        function set.subjectsFolder(this, x)
            assert(ischar(x));
            this.subjectsDir_ = fullfile(fileparts(this.subjectsDir_), x, '');
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
        subjectsDir_
    end
    
	methods (Access = 'private')		  
 		function this = RaichleRegistry(varargin)
            this.subjectsDir_ = getenv('SUBJECTS_DIR');
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

