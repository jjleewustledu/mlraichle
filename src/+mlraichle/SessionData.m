classdef SessionData < mlnipet.CommonSessionData
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
    
    methods (Static)
        function sessd = struct2sessionData(sessObj)
            if (isa(sessObj, 'mlraichle.SessionData'))
                sessd = sessObj;
                return
            end
            
            import mlraichle.*;
            assert(isfield(sessObj, 'projectFolder'))
            assert(isfield(sessObj, 'sessionFolder'));
            assert(isfield(sessObj, 'sessionDate'));
            assert(isfield(sessObj, 'parcellation'));
            studyd = StudyData;
            sessp = fullfile(studyd.projectsDir, sessObj.projectFolder, sessObj.sessionFolder, '');
            sessd = SessionData('studyData', studyd, 'sessionPath', sessp, ...
                                'tracer', 'FDG', 'ac', true, 'sessionDate', sessObj.sessionDate);  
            if ( isfield(sessObj, 'parcellation') && ...
                ~isempty(sessObj.parcellation))
                sessd.parcellation = sessObj.parcellation;
            end
        end
    end

    methods
        
        %% GET, SET
        
        function g    = getStudyCensus(this)
            g = mlraichle.StudyCensus(this.STUDY_CENSUS_XLSX_FN', 'sessionData', this);
        end 
        
        %% 
        
        function obj  = mprForReconall(this, varargin)
            obj = this.fqfilenameObject( ...
                fullfile(this.sessionPath, ['mpr' this.filetypeExt]), varargin{:});            
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

        
        %% Metabolism
        
        function obj  = cbfOpFdg(this, varargin)
            obj = this.visitMapOpFdg('cbf', varargin{:});
        end
        function obj  = cbvOpFdg(this, varargin)
            obj = this.visitMapOpFdg('cbv', varargin{:});
        end
        function obj  = oefOpFdg(this, varargin)
            obj = this.visitMapOpFdg('oef', varargin{:});
        end
        function obj  = cmro2OpFdg(this, varargin)
            obj = this.visitMapOpFdg('cmro', varargin{:});
        end
        function obj  = cmrglcOpFdg(this, varargin)
            obj = this.visitMapOpFdg('cmrglc', varargin{:});
        end
        function obj  = ksOpFdg(this, varargin)
            obj = this.visitMapOpFdg('sokoloffKs', varargin{:});
        end
        function obj  = ogiOpFdg(this, varargin)
            obj = this.visitMapOpFdg('ogi', varargin{:});
        end
        function obj  = agiOpFdg(this, varargin)
            % dag := cmrglc - cmro2/6 \approx aerobic glycolysis
            
            obj = this.visitMapOpFdg('agi', varargin{:});
        end        
        function obj  = cbfOnAtl(this, varargin)
            obj = this.visitMapOnAtl('cbf', varargin{:});
        end
        function obj  = cbvOnAtl(this, varargin)
            obj = this.visitMapOnAtl('cbv', varargin{:});
        end
        function obj  = oefOnAtl(this, varargin)
            obj = this.visitMapOnAtl('oef', varargin{:});
        end
        function obj  = cmro2OnAtl(this, varargin)
            obj = this.visitMapOnAtl('cmro', varargin{:});
        end
        function obj  = cmrglcOnAtl(this, varargin)
            obj = this.visitMapOnAtl('cmrglc', varargin{:});
        end
        function obj  = ksOnAtl(this, varargin)
            obj = this.visitMapOnAtl('sokoloffKs', varargin{:});
        end
        function obj  = ogiOnAtl(this, varargin)
            obj = this.visitMapOnAtl('ogi', varargin{:});
        end
        function obj  = agiOnAtl(this, varargin)
            % dag := cmrglc - cmro2/6 \approx aerobic glycolysis
            
            obj = this.visitMapOnAtl('agi', varargin{:});
        end
                
        %%      
        
      	function this = SessionData(varargin)
 			this = this@mlnipet.CommonSessionData(varargin{:});
            if (isempty(this.subjectData_))
                this.subjectData_ = mlraichle.SubjectData();
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

