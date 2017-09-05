classdef StudyData < mlpipeline.StudyData
	%% STUDYDATA  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
    
    
    properties (SetAccess = protected)
        dicomExtension = 'dcm'
    end
    
    properties (Dependent)
        subjectsDir
        subjectsFolder
    end
    
    methods
        
        %% GET
        
        function g = get.subjectsDir(this)
            g = this.subjectsDir_;
        end
        function g = get.subjectsFolder(this)
            [~,g] = fileparts(this.subjectsDir);
        end
        
        function this = set.subjectsDir(this, s)
            assert(ischar(s));       
            this.subjectsDir_ = s;
        end
        function this = set.subjectsFolder(this, s)
            assert(ischar(s));
            this.subjectsDir_ = fullfile(fileparts(this.subjectsDir_), s, '');
        end
        
        %% concrete implementations of abstract mlpipeline.StudyDataHandle
        
        function d    = freesurfersDir(this)
            d = fullfile(fileparts(this.subjectsDir), 'freesurfer', '');
        end
        function d    = rawdataDir(this)
            d = fullfile(fileparts(this.subjectsDir), 'rawdata', '');
        end
        function this = replaceSessionData(this, varargin)
            %% REPLACESESSIONDATA
            %  @param must satisfy parameter requirements of mlraichle.SessionData.
            %  @returns this.

            this.sessionDataComposite_ = mlpatterns.CellComposite({ ...
                mlraichle.SessionData('studyData', this, varargin{:})});
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
        
        %%
        
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
        function a    = seriesDicomAsterisk(this, fqdn)
            assert(isdir(fqdn));
            assert(isdir(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*.' this.dicomExtension]);
        end
        function f    = subjectsDirFqdns(this)
            if (isempty(this.subjectsDir))
                f = {};
                return
            end
            
            dt = mlsystem.DirTools(this.subjectsDir);
            f = {};
            for di = 1:length(dt.dns)
                if (strncmp(dt.dns{di}, 'NP', 2) || strncmp(dt.dns{di}, 'HY', 2))
                    f = [f dt.fqdns(di)]; %#ok<AGROW>
                end
            end
        end
        
 		function this = StudyData(varargin)
 			this = this@mlpipeline.StudyData(varargin{:});
            this.subjectsDir_ = mlraichle.RaichleRegistry.instance.subjectsDir;
        end        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        subjectsDir_
    end
    
	methods (Access = protected)
        function this = assignSessionDataCompositeFromPaths(this, varargin)
            %% ASSIGNSESSIONDATACOMPOSITEFROMPATHS
            %  @param varargin cell containing directories.
            
            for v = 1:length(varargin)
                if (ischar(varargin{v}) && isdir(varargin{v}) && ~isempty(this.sessionDataComposite_))                    
                    this.sessionDataComposite_ = ...
                        this.sessionDataComposite_.add( ...
                            mlraichle.SessionData('studyData', this, 'sessionPath', varargin{v}));
                end
            end
        end
    end   

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

