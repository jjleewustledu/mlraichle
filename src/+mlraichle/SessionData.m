classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties
        filetypeExt = '.4dfp.ifh'
    end
    
	properties (Dependent)
        acTag
        convertedSuffix
        petBlur
        rawdataDir
    end
    
    methods %% GET
        function g = get.acTag(this)
            if (this.attenuationCorrected)
                g = 'AC';
            else
                g = 'NAC';
            end
        end
        function g = get.convertedSuffix(this)
            if (~this.attenuationCorrected)
                g = '-Converted-NAC';
                return
            end
            if (lstrfind(upper(this.tracer), 'OO') || ...
                lstrfind(upper(this.tracer), 'OC'))
                g = '-Converted-Abs';
                return
            end
            g = '-Converted';
        end
        function g = get.petBlur(~)
            g = mlpet.MMRRegistry.instance.petPointSpread;
            g = mean(g);
        end
        function g = get.rawdataDir(this)
            g = this.studyData_.rawdataDir;
        end 
    end

	methods
 		function this = SessionData(varargin)
 			this = this@mlpipeline.SessionData(varargin{:});
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
            
            if (lstrfind(upper(ipr.tracer), 'FDG'))
                ipr.snumber = nan;
            end
            if (isnan(ipr.snumber))
                schar = '';
            else
                schar = num2str(ip.Results.snumber);
            end
        end
        function loc  = vLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionPath, sprintf('V%i', this.vnumber), ''));
        end
        
        %% IMRData
        
        function obj  = adc(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_ADC', varargin{:});
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
        function obj  = tof(this, varargin)
            obj = this.mrObject('tof', varargin{:});
        end
        function obj  = toffov(this, varargin)
            obj = this.mrObject('AIFFOV%s%s', varargin{:});
        end
                
        %% IPETData
        
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
        function p    = petPointSpread(varargin)
            inst = mlpet.MMRRegistry.instance;
            p    = inst.petPointSpread(varargin{:});
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
                         sprintf('%s%s_V%i%s', ipr.tracer, schar, this.vnumber, this.convertedSuffix), ...
                         sprintf('%s%s_V%i-LM-00', ipr.tracer, schar, this.vnumber), ''));
        end
        function loc  = tracerLocation(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.vLocation);
                return
            end
            loc = locationType(ipr.typ, ...
                  fullfile(this.vLocation, sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.acTag), ''));
        end
        function obj  = tracerLM(this, varargin)
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
                sprintf('%s%s_V%i-LM-00-OP.4dfp.ifh', ipr.tracer, schar, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerLMFrame(this, varargin)
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
                sprintf('%s%s_V%i-LM-00-OP_%03i_000.v', ipr.tracer, schar, this.vnumber, ipr.frame));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerNative(this, varargin)
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
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s_V%i-LM-00-OP.4dfp.ifh', ipr.tracer, schar, this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolved(this, varargin)
            %  @param named tracer is a string identifier.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @param named frame is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            [ipr,schar] = this.iprLocation(varargin{:});
            assert(~isempty(this.builder_), ...
                'please assign SessionData.builder before calling SessionData.tracerResolved');
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%ir%i_%s.4dfp.ifh', ...
                    lower(ipr.tracer), schar, this.vnumber, ipr.rnumber, this.builder__.resolveTag));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevision(this, varargin)
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
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%sv%ir%i.4dfp.ifh', lower(ipr.tracer), schar, this.vnumber, ipr.rnumber));
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
                             sprintf('%s_V%i-%s', ipr.tracer, this.vnumber, this.acTag), 'T4', ''));
                return
            end
            if (lstrfind(ipr.tracer, 'HO') || lstrfind(ipr.tracer, 'OO'))
                ipr.tracer = 'OO';
            end            
            if (isdir(fullfile(this.vLocation, sprintf('OO1_V%i-%s', this.vnumber, this.acTag))))
                schar = '1';
            end
            if (isdir(fullfile(this.vLocation, sprintf('OO2_V%i-%s', this.vnumber, this.acTag))))
                schar = '2';
            end
            loc = locationType(ipr.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('%s%s_V%i-%s', ipr.tracer, schar, this.vnumber, this.acTag), 'T4', ''));
        end
        function obj  = tracerUmapLM(this, varargin)
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
        function obj  = umapSynth(this, varargin)
            if (isempty(this.tracer))
                fqfn = fullfile(this.vLocation('typ', 'path'), 'umapSynth_op_T1001.4dfp.ifh');
                obj  = this.fqfilenameObject(fqfn, varargin{:});
                return
            end
            fqfn = fullfile( ...
                this.tracerLocation('typ', 'path'), ...
                sprintf('umapSynth_op_%s.4dfp.ifh', this.tracerRevision('typ', 'fqfp')));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end     

        %% idiomatic objects
        
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
            
            if (lstrfind(lower(ip.Results.tracer), 'fdg'))
                fqfn = fullfile(this.petLocation, ...
                       sprintf('%sv%ir%i%s', ip.Results.tracer, this.vnumber, this.rnumber, this.filetypeExt));
            else
                fqfn = fullfile(this.petLocation, ...
                       sprintf('%s%iv%ir%i%s', ip.Results.tracer, this.snumber, this.vnumber, this.rnumber, this.filetypeExt));
            end
            this.ensurePETFqfilename(fqfn);
            obj = imagingType(ip.Results.typ, fqfn);
        end  
    end
    
    %% PROTECTED
    
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
    
    %% HIDDEN, DEPRECATED
    
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
        function obj  = fdgLM(this, varargin)
            obj = this.tracerLM('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgLMFrame(this, frame, varargin)
            assert(isnumeric(frame));
            obj = this.tracerLMFrame('tracer', 'FDG', 'frame', frame, varargin{:});
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
        function obj  = fdgNACResolved0(this, typ, varargin)
            ip = inputParser;
            addParameter(ip, 'frame0', nan, @isnumeric);
            addParameter(ip, 'frameF', nan, @isnumeric);
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            parse(ip, varargin{:});
            
            obj = imagingType(typ, ...
                fullfile(this.fdgNACLocation('typ', 'path'), ...
                sprintf('fdgv%ir%i_frames%ito%i_resolved.4dfp.img', this.vnumber, ip.Results.rnumber, ip.Results.frame0, ip.Results.frameF)));
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
        function obj  = fdgUmapLM(this, varargin)
            obj = this.tracerUmapLM('tracer', 'FDG', varargin{:});
        end
        function obj  = tracerAC(this, varargin)
            this.attenuationCorrected = true;
            obj = this.tracerNative(varargin{:});
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
            obj = this.tracerNative(varargin{:});
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
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

