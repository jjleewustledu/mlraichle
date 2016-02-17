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
            f = sprintf('V%i', sessDat.vnumber);
        end
        function f = hdrinfoFolder(~, sessDat)
            f = sprintf('V%i', sessDat.vnumber);
        end
        function f = mriFolder(~, sessDat)
            f = sprintf('V%i', sessDat.vnumber);
        end
        function f = petFolder(~, sessDat)
            f = sprintf('V%i', sessDat.vnumber);
        end      
        
        function fn = fdg_fn(~, sessDat, varargin)            
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})  
            fn = sprintf('%sfdg%s.4dfp.nii.gz', sessDat.sessionFolder, ip.Results.suff);
        end
        function fn = ho_fn(~, sessDat, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('%sho%i%s.4dfp.nii.gz', sessDat.sessionFolder, sessDat.snumber, ip.Results.suff);
        end
        function fn = mpr_fn(~, sessDat, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('%s_mpr%s.4dfp.nii.gz', sessDat.sessionFolder, ip.Results.suff);
        end
        function fn = oc_fn(~, sessDat, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('%soc%i%s.4dfp.nii.gz', sessDat.sessionFolder, sessDat.snumber, ip.Results.suff);
        end
        function fn = oo_fn(~, sessDat, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('%soo%i%s.4dfp.nii.gz', sessDat.sessionFolder, sessDat.snumber, ip.Results.suff);
        end
        function fn = petfov_fn(~, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('PETFOV%s.4dfp.nii.gz', ip.Results.suff);
        end
        function fn = tof_fn(~, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('TOF_ART%s.4dfp.nii.gz', ip.Results.suff);
        end
        function fn = toffov_fn(~, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            fn = sprintf('AIFFOV%s.4dfp.nii.gz', ip.Results.suff);
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
                    cellfun(@(x) mlraichle.SessionData('studyData', this, 'sessionPath', x), ...
                    fqdns, 'UniformOutput', false));            
            this.registerThis;
        end
        function registerThis(this)
            mlpipeline.StudyDataSingletons.register('raichle', this);
        end
    end     

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

