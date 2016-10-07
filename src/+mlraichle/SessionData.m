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
        rawdataDir
        petBlur
    end
    
    methods %% GET
        function g = get.rawdataDir(this)
            g = this.studyData_.rawdataDir;
        end        
        function g = get.petBlur(~)
            g = mlpet.MMRRegistry.instance.petPointSpread;
            g = mean(g);
        end
    end

	methods
 		function this = SessionData(varargin)
 			%% SESSIONDATA
 			%  @param [param-name, param-value[, ...]]
            %         'nac'         is logical
            %         'rnumber'     is numeric
            %         'sessionPath' is a path to the session data
            %         'studyData'   is a mlpipeline.StudyDataSingleton
            %         'snumber'     is numeric
            %         'tracer'      is char
            %         'vnumber'     is numeric
            %         'tag'         is appended to the fileprefix

 			this = this@mlpipeline.SessionData(varargin{:});
        end
        function loc  = vLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = this.studyData_.locationType(ip.Results.typ, ...
                fullfile(this.sessionPath, sprintf('V%i', this.vnumber), ''));
        end
        
        %% IMRData
        
        function loc  = freesurferLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = this.studyData_.locationType(ip.Results.typ, ...
                fullfile(this.freesurfersDir, [this.sessionLocation('typ', 'folder') '_' this.vLocation('typ', 'folder')], ''));
        end
        
        function obj  = adc(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_ADC', varargin{:});
        end
        function obj  = dwi(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_TRACEW', varargin{:});
        end
        function obj  = mprage(this, varargin)
            obj = this.mrObject('t1_mprage_sag', varargin{:});
        end
        function obj  = perf(this, varargin)
            obj = this.mrObject('ep2d_perf', varargin{:});
        end
        function obj  = t2(this, varargin)
            obj = this.mrObject('', varargin{:});
            
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation, ['t2_spc_sag' this.filetypeExt]));
        end
        function obj  = tof(this, varargin)
            obj = this.mrObject('TOF_ART', varargin{:});
        end
        function obj  = toffov(this, varargin)
            fqfn = fullfile(this.petLocation, sprintf('AIFFOV%s%s', ip.Results.suffix, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
                
        %% IPETData
        
        function loc  = fdgACLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = this.studyData_.locationType(ip.Results.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('FDG_V%i-AC', this.vnumber), ''));
        end
        function loc  = fdgListmodeLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = this.studyData_.locationType(ip.Results.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('FDG_V%i-Converted', this.vnumber), ...
                         sprintf('FDG_V%i-LM-00', this.vnumber), ''));
        end
        function loc  = fdgNACLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = this.studyData_.locationType(ip.Results.typ, ...
                fullfile(this.vLocation, ...
                         sprintf('FDG_V%i-NAC', this.vnumber), ''));
        end  
        
        function obj  = ct(this, varargin)
            obj = this.ctObject('AC_CT', varargin{:});
        end
        function obj  = ctMasked(this, varargin)
            fqfn = fullfile(this.sessionLocation, sprintf('AC_CT_masked%s', this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = fdgAC(this, varargin)
            fqfn = fullfile(this.fdgACLocation, sprintf('FDG_V%i-LM-00-OP.4dfp.img', this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = fdgNAC(this, varargin)
            fqfn = fullfile(this.fdgNACLocation, sprintf('FDG_V%i-LM-00-OP.4dfp.img', this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = fdgNACResolved(this, varargin)
            ip = inputParser;
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.fdgNACLocation, sprintf('fdgv%ir%i_resolved.4dfp.img', this.vnumber, ip.Results.rnumber));            
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = petfov(this, varargin)
            fqfn = fullfile(this.petLocation, sprintf('AIFFOV%s%s', ip.Results.suffix, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = umap(this, varargin)
            obj = this.mrObject('Head_UTE_AC_only_UMAP', varargin{:});
        end 
        function obj  = umapJSRecon(this, varargin)
            fqfn = fullfile(this.fdgNACLocation, sprintf('FDG_V%i-LM-00-umap.v', this.vnumber));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end      
        
        function p    = petPointSpread(varargin)
            p = mlpet.MMRRegistry.instance.petPointSpread(varargin{:});
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)
        function obj = ctObject(this, varargin)
            ip = inputParser;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.sessionLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.suffix, this.filetypeExt));
            this.ensureCTFqfilename(fqfn);
            obj = this.studyData_.imagingType(ip.Results.typ, fqfn);
        end 
        function       ensureCTFqfilename(~, fqfn)
            assert(lexist(fqfn, 'file'));
        end
        function       ensureMRFqfilename(~, fqfn)
            if (~lexist(fqfn, 'file'))
                import mlfourdfp.*;
                srcPath = this.findRawdataSession;
                destPath = this.fourdfpLocation;
                DicomSorter.session_to_4dfp( ...
                    srcPath, destPath, ...
                    'studyData', this.studyData_, 'filter', mybasename(fqfn), 'preferredName', mybasename(fqfn));
            end
        end
        function       ensurePETFqfilename(~, fqfn)
            assert(lexist(fqfn, 'file'));
        end
        function       ensureUmapFqfilename(~, fqfn)
            assert(lexist(fqfn, 'file'));
        end
        function obj = fqfilenameObject(this, varargin)
            ip = inputParser;
            addRequired( ip, 'fqfn', @(x) lexist(x, 'file'));
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfn', @ischar);
            parse(ip, varargin{:});
            
            obj = this.studyData_.imagingType(ip.Results.typ, ip.Results.fqfn);
        end
        function obj = mrObject(this, varargin)
            ip = inputParser;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.fourdfpLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.suffix, this.filetypeExt));
            this.ensureMRFqfilename(fqfn);
            obj = this.studyData_.imagingType(ip.Results.typ, fqfn);
        end 
        function obj = petObject(this, varargin)
            ip = inputParser;
            addRequired( ip, 'tracer', @ischar);
            addParameter(ip, 'noSnumber', false, @islogical);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            if (ip.Results.noSnumber)
                fqfn = fullfile(this.petLocation, ...
                       sprintf('%s_v%i%s%s', ip.Results.tracer, this.vnumber, this.nacSuffix, this.filetypeExt));
            else
                fqfn = fullfile(this.petLocation, ...
                       sprintf('%s%i_v%i%s%s', ip.Results.tracer, this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt));
            end
            this.ensurePETFqfilename(fqfn);
            obj = this.studyData_.imagingType(ip.Results.typ, fqfn);
        end  
        function obj = umapObject(this, varargin)
            ip = inputParser;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.fourdfpLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.suffix, this.filetypeExt));
            this.ensureUmapFqfilename(fqfn);
            obj = this.studyData_.imagingType(ip.Results.typ, fqfn);
        end 
    end
    
    %% HIDDEN, DEPRECATED
    
    methods (Hidden)
        function obj  = fdgNACResolved0(this, typ, varargin)
            ip = inputParser;
            addParameter(ip, 'frame0', nan, @isnumeric);
            addParameter(ip, 'frameF', nan, @isnumeric);
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            parse(ip, varargin{:});
            
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgNACLocation('path'), ...
                sprintf('fdgv%ir%i_frames%ito%i_resolved.4dfp.img', this.vnumber, ip.Results.rnumber, ip.Results.frame0, ip.Results.frameF)));
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

