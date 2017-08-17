classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties
        epoch
        segment
        filetypeExt = '.4dfp.ifh'
    end
    
	properties (Dependent)
        attenuationTag
        convertedTag
        epochLabel
        hct
        petBlur
        plasmaGlucose        
        rawdataDir
        resolveTag
        vfolder
    end
    
    methods (Static)
        function this = loadSession(subjFold, sessid, varargin)
            assert(ischar(sessid), ...
                'mlraichle:unsupportedTypeclass', 'class(SessionData.loadSession.sessid) -> %s', class(sessid));
            pth = fullfile(getenv('PPG'), subjFold, sessid, '');
            assert(isdir(pth), ...
                'mlraichle:pathNotFound', 'SessionData.loadSession.pth -> %s', pth);
            this = mlraichle.SessionData('sessionPath', pth, varargin{:});
        end
    end

    methods
        
        %% GET
        
        function g    = get.attenuationTag(this)
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
        function g    = get.convertedTag(this)
            g = 'Converted';
            if (~isempty(this.segment))
                assert(isnumeric(this.segment));
                g = sprintf('%s-Seg%i', g, this.segment);
            end
            g = [g '-' this.attenuationTag];
        end
        function g    = get.epochLabel(this)
            assert(isnumeric(this.epoch));
            if (1 == length(this.epoch))
                g = sprintf('e%i', this.epoch);
            else
                g = sprintf('e%ito%i', this.epoch(1), this.epoch(end));
            end
        end
        function g    = get.hct(this)
            g = this.bloodGlucoseAndHct.Hct(this.sessionFolder, this.vnumber);
        end
        function g    = get.petBlur(~)
            g = mlpet.MMRRegistry.instance.petPointSpread;
        end
        function g    = get.plasmaGlucose(this)
            g = this.bloodGlucoseAndHct.plasmaGlucose(this.sessionFolder, this.vnumber);
        end
        function g    = get.rawdataDir(this)
            g = this.studyData_.rawdataDir;
        end 
        function g    = get.resolveTag(this)
            if (~isempty(this.resolveTag_))
                g = this.resolveTag_;
                return
            end
            g = sprintf('op_%s', this.tracerRevision('typ','fp'));
        end
        function this = set.resolveTag(this, s)
            assert(ischar(s));
            this.resolveTag_ = s;
        end       
        function g    = get.vfolder(this)
            g = sprintf('V%i', this.vnumber);
        end   
        
        %% IMRData       
        
        function obj  = adc(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_ADC', varargin{:});
        end
        function obj  = aparcAsegBinarized(this, varargin)
            fqfn = fullfile(this.vLocation, sprintf('aparcAsegBinarized_%s.4dfp.ifh', this.resolveTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = atlas(this, varargin)
            ip = inputParser;
            addParameter(ip, 'desc', 'TRIO_Y_NDC', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            obj = imagingType(ip.Results.typ, ...
                fullfile(getenv('REFDIR'), ...
                         sprintf('%s%s%s', ip.Results.desc, ip.Results.suffix, this.filetypeExt)));
        end
        function obj  = brainmaskBinarizeBlended(this, varargin)
            fqfn = fullfile(this.vLocation, sprintf('brainmaskBinarizeBlended_%s.4dfp.ifh', this.resolveTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = dwi(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_TRACEW', varargin{:});
        end
        function loc  = freesurferLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.freesurfersDir, [this.sessionLocation('typ', 'folder') '_' this.vLocation('typ', 'folder')], ''));
        end  
        function obj  = mpr(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = mprage(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = perf(this, varargin)
            obj = this.mrObject('ep2d_perf', varargin{:});
        end
        function obj  = T1(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            fqfn = fullfile(this.vLocation, 'T1001.4dfp.ifh');
            if (~lexist(fqfn, 'file'))
                mic = T1@mlpipeline.SessionData(this, 'typ', 'mlmr.MRImagingContext');
                mic.niftid;
                mic.saveas(fqfn);
            end
            obj = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = t1(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = tof(this, varargin)
            obj = this.mrObject('tof', varargin{:});
        end
        function obj  = toffov(this, varargin)
            obj = this.mrObject('AIFFOV%s%s', varargin{:});
        end
                
        %% IPETData
        
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
            obj = fullfile( ...
                this.vLocation, 'CCIRRadMeasurements.xlsx');
        end
        function obj  = ct(this, varargin)
            obj = this.ctObject('ct', varargin{:});
        end
        function obj  = ctMasked(this, varargin)
            obj = this.ctObject('ctMasked', varargin{:});
        end
        function obj  = ctMask(this, varargin)
            obj = this.ctObject('ctMask', varargin{:});
        end
        function obj  = ctRescaled(this, varargin)
            fqfn = fullfile( ...
                this.vLocation('typ', 'path'), ...
                sprintf('ctRescaledv%i.4dfp.ifh', this.vnumber));
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
            inst = mlpet.MMRRegistry.instance;
            p    = inst.petPointSpread(varargin{:});
        end
        function suff = petPointSpreadSuffix(this, varargin)
            suff = sprintf('_b%i', floor(10*mean(this.petPointSpread(varargin{:}))));
        end
        function obj  = timingData(this, varargin)
            %% TIMINGDATA 
            %  @deprecated prefer mlpet.IScannerData.readTimingData
            
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.subjectsDir, ...
                sprintf('%s-%s-timings.txt', ipr.tracer, this.attenuationTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerConvertedLocation(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.convertedTag), ''));
        end
        function obj  = tracerEpoch(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            if (isempty(this.epoch))
                fn = sprintf('%s%sv%i.4dfp.ifh', lower(ipr.tracer), schar, this.vnumber);
            else
                fn = sprintf('%s%sv%i%s.4dfp.ifh', lower(ipr.tracer), schar, this.vnumber, this.epochLabel);
            end
            
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), fn);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerLocation(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.vLocation);
                return
            end
            if (isempty(this.epoch))
                loc = locationType(ipr.typ, ...
                      fullfile(this.vLocation, ...
                               sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.attenuationTag), ''));
            else
                loc = locationType(ipr.typ, ...
                      fullfile(this.vLocation, ...
                               sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.attenuationTag), ...
                               capitalize(this.epochLabel), ''));
                if (~isdir(loc))
                    mkdir(loc);
                end
            end
        end
        function loc  = tracerListmodeLocation(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.convertedTag), ...
                         sprintf('%s%s_V%i-LM-00', ipr.tracer, schar, this.vnumber), ''));
        end
        function obj  = tracerListmodeMhdr(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP%s.mhdr', ipr.tracer, schar, this.vnumber, ipr.nacTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeSif(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP%s.4dfp.ifh', ipr.tracer, schar, this.vnumber, ipr.nacTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeUmap(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-umap.v', ipr.tracer, schar, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeFrameV(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerListmodeLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP%s_%03i_000.v', ipr.tracer, schar, this.vnumber, ipr.nacTag, ipr.frame));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSif(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            ipr.ac = false;
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP%s.4dfp.ifh', ipr.tracer, schar, this.vnumber, ipr.nacTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolved(this, varargin)
            fqfn = sprintf('%s_%s.4dfp.ifh', this.tracerRevision('typ', 'fqfp'), this.resolveTag);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedSumt(this, varargin)
            fqfn = sprintf('%s_%s_sumt.4dfp.ifh', this.tracerRevision('typ', 'fqfp'), this.resolveTag);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevision(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            if (isempty(this.epoch))
                fn = sprintf('%s%sv%ir%i.4dfp.ifh', lower(ipr.tracer), schar, this.vnumber, ipr.rnumber);
            else
                fn = sprintf('%s%sv%i%sr%i.4dfp.ifh', lower(ipr.tracer), schar, this.vnumber, this.epochLabel, ipr.rnumber);
            end
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), fn);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevisionSumt(this, varargin)
            fqfn = sprintf('%s_sumt.4dfp.ifh', this.tracerRevision('typ', 'fqfp'));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerVisit(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%i.4dfp.ifh', lower(ipr.tracer), schar, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerT4Location(this, varargin)
            %% TRACERT4LOCATION has KLUDGES!
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
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
        function obj  = umapSynth(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', this.tracer, @ischar);
            parse(ip, varargin{:});
            this.tracer = ip.Results.tracer;
            
            if (isempty(this.tracer))
                fqfn = fullfile(this.vLocation('typ', 'path'), 'umapSynth_op_T1001_b40.4dfp.ifh');
                obj  = this.fqfilenameObject(fqfn, varargin{:});
                return
            end
            fqfn = fullfile( ...
                this.tracerLocation('typ', 'path'), ...
                sprintf('umapSynthv%i_op_%s.4dfp.ifh', this.vnumber, this.tracerRevision('typ', 'fp')));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end     

        %%  
        
        function obj = ctObject(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.sessionLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.suffix, this.filetypeExt));
            this.ensureCTFqfilename(fqfn);
            obj = imagingType(ip.Results.typ, fqfn);
        end 
        function obj = fqfilenameObject(~, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'fqfn', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfn', @ischar);
            parse(ip, varargin{:});
            
            obj = imagingType(ip.Results.typ, ip.Results.fqfn);
        end
        function obj = fqfileprefixObject(~, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'fqfp', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            obj = imagingType(ip.Results.typ, ip.Results.fqfp);
        end
        function [ipr,schar,this] = iprLocation(this, varargin)
            %% IPRLOCATION
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'ac', this.attenuationCorrected, @islogical);
            addParameter(ip, 'tracer', this.tracer, @ischar);
            addParameter(ip, 'frame', nan, @isnumeric);
            addParameter(ip, 'nacTag', '', @ischar);
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            addParameter(ip, 'snumber', this.snumber, @isnumeric);
            addParameter(ip, 'vnumber', this.vnumber, @isnumeric);
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});            
            ipr = ip.Results;
            this.attenuationCorrected = ip.Results.ac;
            this.tracer  = ip.Results.tracer; 
            this.rnumber = ip.Results.rnumber;
            this.snumber = ip.Results.snumber;
            this.vnumber = ip.Results.vnumber;            
            if (~lstrfind(upper(ipr.tracer), 'OC') && ...
                ~lstrfind(upper(ipr.tracer), 'OO') && ...
                ~lstrfind(upper(ipr.tracer), 'HO'))
                ipr.snumber = nan;
            end
            if (isnan(ipr.snumber))
                schar = '';
            else
                schar = num2str(ip.Results.snumber);
            end
        end
        function obj = mrObject(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'orientation', '', @(x) lstrcmp({'sagittal' 'transverse' 'coronal' ''}, x));
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.fourdfpLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.suffix, this.filetypeExt));
            this.ensureMRFqfilename(fqfn);
            fqfn = this.ensureOrientation(fqfn, ip.Results.orientation);
            obj  = imagingType(ip.Results.typ, fqfn);
        end 
        function obj = petObject(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'tracer', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            suff = ip.Results.suffix;
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
        function tag = resolveTagFrame(this, f)
            tag = sprintf('%s_frame%i', this.resolveTag, f);
        end
        function a   = seriesDicomAsterisk(this, varargin)
            a = this.studyData.seriesDicomAsterisk(varargin{:});
        end
        function loc = vLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionPath, sprintf('V%i', this.vnumber), ''));
        end        
        
 		function this = SessionData(varargin)
 			this = this@mlpipeline.SessionData(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'studyData', mlraichle.StudyData, @(x) isa(x, 'mlpipeline.StudyDataHandle'));            
            addParameter(ip, 'resolveTag', '',   @ischar);
            parse(ip, varargin{:});             
            this.resolveTag_ = ip.Results.resolveTag;
            this.studyData_ = ip.Results.studyData;
            
            filename = fullfile(this.subjectsDir, this.bloodGlucoseAndHctXlsx);
            if (lexist(filename, 'file'))
                this.bloodGlucoseAndHct = mlraichle.BloodGlucoseAndHct(filename);
            else
                warning('mlraichle:dataNotAvailable', 'SessionData.cotr.%s', this.bloodGlucoseAndHctXlsx);
            end
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        resolveTag_
    end
    
    methods (Access = protected)
        function        ensureCTFqfilename(~, fqfn) %#ok<INUSD>
            %assert(lexist(fqfn, 'file'));
        end
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
            if (~lexist(fqfn, 'file'))
                try
                    import mlfourdfp.*;
                    srcPath = DicomSorter.findRawdataSession(this);
                    destPath = this.fourdfpLocation;
                    DicomSorter.session_to_4dfp( ...
                        srcPath, destPath, ...
                        'studyData', this.studyData_, 'seriesFilter', mybasename(fqfn), 'preferredName', mybasename(fqfn));
                catch ME
                    handexcept(ME);
                end
            end
        end
        function        ensurePETFqfilename(~, fqfn) %#ok<INUSD>
            %assert(lexist(fqfn, 'file'));
        end
        function        ensureUmapFqfilename(~, fqfn) %#ok<INUSD>
            %assert(lexist(fqfn, 'file'));
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
        function o    = readOrientation(~, varargin)
            ip = inputParser;
            addRequired(ip, 'fqfp', @mlfourdfp.FourdfpVisitor.lexist_4dfp);
            parse(ip, varargin{:});
            
            [~,o] = mlbash(sprintf('awk ''/orientation/{print $NF}'' %s.4dfp.ifh', ip.Results.fqfp));
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
    end
    
    %% HIDDEN
    %  @deprecated as used in early development.  Use less-specialized corresponding methods from above.
    
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
                sprintf('%s%sv%ir%i_on_resolved.4dfp.ifh', ...
                    lower(ipr.tracer), schar, this.vnumber, ipr.rnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedSumt1(this, varargin)
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%ir%i_on_resolved_sumt.4dfp.ifh', ...
                    lower(ipr.tracer), schar, this.vnumber, ipr.rnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end    
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

