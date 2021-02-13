classdef SessionData < mlnipet.ResolvingSessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.    
    
    properties (Constant)
        STUDY_CENSUS_XLSX_FN = 'census 2018may31.xlsx'
    end
    
    properties
        registry
        tracers = {'fdg' 'ho' 'oo' 'oc'}
    end
    
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
    
            this = SessionData( ...
                'studyData', StudyRegistry.instance(), ...
                'projectData', ProjectData('projectFolder', ipr.prjfold), ...
                'subjectData', SubjectData('subjectFolder', ipr.subfold), ...
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
            studyd = StudyData;
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

    methods
        function obj  = aifsOnAtlas(this, varargin)
            tr = lower(this.tracer);
            obj = this.metricOnAtlas(['aif_' tr], varargin{:});
        end
        function obj  = brainOnAtlas(this, varargin)
            obj = this.metricOnAtlas('brain', 'datetime', '',varargin{:});
        end
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
        function obj  = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonlhy is logical.
            %  @param tags is char, e.g., '_b43_wmparc1_b43'
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @ischar)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;
            
            if ischar(ipr.datetime)
                adatestr = ipr.datetime;
            end
            if isdatetime(ipr.datetime)
                if ipr.dateonly
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmdd') '000000'];
                else
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmddHHMMSS')];
                end
            end
            
            fqfn = fullfile( ...
                this.dataPath, ...
                sprintf('%s%s%s%s%s', ...
                        lower(ipr.metric), ...
                        adatestr, ...
                        this.registry.atlasTag, ...
                        ipr.tags, ...
                        this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = mprForReconall(this, varargin)
            obj = this.fqfilenameObject( ...
                fullfile(this.sessionPath, ['mpr' this.filetypeExt]), varargin{:});            
        end        
        function obj  = parcOnAtlas(this, varargin)
            fqfn = fullfile( ...
                this.dataPath, ...
                sprintf('%s%s%s', this.parcellation, this.registry.atlasTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
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
        function obj  = tracerOnAtlas(this, varargin)
            obj = this.metricOnAtlas(this.tracer, varargin{:});
        end
        function obj  = venousOnAtlas(this, varargin)
            obj = this.metricOnAtlas('venous', 'datetime', '',varargin{:});
        end
        function obj  = wbrain1OnAtlas(this, varargin)
            
            % prepare as needed
            wm_fqfn = this.wmparc1OnAtlas('typ', 'fqfilename');
            assert(isfile(wm_fqfn))
            wb_fqfn = strrep(wm_fqfn, 'wmparc1', 'wbrain1');
            if ~isfile(wb_fqfn)
                ic = mlfourd.ImagingContext2(wm_fqfn);
                ic = ic.binarized();
                ic.fileprefix = strrep(ic.fileprefix, 'wmparc1', 'wbrain1');
                ic.save()
            end
            
            obj = this.metricOnAtlas('wbrain1', 'datetime', '',varargin{:});
        end
        function obj  = wmparcOnAtlas(this, varargin)
            obj = this.metricOnAtlas('wmparc', 'datetime', '',varargin{:});
        end
        function obj  = wmparc1OnAtlas(this, varargin)
            obj = this.metricOnAtlas('wmparc1', 'datetime', '',varargin{:});
        end
        
        %% Metabolism
        
        function obj  = agiOnAtlas(this, varargin)
            % dag := cmrglc - cmro2/6 \approx aerobic glycolysis
            
            obj = this.metricOnAtlas('agi', varargin{:});
        end        
        function obj  = cbfOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbf', varargin{:});
        end
        function obj  = cbvOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbv', varargin{:});
        end
        function obj  = chiOnAtlas(this, varargin)
            obj = this.metricOnAtlas('chi', varargin{:});
        end
        function obj  = cmrglcOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmrglc', varargin{:});
        end
        function obj  = cmro2OnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmro', varargin{:});
        end
        function obj  = coOnAtlas(this, varargin)
            obj = this.metricOnAtlas('co', varargin{:});
        end
        function obj  = fdgOnAtlas(this, varargin)            
            obj = this.metricOnAtlas('fdg', varargin{:});
        end
        function obj  = fsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('fs', varargin{:});
        end
        function obj  = gsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('gs', varargin{:});
        end
        function obj  = hoOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ho', varargin{:});
        end
        function obj  = KsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('Ks', varargin{:});
        end
        function obj  = ksOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ks', varargin{:});
        end
        function obj  = maskOnAtlas(this, varargin)
            obj = this.metricOnAtlas('mask', varargin{:});
        end
        function obj  = ocOnAtlas(this, varargin)
            obj = this.metricOnAtlas('oc', varargin{:});
        end
        function obj  = ooOnAtlas(this, varargin)
            obj = this.metricOnAtlas('oo', varargin{:});
        end
        function obj  = osOnAtlas(this, varargin)
            obj = this.metricOnAtlas('os', varargin{:});
        end
        function obj  = oefOnAtlas(this, varargin)
            obj = this.metricOnAtlas('oef', varargin{:});
        end
        function obj  = ogiOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ogi', varargin{:});
        end
        function obj  = v1OnAtlas(this, varargin)
            obj = this.metricOnAtlas('v1', varargin{:});
        end
        function obj  = vsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('vs', varargin{:});
        end
                
        %% 
        
      	function this = SessionData(varargin)
 			this = this@mlnipet.ResolvingSessionData(varargin{:});
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
            
            if (~isempty(this.scanFolder_) && lexist(this.jsonFilename, 'file'))
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

