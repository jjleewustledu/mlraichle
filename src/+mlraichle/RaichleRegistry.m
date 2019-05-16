classdef RaichleRegistry < mlnipet.Resources
	%% RAICHLEREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties 
        comments
        atlVoxelSize = 222
    end
    
    properties (Dependent)
        rawdataDir
    end
    
    methods 
        
        %% GET
        
        function x = get.rawdataDir(~)
            x = fullfile(getenv('PPG'), 'rawdata', '');
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
    
    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = RaichleRegistry(varargin)
            this = this@mlnipet.Resources(varargin{:});
            setenv('CCIR_RAD_MEASUREMENTS_DIR',  ...
                   fullfile(getenv('HOME'), 'Documents', 'private', ''));
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

