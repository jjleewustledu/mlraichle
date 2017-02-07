classdef StudyDataSingleton < mlpipeline.StudyDataSingleton
	%% STUDYDATASINGLETON  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
    

    properties
        subjectsFolder = 'jjlee2'
    end

    properties (SetAccess = protected)
        dicomExtension = 'dcm'
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
        function d    = freesurfersDir(~)
            d = fullfile(getenv('PPG'), 'freesurfer', '');
        end
        function d    = RawDataDir(this, sessFold)
            %% RAWDATADIR
            %  @param sessFold is the name of the folder in rawdataDir that contains session data.
            %  @returns a path to the session data ending in 'RawData' or the empty string on failures.
            
            import mlraichle.*;
            assert(ischar(sessFold));
            d = fullfile(this.rawdataDir, sessFold, 'RESOURCES', 'RawData', '');
            if (~isdir(d))
                d = fullfile(this.rawdataDir, sessFold, 'resources', 'RawData', '');
            end
            if (~isdir(d))
                d = '';
            end
        end
        function d    = rawdataDir(~)
            d = fullfile(getenv('PPG'), 'rawdata', '');
        end
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
        function a    = seriesDicomAsterisk(this, fqdn)
            assert(isdir(fqdn));
            assert(isdir(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*.' this.dicomExtension]);
        end
        function sess = sessionData(this, varargin)
            %% SESSIONDATA
            %  @param [parameter name,  parameter value, ...] as expected by mlraichle.SessionData are optional;
            %  'studyData' and this are always internally supplied.
            %  @returns for empty param:  mlpatterns.CellComposite object or it's first element when singleton, 
            %  which are instances of mlraichle.SessionData.
            %  @returns for non-empty param:  instance of mlraichle.SessionData corresponding to supplied params.
            
            if (isempty(varargin))
                sess = this.sessionDataComposite_;
                if (1 == length(sess))
                    sess = sess.get(1);
                end
                return
            end
            sess = mlraichle.SessionData('studyData', this, varargin{:});
        end  
        function d    = subjectsDir(this)
            d = fullfile(getenv('PPG'), this.subjectsFolder, '');
        end
        function f    = subjectsDirFqdns(this)
            dt = mlsystem.DirTools(this.subjectsDir);
            f = {};
            for di = 1:length(dt.dns)
                if (strcmp(dt.dns{di}(1:2), 'NP') || ...
                    strcmp(dt.dns{di}(1:2), 'HY'))
                    f = [f dt.fqdns(di)]; %#ok<AGROW>
                end
            end
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
    end   

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

