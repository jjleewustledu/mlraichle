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
            % @param folders found in getenv('SINGULARITY_HOME'):
            %        ~ <project folder>/<session folder>/<scan folder> or
            %        ~ subjects/<subject folder>/<session folder>/<scan folder>
            % @param ignoreFinishMark is logical, default := false
            
            import mlraichle.*

            ip = inputParser;
            addRequired(ip, 'folders', @(x) isfolder(fullfile(getenv('SINGULARITY_HOME'), x)));
            addParameter(ip, 'ignoreFinishMark', false, @islogical);
            addParameter(ip, 'reconstructionMethod', 'NiftyPET', @ischar);
            parse(ip, varargin{:});
            ipr = adjustIpr(ip.Results);
    
            this = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyRegistry.instance(), ...
                'projectData', mlraichle.ProjectData('projectFolder', ipr.prjfold), ...
                'subjectData', mlraichle.SubjectData('subjectFolder', ipr.subfold), ...
                'sessionFolder', ipr.sesfold, ...
                'scanFolder', ipr.scnfold);
            this.ignoreFinishMark = ipr.ignoreFinishMark;            
            this.reconstructionMethod = ipr.reconstructionMethod;
            
            function ipr = adjustIpr(ipr)
                ss = strsplit(ipr.folders, filesep);
                if lstrfind(ss{1}, 'subjects')
                    p = mlraichle.ProjectData();
                    ipr.subfold = ss{2};
                    ipr.prjfold = p.session2project(ss{3});
                    ipr.sesfold = ss{3};
                    if length(ss) >= 3
                        ipr.scnfold = ss{4};
                    else
                        ipr.scnfold = '';
                    end
                    return
                end
                
                ipr.prjfold = ss{1};
                ipr.subfold = mlraichle.SubjectData().sesFolder2subFolder(ss{2});
                ipr.sesfold = ss{2};
                if length(ss) >= 3
                    ipr.scnfold = ss{3};
                else
                    ipr.scnfold = '';
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
        registry
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

            %% KLUDGE for bootstrapping

            if isempty(this.tracer_) || isempty(this.attenuationCorrected_)
                g = '';
                dt = datetime(datestr(now));
                for globbed = globFoldersT(fullfile(this.sessionPath, '*_DT*.000000-Converted-*'))
                    base = mybasename(globbed{1});
                    re = regexp(base, ...
                        '\S+_DT(?<yyyy>\d{4})(?<mm>\d{2})(?<dd>\d{2})(?<HH>\d{2})(?<MM>\d{2})(?<SS>\d{2})\.\d{6}-Converted\S*', ...
                        'names');
                    assert(~isempty(re))
                    dt1 = datetime(str2double(re.yyyy), str2double(re.mm), str2double(re.dd), ...
                        str2double(re.HH), str2double(re.MM), str2double(re.SS));
                    if dt1 < dt
                        dt = dt1; % find earliest scan
                        g = base;
                    end                    
                end                
                return
            end
            dtt = mlpet.DirToolTracer( ...
                'tracer', fullfile(this.sessionPath, this.tracer_), ...
                'ac', this.attenuationCorrected_);            
            assert(~isempty(dtt.dns));
            try
                g = dtt.dns{this.scanIndex};
            catch ME
                if length(dtt.dns) < this.scanIndex 
                    error('mlnipet:ValueError:getScanFolder', ...
                        'SessionData.getScanFolder().this.scanIndex->%s', mat2str(this.scanIndex))
                else
                    rethrow(ME)
                end
            end
        end
        function this = set.scanFolder(this, s)
            this = this.setScanFolder(s);
        end

        function g    = get.dataPath(this)
            g = fullfile(this.subjectPath, this.dataFolder, '');
        end
        function g = get.dataFolder(~)
            g = 'resampling_restricted';
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

            if isempty(this.studyData_)
                this.studyData_ = mlraichle.StudyData();
            end
            this.ReferenceTracer = 'FDG';
            if isempty(this.projectData_)
                this.projectData_ = mlraichle.ProjectData('sessionStr', this.sessionFolder);
            end
            
            %% registry
            
            this.registry = mlraichle.StudyRegistry.instance();
            
            %% taus
            
            if (~isempty(this.scanFolder_) && isfile(this.jsonFilename))
                j = jsondecode(fileread(this.jsonFilename));
                this.taus_ = j.taus';
            end
        end
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

