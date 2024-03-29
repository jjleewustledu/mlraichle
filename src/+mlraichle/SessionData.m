classdef SessionData < mlnipet.MetabolicSessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.    
    
    methods (Static)
        function this = create(varargin)
            %  Args:
            %      folders (text): <proj folder>/<ses folder>/<scan folder>[/file] | 
            %                      <singularity home>/subjects/<sub folder>/<ses folder>/<scan folder>[/file] 
            %                      e.g., 'CCIR_00754/ses-E248568/FDG_DT20180511140741.000000-Converted-AC'
            %                      e.g., '$SINGULARITY_HOME/subjects/sub-S58163/ses-E248568/FDG_DT20180511140741.000000-Converted-AC/fdgr2_op_fdgr1_frame62.4dfp.hdr'
            %      ignoreFinishMark (logical): default := false
            %      reconstructionMethod (text): e.g., 'e7', 'NiftyPET'
            
            ip = inputParser;
            addRequired(ip, 'folders', @istext);
            addParameter(ip, 'ignoreFinishMark', false, @islogical);
            addParameter(ip, 'reconstructionMethod', 'NiftyPET', @ischar);
            addParameter(ip, 'studyRegistry', mlraichle.StudyRegistry.instance());
            parse(ip, varargin{:});
            [ipr,b,ic] = adjustIpr(ip.Results);
    
            this = mlraichle.SessionData( ...
                'studyData', ipr.studyRegistry, ...
                'projectData', mlraichle.ProjectData('projectFolder', ipr.prjfold), ...
                'subjectData', mlraichle.SubjectData('subjectFolder', ipr.subfold), ...
                'sessionFolder', ipr.sesfold, ...
                'scanFolder', ipr.scnfold, ...
                'bids', b, ...
                'imagingContext', ic);
            this.ignoreFinishMark = ipr.ignoreFinishMark;            
            this.reconstructionMethod = ipr.reconstructionMethod;
            
            function [ipr,b,ic] = adjustIpr(ipr)
                ss = strsplit(ipr.folders, filesep);    
                ipr.prjfold = '';
                ipr.subfold = '';
                ipr.sesfold = '';
                ipr.scnfold = '';
                if any(contains(ss, 'CCIR_'))
                    ipr.prjfold = ss{contains(ss, 'CCIR_')}; % 1st match
                end
                if any(contains(ss, 'ses-'))
                    ipr.sesfold = ss{contains(ss, 'ses-')};
                    ipr.subfold = mlraichle.SubjectData().sesFolder2subFolder(ipr.sesfold);
                    ipr.prjfold = mlraichle.ProjectData().session2project(ipr.sesfold);
                end
                if any(contains(ss, 'sub-'))
                    ipr.subfold = ss{contains(ss, 'sub-')};
                end
                if any(contains(ss, '-Converted-'))
                    ipr.scnfold = ss{contains(ss, '-Converted-')};
                end

                b = []; ic = [];
                if isfolder(ipr.folders)
                    b = mlraichle.Ccir559754Bids('destinationPath', ipr.folders);
                end
                if isfile(ipr.folders)
                    b = mlraichle.Ccir559754Bids('destinationPath', myfileparts(ipr.folders));
                    ic = mlfourd.ImagingContext2(ipr.folders);
                end
            end
        end
        function sessd = struct2sessionData(sessObj)
            if (isa(sessObj, 'mlraichle.SessionData'))
                sessd = sessObj;
                return
            end
            
            import mlraichle.*;
            assert(isfield(sessObj, 'projectFolder'))
            assert(isfield(sessObj, 'sessionFolder'));
            assert(isfield(sessObj, 'sessionDate'));
            studyd = StudyRegistry.instance();
            sessp = fullfile(studyd.projectsDir, sessObj.projectFolder, sessObj.sessionFolder, '');
            sessd = SessionData('studyData', studyd, ...
                                'sessionPath', sessp, ...
                                'tracer', 'FDG', ...
                                'ac', true, ...
                                'sessionDate', sessObj.sessionDate);  
            if ( isfield(sessObj, 'parcellation') && ...
                ~isempty(sessObj.parcellation))
                sessd.parcellation = sessObj.parcellation;
            end
            if ( isfield(sessObj, 'region') && ...
                ~isempty(sessObj.region))
                sessd.region = sessObj.region;
            end
        end
    end

    properties (Constant)
        STUDY_CENSUS_XLSX_FN = 'census 2018may31.xlsx'
    end
    
    properties
        defects = {'20180511133140' '20180511120621' '20190110105722' '20190110122045'}
        tracers = {'fdg' 'ho' 'oo' 'oc'}
    end

    properties (Dependent)
        projectsDir % homolog of __Freesurfer__ subjectsDir
        projectsPath
        projectsFolder
        projectPath
        projectFolder % \in projectsFolder        
        
        subjectsDir % __Freesurfer__ convention
        subjectsPath 
        subjectsFolder 
        subjectPath
        subjectFolder % \in subjectsFolder  
        
        sessionsDir % __Freesurfer__ convention
        sessionsPath 
        sessionsFolder 
        sessionPath
        sessionFolder % \in projectFolder        
        
        scansDir % __Freesurfer__ convention
        scansPath 
        scansFolder 
        scanPath
        scanFolder % \in sessionFolder

        dataPath
        dataFolder

        bids
        imagingContext
        registry
    end

    methods
            
        %% GET

        function g    = get.projectsDir(this)
            if ~isempty(this.studyData_)
                g = this.studyData_.projectsDir;
                return
            end
            if ~isempty(this.projectData_)
                g = this.projectData_.projectsDir;
                return
            end
            error('mlpipeline:RuntimeError', 'SessionData.get.projectsDir')
        end
        function this = set.projectsDir(this, s)
            assert(ischar(s))
            if ~isempty(this.studyData_)
                this.studyData_.projectsDir = s;
                return
            end
            if ~isempty(this.projectData_)
                this.projectData_.projectsDir = s;
                return
            end
            error('mlpipeline:RuntimeError', 'SessionData.get.projectsDir')
        end
        function g    = get.projectsPath(this)
            g = this.projectsDir;
        end
        function g    = get.projectsFolder(this)
            g = this.projectsDir;
            if (strcmp(g(end), filesep))
                g = g(1:end-1);
            end
            g = mybasename(g);
        end     
        function g    = get.projectPath(this)
            g = fullfile(this.projectsPath, this.projectFolder);
        end
        function g    = get.projectFolder(this)
            g = this.projectData.projectFolder;
        end
        
        function g    = get.subjectsDir(this)
            g = this.studyData_.subjectsDir;
        end
        function this = set.subjectsDir(this, s)
            assert(ischar(s));
            this.studyData_.subjectsDir = s;
        end
        function g    = get.subjectsPath(this)
            g = this.subjectsDir;
        end
        function g    = get.subjectsFolder(this)
            g = this.subjectsDir;
            if (strcmp(g(end), filesep))
                g = g(1:end-1);
            end
            g = mybasename(g);
        end 
        function g    = get.subjectPath(this)
            g = this.subjectData.subjectPath;
        end
        function g    = get.subjectFolder(this)
            g = this.subjectData.subjectFolder;
        end  
        
        function g    = get.sessionsDir(this)
            g = this.projectPath;
        end
        function g    = get.sessionsPath(this)
            g = this.sessionsDir;
        end
        function g    = get.sessionsFolder(this)
            g = this.projectFolder;
        end
        function g    = get.sessionPath(this)
            g = fullfile(this.projectPath, this.sessionFolder);
        end
        function this = set.sessionPath(this, s)
            assert(ischar(s));
            [this.projectPath,this.sessionFolder] = fileparts(s);
        end
        function g    = get.sessionFolder(this)
            g = this.sessionFolder_;
        end        
        function this = set.sessionFolder(this, s)
            assert(ischar(s));
            this.sessionFolder_ = s;            
        end    
        
        function g    = get.scansDir(this)
            g = this.sessionPath;
        end
        function g    = get.scansPath(this)
            g = this.scansDir;
        end
        function g    = get.scansFolder(this)
            g = this.sessionFolder;
        end
        function g    = get.scanPath(this)
            g = fullfile(this.sessionPath, this.scanFolder);
        end
        function this = set.scanPath(this, s)
            assert(ischar(s));
            [this.sessionPath,this.scanFolder] = myfileparts(s);
        end
        function g    = get.scanFolder(this)
            if (~isempty(this.scanFolder_))
                g = this.scanFolder_;
                return
            end
            g = this.bootstrapScanFolder();
        end
        function this = set.scanFolder(this, s)
            this = this.setScanFolder(s);
        end

        function g    = get.dataPath(this)
            g = fullfile(this.subjectPath, this.dataFolder, '');
        end
        function g    = get.dataFolder(this)
            g = this.dataFolder_;
        end
        function this = set.dataFolder(this, s)
            assert(istext(s));
            this.dataFolder_ = s;
        end

        function g    = get.bids(this)
            g = copy(this.bids_);
        end
        function g    = get.imagingContext(this)
            g = copy(this.imagingContext_);
        end
        function g    = get.registry(this)
            g = this.registry_;
        end

        %% 
        
        function g    = getStudyCensus(this)
            g = mlraichle.StudyCensus(this.STUDY_CENSUS_XLSX_FN', 'sessionData', this);
        end 
        function this = manageLegacyStudyData(this, studyd)
            assert(isa(studyd, 'mlraichle.StudyData'))
            if isempty(this.subjectData_)
                this.subjectData_ = mlraichle.SubjectData();
            end
            this.subjectData_.studyData = studyd;
        end
        function loc  = tracerRawdataLocation(this, varargin)
            %% Siemens legacy
            ipr = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.studyData.rawdataPath);
                return
            end
            loc = this.tracerConvertedLocation(varargin{:});
        end        
        
      	function this = SessionData(varargin)
 			this = this@mlnipet.MetabolicSessionData(varargin{:});

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'bids', []);
            addParameter(ip, 'imagingContext', []);
            addParameter(ip, 'registry', mlvg.Ccir1211Registry.instance());
            parse(ip, varargin{:});   
            ipr = ip.Results;
            this.bids_ = ipr.bids;
            this.imagingContext_ = ipr.imagingContext;
            this.registry_ = ipr.registry;
            if isempty(this.tracer_) && ~isempty(this.bids_) && ~isempty(this.imagingContext_)
                this.tracer_ = this.bids_.obj2tracer(this.imagingContext_);
            end

            this.ReferenceTracer = 'FDG';
            if isempty(this.studyData_)
                this.studyData_ = mlraichle.StudyData();
            end
            if isempty(this.projectData_)
                this.projectData_ = mlraichle.ProjectData('sessionStr', this.sessionFolder);
            end

            this.dataFolder_ = 'resampling_restricted';
            
            %% taus
            
            if (~isempty(this.scanFolder_) && isfile(this.jsonFilename))
                j = jsondecode(fileread(this.jsonFilename));
                this.taus_ = j.taus';
            end
        end
    end

    %% PRIVATE

    properties (Access = private)
        bids_
        dataFolder_
        imagingContext_
        registry_
    end
    
    %% HIDDEN, DEPRECATED
    
    methods (Hidden)
        function obj  = tracerResolvedSubj(this, varargin)
            %% TRACERRESOLVEDSUBJ is designed for use with mlraichle.SubjectImages.
            %  TODO:  reconcile use of ipr.destVnumber.
            %  @param named name; e.g., 'cbfv1r2'.
            %  @param named rnumber.
            %  @param named dest.
            %  @param named tag1 is inserted before '_op_'; e.g., '_sumt'
            %  @param named tag2 is inserted before this.filetypeExt; e.g., '_sumxyz'.
                       
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'name', this.tracerRevision('typ','fp'), @ischar);
            addParameter(ip, 'dest', 'fdg', @ischar);
            addParameter(ip, 'destVnumber', 1, @isnumeric); 
            addParameter(ip, 'destRnumber', 1, @isnumeric); 
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});  
            ipr = ip.Results;
            
            this.attenuationCorrected = true;
            this.epoch = [];
            ensuredir(this.vallLocation);
            fqfn = fullfile( ...
                this.vallLocation, ...
                sprintf('%s%s_op_%sv%ir%i%s', ...
                        ipr.name, ipr.tag, ipr.dest, ipr.destVnumber, ipr.destRnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end        
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

