classdef StudyDataSingleton < mlpipeline.StudyDataSingleton
	%% STUDYDATASINGLETON  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties (SetAccess = private)
        raichleTrunk = '/Volumes/SeagateBP4/raichle'

        mriFolder = ''
        petFolder = ''
        hdrinfoFolder = ''
        fslFolder = 'fsl'
    end
    
	properties (Dependent)
        subjectsDirs
        loggingPath
    end
    
    methods %% GET
        function g = get.subjectsDirs(this)
            g = fullfile(this.raichleTrunk, 'idaif', '');
        end
        function g = get.loggingPath(this)
            g = this.raichleTrunk;
        end
    end

    methods (Static)
        function this = instance(qualifier)
            persistent instance_            
            if (exist('qualifier','var'))
                assert(ischar(qualifier));
                if (strcmp(qualifier, 'initialize'))
                    instance_ = [];
                end
            end            
            if (isempty(instance_))
                instance_ = mlraichle.StudyDataSingleton();
            end
            this = instance_;
        end
        function        register(varargin)
            %% REGISTER
            %  @param []:  if this class' persistent instance
            %  has not been registered, it will be registered via instance() call to the ctor; if it
            %  has already been registered, it will not be re-registered.
            %  @param ['initialize']:  any registrations made by the ctor will be repeated.
            
            mlraichle.StudyDataSingleton.instance(varargin{:});
        end
    end
    
	methods (Access = private)	   
 		function this = StudyDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:});
            mlpipeline.StudyDataSingletons.register('raichle', this);
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

