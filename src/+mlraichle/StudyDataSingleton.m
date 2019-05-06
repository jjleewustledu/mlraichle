classdef StudyDataSingleton < handle & mlpipeline.StudyDataSingleton
	%% STUDYDATASINGLETON  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
        
    properties (Dependent)
        dicomExtension
        rawdataDir
        projectsDir
        subjectsDir
        YeoDir
    end

    methods (Static)
        function this = instance(varargin)
            persistent instance_
            if (~isempty(varargin))
                instance_ = [];
            end
            if (isempty(instance_))
                instance_ = mlraichle.StudyDataSingleton(varargin{:});
            end
            this = instance_;
        end
    end
    
    methods
        
        %% GET
        
        function g = get.dicomExtension(~)
            d = mlraichle.RaichleRegistry.instance.dicomExtension;
        end
        function d = get.rawdataDir(~)
            d = mlraichle.RaichleRegistry.instance.subjectsDir;
        end
        function g = get.projectsDir(~)
            g = mlraichle.RaichleRegistry.instance.projectsDir;
        end
        function g = get.subjectsDir(~)
            g = mlraichle.RaichleRegistry.instance.subjectsDir;
        end
        function g = get.YeoDir(~)
            g = mlraichle.RaichleRegistry.instance.YeoDir;
        end
        
        %%
        
        function        register(this, varargin)
            %% REGISTER this class' persistent instance with mlpipeline.StudyDataSingletons
            %  using the latter class' register methods.
            %  @param key is any registration key stored by mlpipeline.StudyDataSingletons; default 'derdeyn'.
            
            ip = inputParser;
            addOptional(ip, 'key', 'raichle', @ischar);
            parse(ip, varargin{:});
            mlpipeline.StudyDataSingletons.register(ip.Results.key, this);
        end
        function this = replaceSessionData(this, varargin)
            %% REPLACESESSIONDATA completely replaces this.sessionDataComposite_.
            %  @param must satisfy parameter requirements of mlraichle.SessionData;
            %  'studyData' and this are always internally supplied.
            %  @returns this.

            this.sessionDataComposite_ = mlpatterns.CellComposite({ ...
                mlraichle.SessionData('studyData', this, varargin{:})});
        end
        function        seriesDicomAsterisk(~, varargin)
            error('pythonic:NotImplementedError', 'mlraichle.StudyDataSingleton.seriesDicomAsterisk')
        end
        function        subjectsDirFqdns(~)
            error('pythonic:NotImplementedError', 'mlraichle.StudyDataSingleton.subjectsDirFqdns')
        end
    end
    
    %% PROTECTED
    
	methods (Access = protected)   
 		function this = StudyDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:});
        end
        function this = assignSessionDataCompositeFromPaths(this, varargin)
            %% ASSIGNSESSIONDATACOMPOSITEFROMPATHS
            %  @param [1...N] that is dir, add to this.sessionDataComposite_.
            
            for v = 1:length(varargin)
                if (ischar(varargin{v}) && isdir(varargin{v}))                    
                    this.sessionDataComposite_ = ...
                        this.sessionDataComposite_.add( ...
                            mlraichle.SessionData('studyData', this, 'sessionPath', varargin{v}));
                end
            end
        end
        function that = copyElement(this)
            that = mlraichle.StudyData;
            that.comments = this.comments;
            that.sessionDataComposite_ = this.sessionDataComposite_;
        end
    end   

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

