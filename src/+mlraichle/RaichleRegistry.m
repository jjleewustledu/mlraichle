classdef RaichleRegistry < mlpatterns.Singleton
	%% ARBELAEZREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties
        subjectsFolder = 'jjlee2'
    end
    
    properties (Dependent)
        subjectsDir
        testSessionPath
        YeoDir
    end
    
    methods %% GET
        function x = get.subjectsDir(this)
            x = fullfile(getenv('PPG'), this.subjectsFolder, '');
        end
        function x = get.testSessionPath(~)
            x = fullfile(getenv('MLUNIT_TEST_PATH'), 'HYGLY28', '');
        end
        function x = get.YeoDir(~)
            x = fullfile(getenv('PPG', 'jjlee2', ''));
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
    
    methods
    end
    
    %% PRIVATE
    
    properties (Constant, Access = 'private')
    end
    
	methods (Access = 'private')		  
 		function this = RaichleRegistry(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

