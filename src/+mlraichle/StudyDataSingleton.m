classdef StudyDataSingleton < mlpipeline.StudyDataSingleton
	%% STUDYDATASINGLETON  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties (SetAccess = protected)
        raichleTrunk = '/Volumes/SeagateBP4/raichle/PPGdata'
    end
    
	properties (Dependent)
        subjectsDir
        loggingPath
    end
    
    methods %% GET
        function g = get.subjectsDir(this)
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
    
    methods
        function f = fslFolder(~, sessDat)
            f = sprintf('V%i', sessDat.snumber);
        end
        function f = hdrinfoFolder(~, sessDat)
            f = sprintf('V%i', sessDat.snumber);
        end
        function f = mriFolder(~, sessDat)
            f = sprintf('V%i', sessDat.snumber);
        end
        function f = petFolder(~, sessDat)
            f = sprintf('V%i', sessDat.snumber);
        end      
        
        function fn = ho_fn(~, sessDat)
            fn = sprintf('%sho%i.4dfp.nii.gz', sessDat.sessionFolder, sessDat.snumber);
        end
        function fn = oc_fn(~, sessDat)
            fn = sprintf('%soc%i.4dfp.nii.gz', sessDat.sessionFolder, sessDat.snumber);
        end
        function fn = mpr_fn(~, sessDat)
            fn = sprintf('%s_mpr.4dfp.nii.gz', sessDat.sessionFolder);
        end
        function fn = oo_fn(~, sessDat)
            fn = sprintf('%soo%i.4dfp.nii.gz', sessDat.sessionFolder, sessDat.snumber);
        end
        function fn = petfov_fn(~)
            fn = 'PETFOV.4dfp.nii.gz';
        end
        function fn = tof_fn(~)
            fn = 'TOF_ART.4dfp.nii.gz';
        end
        function fn = toffov_fn(~)
            fn = 'AIFFOV.4dfp.nii.gz';
        end
    end
    
    %% PROTECTED
    
	methods (Access = protected)   
 		function this = StudyDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:});
            
            dt = mlsystem.DirTools(this.subjectsDir);
            fqdns = {};
            for di = 1:length(dt.dns)
                if (strcmp(dt.dns{di}(1),   'p')  || ...
                    strcmp(dt.dns{di}(1:2), 'NP') || ...
                    strcmp(dt.dns{di}(1:2), 'TW') || ...
                    strcmp(dt.dns{di}(1:5), 'HYGLY'))
                    fqdns = [fqdns dt.fqdns(di)];
                end
            end
            this.sessionDataComposite_ = ...
                mlpatterns.CellComposite( ...
                    cellfun(@(x) mlpipeline.SessionData('studyData', this, 'sessionPath', x), ...
                    fqdns, 'UniformOutput', false));            
            this.registerThis;
        end
        function registerThis(this)
            mlpipeline.StudyDataSingletons.register('raichle', this);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

