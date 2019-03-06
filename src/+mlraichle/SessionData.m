classdef SessionData < mlpipeline.ResolvingSessionData & mlnipet.ISessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
    
    properties
        ensureFqfilename = false
        fractionalImageFrameThresh = 0.01 % of median
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
        resources
        assessors
        
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
            assert(isfield(sessObj, 'sessionDate'));
            assert(isfield(sessObj, 'parcellation'));
            studyd = StudyData;
            sessp = fullfile(studyd.subjectsDir, sessObj.sessionFolder, '');
            sessd = SessionData('studyData', studyd, 'sessionPath', sessp, ...
                                'tracer', 'FDG', 'ac', true, 'sessionDate', sessObj.sessionDate);  
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
        function g = get.resources(this)
             g = [];
        end
        function g = get.assessors(this)
             g = [];
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
        function g = get.supEpoch(this)
            if (~isempty(this.supEpoch_))
                g = this.supEpoch_;
                return
            end
            g = ceil(length(this.taus) / this.maxLengthEpoch);
        end
        function this = set.supEpoch(this, s) 
            assert(isnumeric(s));
            this.supEpoch_ = s;
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
            if (lexist(this.listmodeJson, 'file'))
                j = jsondecode(fileread(this.listmodeJson));
                g = j.taus';
                return
            elseif (~this.attenuationCorrected)
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60];
                        % length -> 65 <- 30*10 + 55*60
                    case {'OC' 'CO'}
                        g = [30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30];
                        % length -> 14
                    case 'OO'
                        g = [30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30];
                        % length -> 10
                    case 'HO'
                        g = [30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30];
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
                        g = [3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,12,13,13,15,16,17,19,21,24,27,32,38,47,62,88] ;
                        % g = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
                        % length -> 70 <- 40*3 + 30*10
                    case 'OO'
                        g = [3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,12,13,13,15,16,17,19,21,24,27,32,38,47,62,88];
                        % g = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
                        % length -> 58 <- 40*3 + 18*10
                    case 'HO'
                        g = [3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,12,13,13,15,16,17,19,21,24,27,32,38,47,62,88];
                        % g = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
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
        
        function f = listmodeJson(this)
            dt = mlsystem.DirTool(fullfile(this.tracerOutputPetLocation, [upper(this.tracer) 'dt*.json']));
            assert(1 == dt.length);
            f = dt.fqfns{1};
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
            fqfn = fullfile(this.sessionPath, fn);
            if (~lexist(fqfn, 'file'))
                fqfn = fullfile(this.tracerLocation, fn);
            end
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = dwi(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_TRACEW', varargin{:});
        end
        function loc  = freesurferLocation(this, varargin)
            loc = this.sessionLocation(varargin{:});
        end  
        function obj  = mpr(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = mprForReconall(this, varargin)
            obj = this.fqfilenameObject( ...
                fullfile(this.sessionPath, ['mpr' this.filetypeExt]), varargin{:});            
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
            fqfn = fullfile(this.sessionPath, ['T1001' this.filetypeExt]);
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
                this.sessionLocation('typ', 'path'), ...
                sprintf('%s.crv', this.sessionFolder));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = CCIRRadMeasurements(this)
            obj = mldata.CCIRRadMeasurements.date2filename(this.datetime);
        end
        function obj  = ctRescaled(this, varargin)
            fqfn = fullfile( ...
                this.sessionLocation('typ', 'path'), ...
                sprintf('ctRescaled%s', this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = petfov(this, varargin)
            obj = this.mrObject('AIFFOV%s%s', varargin{:});
        end
        function loc  = petLocation(this, varargin)
            loc = fullfile(this.sessionLocation(varargin{:}), ...
                sprintf('%s-%s', upper(this.tracer), this.attenuationTag), '');
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
        function loc  = tracerConvertedLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.sessionPath, ...
                         sprintf('%s-%s', ipr.tracer, this.convertedTag), ''));
        end
        function loc  = tracerLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.sessionPath);
                return
            end
            loc = locationType(ipr.typ, ...
                  fullfile(this.sessionPath, ...
                           sprintf('%s-%s', ipr.tracer, this.attenuationTag), ...
                           capitalize(this.epochTag), ...
                           ''));
        end
        function loc  = tracerRawdataLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.rawdataPath);
                return
            end
            loc = this.tracerConvertedLocation(varargin{:});
        end
        function loc  = tracerListmodeLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.sessionPath, ...
                         sprintf('%s-%s', ipr.tracer,  this.convertedTag), ...
                         sprintf('%s-LM-00', ipr.tracer), ''));
        end
        function obj  = tracerListmodeDcm(this, varargin)
            dt   = mlsystem.DirTool(fullfile(this.tracerConvertedLocation, 'LM', '*.dcm'));
            assert(1 == length(dt.fqfns));
            fqfn = dt.fqfns{1};            
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerPristine(this, varargin)
            this.epoch = [];
            this.rnumber = 1;
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%sr1%s', lower(ipr.tracer), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolved(this, varargin)
            fqfn = fullfile( ...
                this.sessionPath, ...
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
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_on_%s_%i%s', this.tracerResolvedFinal('typ', 'fp'), this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalOpFdg(this, varargin)
            if (strcmpi(this.tracer, 'FDG'))
                obj = this.tracerResolvedFinal(varargin{:});
                return
            end
            %this.rnumber = 2;
            fqfn = fullfile(this.sessionPath, ...
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
            obj  = this.fqfilenameObject(fullfile(this.sessionPath, fn), varargin{:});
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
            
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s%s%s%s', ...
                lower(ipr.tracer), this.epochTag, ip.Results.rLabel, this.regionTag, this.filetypeExt));
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
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_suvr_%i%s', this.tracerRevision('typ', 'fp'), this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSuvrAveraged(this, varargin)   
            ipr = this.iprLocation(varargin{:});         
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%sa%sr%i_suvr_%i%s', ...
                lower(ipr.tracer), this.epochTag, ipr.rnumber, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSuvrNamed(this, name, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%sr%i_suvr_%i%s', lower(name), this.rnumber, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerTimeWindowed(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_timeWindowed%s', this.tracerRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerTimeWindowedOnAtl(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_timeWindowed_%i%s', this.tracerRevision('typ', 'fp'), this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
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
                fqfn = fullfile(this.sessionLocation('typ', 'path'), ['umapSynth_op_T1001' ip.Results.blurTag this.filetypeExt]);
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
            fqfn = fullfile(this.sessionPath, ...
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
            ipr = this.iprLocation(varargin{:});
            if (ip.Results.nativeFov)
                tr = upper(ipr.tracer);
            else
                tr = lower(ipr.tracer);
            end
            fqfn = fullfile( ...
                this.tracerConvertedLocation('tracer', ipr.tracer, 'snumber', ipr.snumber), ...
                'output', 'PET', ...
                sprintf('%s.nii.gz', tr));
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
            fqfn = fullfile(this.petLocation, ...
                   sprintf('%sr%i%s%s', ip.Results.tracer, this.rnumber, suff, this.filetypeExt));
            this.ensurePETFqfilename(fqfn);
            obj = imagingType(ip.Results.typ, fqfn);
        end       
        
 		function this = SessionData(varargin)
 			this = this@mlpipeline.ResolvingSessionData(varargin{:});
            
            setenv('CCIR_RAD_MEASUREMENTS_DIR', fullfile(getenv('HOME'), 'Documents', 'private', ''));
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
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
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_op_%s%s', map, this.fdgACRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

