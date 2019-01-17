classdef SessionData < mlpipeline.ResolvingSessionData & mlnipet.ISessionData
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
        ensureFqfilename = false
        fractionalImageFrameThresh = 0.1 % of median
        filetypeExt = '.4dfp.hdr'
        fullFov = [344 344 127];
        modality
        supScanList = 3
        tauMultiplier = 1 % 1,2,4,8,16
        tracerBlurArg = 7.5
        umapBlurArg = 1.5
        atlVoxelSize = 333
        
        %% mlnipet.ISessionData
        
        itr = 4
        outfolder = 'output'
    end
    
	properties (Dependent)    
        project
        subject
        session
        scan
        resource
        assessor
        
        STUDY_CENSUS_XLSX
        
        attenuationTag
        compositeT4ResolveBuilderBlurArg
        convertedTag
        doseAdminDatetimeTag
        frameTag    
        indicesLogical
        maxLengthEpoch
        regionTag
        studyCensus
        supEpoch
        t4ResolveBuilderBlurArg
        tauIndices % use to exclude late frames from builders of AC; e.g., HYGLY25 V1; taus := taus(tauIndices)
        taus
        times
        vfolder
        
        %% mlnipet.ISessionData
        
        lmTag
    end
    
    methods (Static)
        function sessd = struct2sessionData(sessObj)
            if (isa(sessObj, 'mlraichle.SessionData'))
                sessd = sessObj;
                return
            end
            
            import mlraichle.*;
            assert(isfield(sessObj, 'sessionFolder'));
            assert(isfield(sessObj, 'vnumber'));
            assert(isfield(sessObj, 'sessionDate'));
            assert(isfield(sessObj, 'parcellation'));
            studyd = StudyData;
            sessp = fullfile(studyd.subjectsDir, sessObj.sessionFolder, '');
            sessd = SessionData('studyData', studyd, 'sessionPath', sessp, ...
                                'tracer', 'FDG', 'ac', true, 'vnumber', sessObj.vnumber, 'sessionDate', sessObj.sessionDate);  
            if ( isfield(sessObj, 'parcellation') && ...
                ~isempty(sessObj.parcellation))
                sessd.parcellation = sessObj.parcellation;
            end
        end
        function v = visit2double(vstr)
            v = str2double(vstr(2:end));
        end
    end

    methods
        
        %% GET
        
        function g = get.project(this)
             g = [];
        end
        function g = get.subject(this)
             g = [];
        end
        function g = get.session(this)
             g = [];
        end
        function g = get.scan(this)
            g = this.tracerRevision('typ', 'fp');
        end  
        function g = get.resource(this)
             g = [];
        end
        function g = get.assessor(this)
             g = [];
        end
        
        function g = get.STUDY_CENSUS_XLSX(this)
            g = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), this.STUDY_CENSUS_XLSX_FN);
        end
        
        function g = get.attenuationTag(this)
            if (this.attenuationCorrected)
                if (this.absScatterCorrected)
                    g = 'Abs';
                    return
                end
                g = 'AC';
                return
            end
            g = 'NAC';
        end
        function g = get.compositeT4ResolveBuilderBlurArg(this)
            if (~this.attenuationCorrected)
                g = this.umapBlurArg;
            else
                g = this.tracerBlurArg;
            end
        end
        function g = get.convertedTag(this)
            if (~isnan(this.frame_))
                g = sprintf('Converted-Frame%i-%s', this.frame_, this.attenuationTag);
                return
            end
            g = ['Converted-' this.attenuationTag];
        end
        function g = get.doseAdminDatetimeTag(this)
            switch (this.tracer)
                case 'OC'
                    if (1 == this.snumber)
                        g = 'C[15O]';
                        return
                    end
                    g = sprintf('C[15O]_%i', this.snumber-1);
                case 'OO'
                    if (1 == this.snumber)
                        g = 'O[15O]';
                        return
                    end
                    g = sprintf('O[15O]_%i', this.snumber-1);
                case 'HO'
                    if (1 == this.snumber)
                        g = 'H2[15O]';
                        return
                    end
                    g = sprintf('H2[15O]_%i', this.snumber-1);
                case 'FDG'
                    g = '[18F]DG';
                otherwise                    
                    error('mlraichle:unsupportedSwitchcase', 'SessionData.doseAdminDatetimeTag');
            end
        end
        function g = get.frameTag(this)
            assert(isnumeric(this.frame));
            if (isnan(this.frame))
                g = '';
                return
            end
            g = sprintf('_frame%i', this.frame);
        end
        function g = get.indicesLogical(this) %#ok<MANU>
            g = true;
            return
        end
        function g = get.maxLengthEpoch(this)
            if (~this.attenuationCorrected)
                g = 8;
                return
            end 
            g = 24;
        end
        function     set.maxLengthEpoch(~, ~)
            error('mlraichle:notImplemented', 'SessionData.set.maxLengthEpoch');
        end
        function g = get.regionTag(this)
            if (isempty(this.region))
                g = '';
                return
            end
            if (isnumeric(this.region))                
                g = sprintf('_%i', this.region);
                return
            end
            if (ischar(this.region))
                g = sprintf('_%s', this.region);
                return
            end
            error('mlraichle:unsupportedParamTypeclass', ...
                'SessionData.get.regionTag');
        end
        function g = get.studyCensus(this) 
            g = this.studyCensus_;
        end
        function g = get.supEpoch(this)
            if (~isempty(this.supEpoch_))
                g = this.supEpoch_;
                return
            end
            g = ceil(length(this.taus) / this.maxLengthEpoch);
        end
        function this = set.supEpoch(this, s) %#ok<MCHV2>
            assert(isnumeric(s));
            this.supEpoch_ = s;
        end
        function g = get.vfolder(this)
            g = sprintf('V%i', this.vnumber);
        end  
        function g = get.t4ResolveBuilderBlurArg(this)
            g = this.tracerBlurArg;
        end
        function g = get.tauIndices(this)
            pris = mlfourd.ImagingContext2(this.tracerPristine('typ','fqfn'));
            g = [];
            if (lexist_4dfp(pris.fqfileprefix))
                sz = mlfourdfp.FourdfpVisitor.size_4dfp(pris);
                g  = 1:sz(4);                
                if (length(g) > 73) %% KLUDGE
                    g = 1:73;
                end                
            end
        end
        function g = get.taus(this)
            if (~this.attenuationCorrected)
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60];
                        % length -> 65 <- 30*10 + 55*60
                    case {'OC' 'CO'}
                        g = [30,30,30,30,30,30,30,30,30,30,30,30,30,30];
                        % length -> 14
                    case 'OO'
                        g = [30,30,30,30,30,30,30,30,30,30];
                        % length -> 10
                    case 'HO'
                        g = [30,30,30,30,30,30,30,30,30,30];
                        % length -> 10
                    otherwise
                        error('mlraichle:unsupportedSwitchcase', 'NAC:SessionData.taus.this.tracer->%s', this.tracer);
                end
            else            
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [10,10,10,10,10,10,10,10,10,10,10,10,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60];
                        % length -> 73 <- 12*10 + 6*30 + 55*60
                    case {'OC' 'CO'}
                        g = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
                        % length -> 70 <- 40*3 + 30*10
                    case 'OO'
                        g = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
                        % length -> 58 <- 40*3 + 18*10
                    case 'HO'
                        g = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
                        % length -> 58
                    otherwise
                        error('mlraichle:unsupportedSwitchcase', 'AC:SessionData.taus.this.tracer->%s', this.tracer);
                end
            end
            ti = this.tauIndices;
            if (~isempty(ti))
                g = g(ti);
            end
            if (this.tauMultiplier > 1)
                g = this.multiplyTau(g);
            end
        end        
        function g = get.times(this)
            t = this.taus;
            g = zeros(size(t));
            for ig = 1:length(t)-1
                g(ig+1) = sum(t(1:ig));
            end
        end
        
        function g = get.lmTag(this)
            if (~this.attenuationCorrected)
                g = 'createDynamicNAC';
                return
            end
            g = 'createDynamic2Carney';
        end
        
        %% IMRData
        
        function obj  = adc(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_ADC', varargin{:});
        end
        function obj  = aparcA2009sAsegBinarized(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('aparcA2009sAseg_%s_binarized%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = aparcAsegBinarized(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('aparcAseg_%s_binarized%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = atlas(this, varargin)
            ip = inputParser;
            addParameter(ip, 'desc', 'TRIO_Y_NDC', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'mlfourd.ImagingContext2', @ischar);
            parse(ip, varargin{:});
            
            obj = imagingType(ip.Results.typ, ...
                fullfile(getenv('REFDIR'), ...
                         sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt)));
        end
        function obj  = brainmaskBinarized(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('brainmask_%s_binarized%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = brainmaskBinarizeBlended(this, varargin)
            fn   = sprintf('brainmask_%s_binarizeBlended%s', this.resolveTag, this.filetypeExt);
            fqfn = fullfile(this.vLocation, fn);
            if (~lexist(fqfn, 'file'))
                fqfn = fullfile(this.tracerLocation, fn);
            end
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = dwi(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_TRACEW', varargin{:});
        end
        function loc  = freesurferLocation(this, varargin)
            loc = this.vLocation(varargin{:});
        end  
        function obj  = mpr(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = mprForReconall(this, varargin)
            obj = this.fqfilenameObject( ...
                fullfile(this.vLocation, ['mpr' this.filetypeExt]), varargin{:});            
        end
        function obj  = mprage(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = perf(this, varargin)
            obj = this.mrObject('ep2d_perf', varargin{:});
        end
        function obj  = studyAtlas(this, varargin)
            ip = inputParser;
            addParameter(ip, 'desc', 'HYGLY_atlas', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'mlfourd.ImagingContext2', @ischar);
            parse(ip, varargin{:});
            
            obj = imagingType(ip.Results.typ, ...
                fullfile(this.subjectsDir, 'atlasTest', 'source', ...
                         sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt)));
        end
        function obj  = T1(this, varargin)
            obj = this.T1001(varargin{:});
        end
        function obj  = T1001(this, varargin)
            fqfn = fullfile(this.vLocation, ['T1001' this.filetypeExt]);
            if (~lexist(fqfn, 'file') && isdir(this.freesurferLocation))
                mic = T1001@mlpipeline.SessionData(this, 'typ', 'mlfourd.ImagingContext2');
                mic.nifti;
                mic.saveas(fqfn);
            end
            obj = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = T1001BinarizeBlended(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('T1001_%s_binarizeBlendedd%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = t1(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = tof(this, varargin)
            try
                obj = this.mrObject('tof', varargin{:});
            catch ME
                dispwarning(ME);
                obj = [];
            end
        end
        function obj  = toffov(this, varargin)
            obj = this.mrObject('AIFFOV%s%s', varargin{:});
        end
                
        %% IPETData
        
        function obj  = adhocTimings(this, varargin)
            %% ADHOCTIMINGS 
            %  @deprecated
            
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.subjectsDir, ...
                sprintf('%s-%s-timings.txt', ipr.tracer, this.attenuationTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = arterialSamplerCalCrv(this, varargin)
            [pth,fp] = this.arterialSamplerCrv(varargin{:});
            fqfn = fullfile(pth, [fp '_cal.crv']);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = arterialSamplerCrv(this, varargin)
            fqfn = fullfile( ...
                this.vLocation('typ', 'path'), ...
                sprintf('%s_V%i.crv', this.sessionFolder, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = CCIRRadMeasurements(this)
            obj = mldata.CCIRRadMeasurements.date2filename(this.datetime);
        end
        function obj  = ctRescaled(this, varargin)
            fqfn = fullfile( ...
                this.vLocation('typ', 'path'), ...
                sprintf('ctRescaledv%i%s', this.vnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = petfov(this, varargin)
            obj = this.mrObject('AIFFOV%s%s', varargin{:});
        end
        function loc  = petLocation(this, varargin)
            if (lstrfind(upper(this.tracer), 'FDG'))
                loc = fullfile(this.vLocation(varargin{:}), ...
                               sprintf('%s_V%i-%s', upper(this.tracer), this.vnumber, this.attenuationTag), '');
            else
                loc = fullfile(this.vLocation(varargin{:}), ...
                               sprintf('%s%i_V%i-%s', upper(this.tracer), this.snumber, this.vnumber, this.attenuationTag), '');
            end
        end
        function p    = petPointSpread(~, varargin)
            inst = mlsiemens.MMRRegistry.instance;
            p    = inst.petPointSpread(varargin{:});
        end
        function suff = petPointSpreadSuffix(this, varargin)
            suff = sprintf('_b%i', floor(10*mean(this.petPointSpread(varargin{:}))));
        end
        function [dt0_,date_] = readDatetime0(this)
            try
                frame0 = this.frame;
                this.frame = nan;
                dcm = this.tracerListmodeDcm;
                this.frame = frame0;
                lp = mlio.LogParser.load(dcm);
                [dateStr,idx] = lp.findNextCell('%study date (yyyy:mm:dd):=', 1);
                 timeStr      = lp.findNextCell('%study time (hh:mm:ss GMT+00:00):=', idx);
                dateNames     = regexp(dateStr, '%study date \(yyyy\:mm\:dd\)\:=(?<Y>\d\d\d\d)\:(?<M>\d+)\:(?<D>\d+)', 'names');
                timeNames     = regexp(timeStr, '%study time \(hh\:mm\:ss GMT\+00\:00\)\:=(?<H>\d+)\:(?<MI>\d+)\:(?<S>\d+)', 'names');
                Y  = str2double(dateNames.Y);
                M  = str2double(dateNames.M);
                D  = str2double(dateNames.D);
                H  = str2double(timeNames.H);
                MI = str2double(timeNames.MI);
                S  = str2double(timeNames.S);

                dt0_ = datetime(Y,M,D,H,MI,S,'TimeZone','Etc/GMT');
                dt0_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
                date_ = datetime(Y,M,D);
            catch ME 
                dispwarning(ME, 'mlraichle:RuntimeWarning', ...
                    'SessionData.readDatetime0');
                [dt0_,date_] = readDatetime0@mlpipeline.SessionData(this);
            end
        end
        function obj  = t1MprageSagSeriesForReconall(this, varargin)
            obj = this.studyCensus_.t1MprageSagSeriesForReconall(this, varargin{:});  
        end
        function loc  = tracerConvertedLocation(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.convertedTag), ''));
        end
        function loc  = tracerLocation(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.vLocation);
                return
            end
            loc = locationType(ipr.typ, ...
                  fullfile(this.vLocation, ...
                           sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.attenuationTag), ...
                           capitalize(this.epochTag), ...
                           ''));
        end
        function loc  = tracerRawdataLocation(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.vLocation);
                return
            end
            loc = locationType(ipr.typ, ...
                  fullfile(this.vLocation, ...
                           sprintf('%s%s_V%i', ipr.tracer, schar, this.vnumber), ''));
        end
        function loc  = tracerListmodeLocation(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.convertedTag), ...
                         sprintf('%s%s_V%i-LM-00', ipr.tracer, schar, this.vnumber), ''));
        end
        function obj  = tracerListmodeDcm(this, varargin)
            dt   = mlsystem.DirTool(fullfile(this.tracerConvertedLocation, 'LM', '*.dcm'));
            assert(1 == length(dt.fqfns));
            fqfn = dt.fqfns{1};            
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeMhdr(this, varargin)
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP.mhdr', ipr.tracer, schar, this.vnumber));
            if (~lexist(fqfn, 'file'))
                fqfn = fullfile( ...
                    this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                    sprintf('%s%s_V%i-LM-00-FBP.mhdr', ipr.tracer, schar, this.vnumber));
            end
            if (~lexist(fqfn, 'file'))                
                fqfn = fullfile( ...
                    this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                    sprintf('%s%s_V%i-LM-00-OP-%s.mhdr', ipr.tracer, schar, this.vnumber, this.attenuationTag));
            end
            assert(lexist(fqfn, 'file'), 'mlraichle.SessionData.tracerListmodMhdr.fqfn->%s NOT FOUND', fqfn);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeSif(this, varargin)
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP%s', ...
                    ipr.tracer, schar, this.vnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeUmap(this, varargin)
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-umap.v', ipr.tracer, schar, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeFrameV(this, varargin)
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP_%03i_000.v', ipr.tracer, schar, this.vnumber, ipr.frame));
            if (~lexist(fqfn, 'file'))                
                fqfn = fullfile( ...
                    this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                    sprintf('%s%s_V%i-LM-00-OP-%s_%03i_000.v', ipr.tracer, schar, this.vnumber, this.attenuationTag, ipr.frame));
            end
            assert(lexist(fqfn, 'file'));
            obj  = this.fqfilenameObject(fqfn, varargin{:}, 'frame', nan);
        end
        function obj  = tracerSif(this, varargin)
            
            [ipr,schar] = this.iprLocation(varargin{:});
            ipr.ac = false;
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP%s', ...
                    ipr.tracer, schar, this.vnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:}, 'frame', this.frame);
        end    
        function obj  = tracerPristine(this, varargin)
            this.epoch = [];
            this.rnumber = 1;
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%ir1%s', lower(ipr.tracer), schar, this.vnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolved(this, varargin)
            fqfn = fullfile( ...
                this.vLocation, ...
                sprintf('%s_%s%s', this.tracerRevision('typ', 'fp'), this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end        
        function obj  = tracerResolvedFinal(this, varargin)
            if (this.attenuationCorrected)
                switch (this.tracer) % KLUDGE
                    case 'FDG'                         
                        rEpoch = 1:this.supEpoch; % KLUDGE within KLUDGE
                        rFrame = this.supEpoch;
                    case 'OC'
                        rEpoch = 1:3;
                        rFrame = 3;
                    case {'HO' 'OO'}
                        rEpoch = 1:3;
                        rFrame = 3;
                    otherwise
                        error('mlraichle:unsupportedSwitchCase', ...
                              'SessionData.tracerResolvedFinal.this.tracer->%s', this.tracer);
                end
            else
                switch (this.tracer) % KLUDGE
                    case 'FDG' 
                        if (strcmp(this.sessionFolder, 'HYGLY25'))
                            rEpoch = 1:this.supEpoch; % KLUDGE within KLUDGE
                            rFrame = this.supEpoch;
                        else
                            rEpoch = 1:9;
                            rFrame = 9;
                        end
                    case {'HO' 'OO' 'OC'}
                        rEpoch = 1:2;
                        rFrame = 2;
                    otherwise
                        error('mlraichle:unsupportedSwitchCase', ...
                              'SessionData.tracerResolvedFinal.this.tracer->%s', this.tracer);
                end                
            end
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'resolvedEpoch', rEpoch, @isnumeric); 
            addParameter(ip, 'resolvedFrame', rFrame, @isnumeric); 
            parse(ip, varargin{:});
            
            % this.rnumber = 2; % POSSIBLE BUG
            sessd1 = this;
            sessd1.rnumber = 1;
            if (this.attenuationCorrected)
                sessd1.epoch = ip.Results.resolvedEpoch;
                fqfn = sprintf('%s_%s%s', ...
                    this.tracerRevision('typ', 'fqfp'), ...
                    sessd1.resolveTagFrame(ip.Results.resolvedFrame), this.filetypeExt);
                obj  = this.fqfilenameObject(fqfn, varargin{:});
            else
                this.epoch = ip.Results.resolvedEpoch;
                sessd1.epoch = ip.Results.resolvedEpoch;
                fqfn = sprintf('%s_%s%s', ...
                    this.tracerRevision('typ', 'fqfp'), ...
                    sessd1.resolveTagFrame(ip.Results.resolvedFrame), this.filetypeExt);
                obj  = this.fqfilenameObject(fqfn, varargin{:});
            end
        end
        function obj  = tracerResolvedFinalOnAtl(this, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_on_%s_%i%s', this.tracerResolvedFinal('typ', 'fp'), this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalOpFdg(this, varargin)
            if (strcmpi(this.tracer, 'FDG'))
                obj = this.tracerResolvedFinal(varargin{:});
                return
            end
            %this.rnumber = 2;
            fqfn = fullfile(this.vLocation, ...
                sprintf('%sr2_op_%s%s', this.tracerResolvedFinal('typ', 'fp'), this.fdgACRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerResolvedFinal('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalSumtOpFdg(this, varargin)
            fn = this.tracerResolvedFinalSumt('typ', 'fn');
            if (~strcmpi(this.tracer, 'FDG'))
                fn = sprintf('%sr2_op_%s', this.tracerResolvedFinalSumt('typ', 'fp'), this.fdgACRevision('typ', 'fn')); 
            end
            obj  = this.fqfilenameObject(fullfile(this.vLocation, fn), varargin{:});
        end
        function obj  = tracerResolvedSubj(this, varargin)
            %% TRACERRESOLVEDSUBJ is designed for use with mlraichle.SubjectImages.
            %  @param named name; e.g., 'cbfv1r2'.
            %  @param named vnumber.
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
        function obj  = tracerResolvedSumt(this, varargin)
            fqfn = sprintf('%s_%s_sumt%s', this.tracerRevision('typ', 'fqfp'), this.resolveTag, this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevision(this, varargin)
            %  @param named rLabel is char and overrides any specifications of r-number;
            %  it may be useful for generating filenames such as '*r1r2_to_resolveTag_t4'.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'rLabel', sprintf('r%i', this.rnumber), @ischar);
            parse(ip, varargin{:});
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%i%s%s%s%s', ...
                lower(ipr.tracer), schar, this.vnumber, this.epochTag, ip.Results.rLabel, this.regionTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevisionSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerRevision('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerScrubbed(this, varargin)
            fqfn = sprintf('%s_scrubbed%s', this.tracerResolved('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end        
        function obj  = tracerSuvr(this, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_suvr_%i%s', this.tracerRevision('typ', 'fp'), this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSuvrAveraged(this, varargin)   
            ipr = this.iprLocation(varargin{:});         
            fqfn = fullfile(this.vLocation, ...
                sprintf('%sav%i%sr%i_suvr_%i%s', ...
                lower(ipr.tracer), this.vnumber, this.epochTag, ipr.rnumber, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSuvrNamed(this, name, varargin)
            schar = '';
            if (strcmpi(this.tracer, 'OC') || ...
                strcmpi(this.tracer, 'CO') || ...
                strcmpi(this.tracer, 'OO') || ...
                strcmpi(this.tracer, 'HO'))
                schar = 'a'; % sprintf('%i', this.snumber);
            end
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s%sv%ir%i_suvr_%i%s', lower(name), schar, this.vnumber, this.rnumber, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerTimeWindowed(this, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_timeWindowed%s', this.tracerRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerTimeWindowedOnAtl(this, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_timeWindowed_%i%s', this.tracerRevision('typ', 'fp'), this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerVisit(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                [sprintf('%s%sv%i%s', lower(ipr.tracer), schar, this.vnumber) this.filetypeExt]);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerT4Location(this, varargin)
            
            [ipr,schar] = this.iprLocation(varargin{:});
            if (lstrfind(ipr.tracer, 'FDG'))
                loc = locationType(ipr.typ, ...
                    fullfile(this.vLocation, ...
                             sprintf('%s_V%i-%s', ipr.tracer, this.vnumber, this.attenuationTag), 'T4', ''));
                return
            end
            if (lstrfind(ipr.tracer, 'HO') || lstrfind(ipr.tracer, 'OO'))
                ipr.tracer = 'OO';
            end            
            if (isdir(fullfile(this.vLocation, sprintf('OO1_V%i-%s', this.vnumber, this.attenuationTag))))
                schar = '1';
            end
            if (isdir(fullfile(this.vLocation, sprintf('OO2_V%i-%s', this.vnumber, this.attenuationTag))))
                schar = '2';
            end
            loc = locationType(ipr.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.attenuationTag), 'T4', ''));
        end
        function obj  = umapTagged(this, varargin)
            %% legacy support
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            
            if (isempty(ip.Results.tag))
                fn = 'umapSynth';
            else 
                fn = sprintf('umapSynth_%s%s', ip.Results.tag, this.filetypeExt);
            end
            fqfn = fullfile(this.tracerRevision('typ','filepath'), fn);
            obj  = this.fqfilenameObject(fqfn, varargin{2:end});
        end 
        function obj  = umapSynth(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', this.tracer, @ischar);
            addParameter(ip, 'blurTag', mlpet.Resources.instance.suffixBlurPointSpread, @ischar);
            parse(ip, varargin{:});
            this.tracer = ip.Results.tracer;
            
            if (isempty(this.tracer))
                fqfn = fullfile(this.vLocation('typ', 'path'), ['umapSynth_op_T1001' ip.Results.blurTag this.filetypeExt]);
                obj  = this.fqfilenameObject(fqfn, varargin{:});
                return
            end
            fqfn = fullfile( ...
                this.tracerLocation('typ', 'path'), ...
                sprintf('umapSynth_op_%s%s', ...
                    this.tracerRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end    
        function obj  = umapSynthOpT1001(this, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('umapSynth_op_%s%s.4dfp.hdr', ...
                        this.T1001('typ', 'fp'), mlpet.Resources.instance.suffixBlurPointSpread));
            obj  = this.fqfilenameObject(fqfn, varargin{2:end});
        end    
        
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
        
        %% mlnipet.ISessionData
        
        function obj  = tracerNipet(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'nativeFov', false, @islogical);
            parse(ip, varargin{:});
            
            this.epoch = [];
            this.rnumber = 1;
            [ipr,schar] = this.iprLocation(varargin{:});
            if (ip.Results.nativeFov)
                tr = upper(ipr.tracer);
            else
                tr = lower(ipr.tracer);
            end
            fqfn = fullfile( ...
                this.tracerConvertedLocation('tracer', ipr.tracer, 'snumber', ipr.snumber), ...
                'output', 'PET', ...
                sprintf('%s%sv%i.nii.gz', tr, schar, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerOutputLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.tracerConvertedLocation(varargin{:}), this.outfolder, ''));
        end
        function loc  = tracerOutputPetLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.tracerConvertedLocation(varargin{:}), this.outfolder, 'PET', ''));
        end
        function loc  = tracerOutputSingleFrameLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.tracerOutputPetLocation(varargin{:}), 'single-frame', ''));
        end
        
        %%  
         
        function loc  = vallLocation(this, varargin)
            %  @override
            
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionPath, 'Vall'));
        end       
        function obj  = fqfilenameObject(this, varargin)
            %  @override
            %  @param named typ has default 'fqfn'
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'fqfn', @ischar);
            addParameter(ip, 'frame', nan, @isnumeric);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'fqfn', @ischar);
            parse(ip, varargin{:});
            this.frame = ip.Results.frame;
            
            [pth,fp,ext] = myfileparts(ip.Results.fqfn);
            fqfn = fullfile(pth, [fp ip.Results.tag this.frameTag ext]);
            obj = imagingType(ip.Results.typ, fqfn);
        end
        function obj  = mrObject(this, varargin)
            %  @override
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'orientation', '', @(x) lstrcmp({'sagittal' 'transverse' 'coronal' ''}, x));
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.fourdfpLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt));
            this.ensureMRFqfilename(fqfn);
            fqfn = this.ensureOrientation(fqfn, ip.Results.orientation);
            obj  = imagingType(ip.Results.typ, fqfn);
        end 
        function obj  = petObject(this, varargin)
            %  @override 
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'tracer', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            suff = ip.Results.tag;
            if (~isempty(suff) && ~strcmp(suff(1),'_'))
                suff = ['_' suff];
            end
            
            if (lstrfind(lower(ip.Results.tracer), 'fdg'))
                fqfn = fullfile(this.petLocation, ...
                       sprintf('%sv%ir%i%s%s', ip.Results.tracer, this.vnumber, this.rnumber, suff, this.filetypeExt));
            else
                fqfn = fullfile(this.petLocation, ...
                       sprintf('%s%iv%ir%i%s%s', ip.Results.tracer, this.snumber, this.vnumber, this.rnumber, suff, this.filetypeExt));
            end
            this.ensurePETFqfilename(fqfn);
            obj = imagingType(ip.Results.typ, fqfn);
        end         
        function loc  = vLocation(this, varargin)
            %  @override
            
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionPath, sprintf('V%i', this.vnumber), ''));
        end        
        
 		function this = SessionData(varargin)
 			this = this@mlpipeline.ResolvingSessionData(varargin{:});
            
            setenv('CCIR_RAD_MEASUREMENTS_DIR', fullfile(getenv('HOME'), 'Documents', 'private', ''));
            this.studyCensus_ = mlraichle.StudyCensus(this.STUDY_CENSUS_XLSX, 'sessionData', this);
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        studyCensus_
        supEpoch_
    end
    
    methods (Access = protected)
        function fqfn = ensureOrientation(this, fqfn, orient)
            assert(lstrcmp({'sagittal' 'transverse' 'coronal' ''}, orient)); 
            [pth,fp,ext] = myfileparts(fqfn);
            fqfp = fullfile(pth, fp);   
            orient0 = this.readOrientation(fqfp);
            fv = mlfourdfp.FourdfpVisitor;             
            
            if (isempty(orient))
                return
            end     
            if (strcmp(orient0, orient))
                return
            end       
            if (lexist([this.orientedFileprefix(fqfp, orient) ext]))
                fqfn = [this.orientedFileprefix(fqfp, orient) ext];
                return
            end
                       
            pwd0 = pushd(pth);
            switch (orient0)
                case 'sagittal'
                    switch (orient)
                        case 'transverse'
                            fv.S2T_4dfp(fp, [fp 'T']);
                            fqfn = [fqfp 'T' ext];
                        case 'coronal'
                            fv.S2C_4dfp(fp, [fp 'C']);
                            fqfn = [fqfp 'C' ext];
                    end
                case 'transverse'
                    switch (orient)
                        case 'sagittal'
                            fv.T2S_4dfp(fp, [fp 'S']);
                            fqfn = [fqfp 'S' ext];
                        case 'coronal'
                            fv.T2C_4dfp(fp, [fp 'C']);
                            fqfn = [fqfp 'C' ext];
                    end
                case 'coronal'
                    switch (orient)
                        case 'sagittal'
                            fv.C2S_4dfp(fp, [fp 'S']);
                            fqfn = [fqfp 'S' ext];
                        case 'transverse'
                            fv.C2T_4dfp(fp, [fp 'T']);
                            fqfn = [fqfp 'T' ext];
                    end
            end
            popd(pwd0);
        end
        function        ensureMRFqfilename(this, fqfn)
            if (~this.ensureFqfilename)
                return
            end
            if (~lexist(fqfn, 'file'))
                try
                    import mlfourdfp.*;
                    srcPath = DicomSorter.findRawdataSession(this);
                    destPath = this.fourdfpLocation;
                    ds = DicomSorter.create('sessionData', this);
                    ds.sessionDcmConvert( ...
                        srcPath, destPath, ...
                        'studyData', this.studyData_, 'seriesFilter', mybasename(fqfn), 'preferredName', mybasename(fqfn));
                catch ME
                    handexcept(ME, 'mlraichle:TypeError', ...
                        'SessionData.ensureMRFqfilename:  possible defect in operations of mlfourdfp.DicomSorter');
                end
            end
        end
        function        ensurePETFqfilename(this, fqfn) %#ok<INUSD>
            if (~this.ensureFqfilename)
                return
            end
            %assert(lexist(fqfn, 'file'));
        end
        function        ensureUmapFqfilename(this, fqfn) %#ok<INUSD>
            if (~this.ensureFqfilename)
                return
            end
            %assert(lexist(fqfn, 'file'));
        end   
        function tau1 = multiplyTau(this, tau)
            %% MULTIPLYTAU increases tau durations by scalar this.tauMultiplier, decreasing the sampling rate,
            %  decreasing the number of frames for dynamic data and
            %  potentially increasing SNR.
            
            N1   = ceil(length(tau)/this.tauMultiplier);
            tau1 = zeros(1, N1);
            
            ti = 1;
            a  = 1;
            b  = this.tauMultiplier;
            while (ti <= N1)
                
                tau1(ti) = sum(tau(a:b));
                
                ti =     ti + 1;
                a  = min(a  + this.tauMultiplier, length(tau));
                b  = min(b  + this.tauMultiplier, length(tau));
                if (a > length(tau) || b > length(tau)); break; end
            end
        end
        function fqfp = orientedFileprefix(~, fqfp, orient)
            assert(mlfourdfp.FourdfpVisitor.lexist_4dfp(fqfp));
            switch (orient)
                case 'sagittal'
                    fqfp = [fqfp 'S'];
                case 'transverse'
                    fqfp = [fqfp 'T'];
                case 'coronal'
                    fqfp = [fqfp 'C'];
                otherwise
                    error('mlraichle:switchCaseNotSupported', ...
                          'SesssionData.orientedFileprefix.orient -> %s', orient);
            end
        end
        function o    = readOrientation(this, varargin)
            ip = inputParser;
            addRequired(ip, 'fqfp', @mlfourdfp.FourdfpVisitor.lexist_4dfp);
            parse(ip, varargin{:});
            
            [~,o] = mlbash(sprintf('awk ''/orientation/{print $NF}'' %s%s', ip.Results.fqfp, this.filetypeExt));
            switch (strtrim(o))
                case '2'
                    o = 'transverse';
                case '3'
                    o = 'coronal';
                case '4'
                    o = 'sagittal';
                otherwise
                    error('mlraichle:switchCaseNotSupported', ...
                          'SessionData.readOrientation.o -> %s', o);
            end
        end    
        function obj  = visitMapOnAtl(this, map, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_on_%s_%i%s', map, this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end     
        function obj  = visitMapOpFdg(this, map, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_op_%s%s', map, this.fdgACRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
    end
    
    %% HIDDEN
    %  @deprecated  Used in early development.  Use less-specialized corresponding methods from above.
    
    properties (Hidden)
        bloodGlucoseAndHct
        bloodGlucoseAndHctXlsx = 'BG_and_Hct_for_metabolism_processing.xlsx'
        selectedMask
    end
    
    methods (Hidden)
        function obj  = fdgAC(this, varargin)
            obj = this.tracerAC('tracer', 'FDG', varargin{:});
        end
        function loc  = fdgACLocation(this, varargin)
            loc = this.tracerLocation('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgACResolved(this, varargin)
            obj = this.tracerACResolved('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgACRevision(this, varargin)
            obj = this.tracerACRevision('tracer', 'FDG', varargin{:});
        end
        function loc  = fdgListmodeLocation(this, varargin)
            loc = this.tracerListmodeLocation('tracer', 'FDG', varargin{:});
        end        
        function obj  = fdgListmodeSif(this, varargin)
            obj = this.tracerListmodeSif('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgListmodeFrameV(this, frame, varargin)
            assert(isnumeric(frame));
            obj = this.tracerListmodeFrameV('tracer', 'FDG', 'frame', frame, varargin{:});
        end
        function obj  = fdgNAC(this, varargin)
            obj = this.tracerNAC('tracer', 'FDG', varargin{:});
        end
        function loc  = fdgNACLocation(this, varargin)
            loc = this.tracerNACLocation('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgNACResolved(this, varargin)
            obj = this.tracerNACResolved('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgNACRevision(this, varargin)
            obj = this.tracerNACRevision('tracer', 'FDG', varargin{:});
        end
        function loc  = fdgACT4Location(this, varargin)
            loc = this.tracerACT4Location('tracer', 'FDG', varargin{:});
        end
        function loc  = fdgNACT4Location(this, varargin)
            loc = this.tracerNACT4Location('tracer', 'FDG', varargin{:});
        end
        function loc  = fdgT4Location(this, varargin)
            loc = this.tracerT4Location('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgListmodeUmap(this, varargin)
            obj = this.tracerListmodeUmap('tracer', 'FDG', varargin{:});
        end
        function h    = hct(this)
            h = this.bloodGlucoseAndHct.Hct(this.sessionFolder, this.vnumber);
        end
        function obj  = mask(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            assert(lexist(this.selectedMask, 'file'));
            obj = this.fqfilenameObject(this.selectedMask, varargin{:});
        end
        function b    = petBlur(~)
            b = mlsiemens.MMRRegistry.instance.petPointSpread;
        end
        function glc  = plasmaGlucose(this)
            glc = this.bloodGlucoseAndHct.plasmaGlucose(this.sessionFolder, this.vnumber);
        end
        function obj  = tracerAC(this, varargin)
            this.attenuationCorrected = true;
            obj = this.tracerSif(varargin{:});
        end
        function loc  = tracerACLocation(this, varargin)
            this.attenuationCorrected = true;
            loc = this.tracerLocation(varargin{:});
        end
        function obj  = tracerACResolved(this, varargin)
            this.attenuationCorrected = true;
            obj = this.tracerResolved(varargin{:});
        end
        function obj  = tracerACRevision(this, varargin)
            this.attenuationCorrected = true;
            obj = this.tracerRevision(varargin{:});
        end
        function loc  = tracerACT4Location(this, varargin)
            this.attenuationCorrected = true;
            loc = this.tracerT4Location(varargin{:});
        end
        function obj  = tracerNAC(this, varargin)
            this.attenuationCorrected = false;
            obj = this.tracerSif(varargin{:});
        end
        function loc  = tracerNACLocation(this, varargin)
            this.attenuationCorrected = false;
            loc = this.tracerLocation(varargin{:});
        end
        function obj  = tracerNACResolved(this, varargin)
            this.attenuationCorrected = false;
            obj = this.tracerResolved(varargin{:});
        end
        function obj  = tracerNACRevision(this, varargin)
            this.attenuationCorrected = false;
            obj = this.tracerRevision(varargin{:});
        end
        function loc  = tracerNACT4Location(this, varargin)
            this.attenuationCorrected = false;
            loc = this.tracerT4Location(varargin{:});
        end    
        function obj  = tracerResolved1(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%ir%i_on_resolved%s', ...
                    lower(ipr.tracer), schar, this.vnumber, ipr.rnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedSumt1(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%ir%i_on_resolved_sumt%s', ...
                    lower(ipr.tracer), schar, this.vnumber, ipr.rnumber, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end    
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

