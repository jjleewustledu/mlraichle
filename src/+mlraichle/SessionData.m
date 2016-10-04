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
        function loc  = vLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.sessionPath, sprintf('V%i', this.vnumber), ''));
        end
        
        %% IMRData
        
        function loc  = freesurferLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.freesurfersDir, [this.sessionLocation('folder') '_' this.vLocation('folder')], ''));
        end
        
        function obj  = adc(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['ep2d_diff_26D_lgfov_nopat_ADC' this.filetypeExt]));
        end
        function obj  = asl(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['pcasl' this.filetypeExt]));
        end
        function obj  = boldResting(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['ep2d_bold_150' this.filetypeExt]));
        end
        function obj  = boldTask(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['ep2d_bold_154' this.filetypeExt]));
        end
        function obj  = dwi(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['ep2d_diff_26D_lgfov_nopat_TRACEW' this.filetypeExt]));
        end
        function obj  = fieldmap(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['FieldMapping' this.filetypeExt]));
        end
        function obj  = localizer(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['localizer' this.filetypeExt]));
        end
        function obj  = mprage(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['t1_mprage_sag' this.filetypeExt]));
        end
        function obj  = perf(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['ep2d_perf' this.filetypeExt]));
        end
        function obj  = t2(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['t2_spc_sag' this.filetypeExt]));
        end
        function obj  = tof(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['tof' this.filetypeExt]));
        end
                
        %% IPETData
        
        function loc  = fdgACLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.vLocation('path'), ...
                         sprintf('FDG_V%i-AC', this.vnumber), ''));
        end
        function loc  = fdgListmodeLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.vLocation('path'), ...
                         sprintf('FDG_V%i-Converted', this.vnumber), ...
                         sprintf('FDG_V%i-LM-00', this.vnumber), ''));
        end
        function loc  = fdgNACLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.vLocation('path'), ...
                         sprintf('FDG_V%i-NAC', this.vnumber), ''));
        end    
        function obj  = petObject(this, varargin)
            ip = inputParser;
            addRequired( ip, 'tracer', @ischar);
            addParameter(ip, 'suffix', '', @ischar);
            addParameter(ip, 'typ', 'mlpet.PETImagingContext', @ischar);
            parse(ip, varargin{:});
            
            obj = this.studyData_.imagingType(ip.Results.typ, ...
                fullfile(this.petLocation('path'), ...
                         sprintf('%s%i_v%i%s%s', ip.Results.tracer, this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt)));
        end    
        
        function obj  = ct(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.sessionLocation('path'), ['ct' this.filetypeExt]));
        end
        function obj  = ctMasked(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.vLocation('path'), ['ctMasked' this.filetypeExt]));
        end
        function obj  = fdg(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.petLocation('path'), sprintf('fdg_v%i%s%s', this.vnumber, this.nacSuffix, this.filetypeExt)));
        end
        function obj  = fdgAC(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgACLocation('path'), ...
                         sprintf('FDG_V%i-LM-00-OP.4dfp.img', this.vnumber)));
        end
        function obj  = fdgNAC(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgNACLocation('path'), ...
                         sprintf('FDG_V%i-LM-00-OP.4dfp.img', this.vnumber)));
        end
        function obj  = fdgNACResolved(this, typ, varargin)            
            ip = inputParser;
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            parse(ip, varargin{:});
            
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgNACLocation('path'), ...
                sprintf('fdgv%ir%i_resolved.4dfp.img', this.vnumber, ip.Results.rnumber)));
        end
        function obj  = gluc(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.petLocation('path'), sprintf('gluc%i_v%i%s%s', this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt)));
        end 
        function obj  = ho(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.petLocation('path'), sprintf('ho%i_v%i%s%s', this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt)));
        end
        function obj  = oc(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.petLocation('path'), sprintf('oc%i_v%i%s%s', this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt)));
        end
        function obj  = oo(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.petLocation('path'), sprintf('oo%i_v%i%s%s', this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt)));
        end
        function obj  = tr(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.petLocation('path'), sprintf('tr%i_v%i%s%s', this.snumber, this.vnumber, this.nacSuffix, this.filetypeExt)));
        end
        function obj  = umap(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fourdfpLocation('path'), ['Head_UTE_AC_only_UMAP' this.filetypeExt]));
        end 
        function obj  = umapSiemens(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgNACLocation('path'), ...
                sprintf('FDG_V%i-LM-00-umap.v', this.vnumber)));
        end      
        
        function p = petPointSpread(varargin)
            p = mlpet.MMRRegistry.instance.petPointSpread(varargin{:});
        end
    end
    
    %% DEPRECATED, HIDDEN
    
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
        
        function g = aparcA2009sAseg_fqfn(this)
            g = fullfile(this.mriLocation('path'), 'aparc.a2009s+aseg.mgz');
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = brain_fqfn(this)
            g = fullfile(this.mriLocation('path'), 'brain.mgz');
        end
        function g = ct_fqfn(this)
            g = fullfile(this.petLocation('path'), 'ct.4dfp.img');
        end
        function g = ct_fqfp(this)
            [pth,fp] = myfileparts(this.ct_fqfn);
            g = fullfile(pth, fp);
        end
        function g = ep2d_fqfn(this)
            g = this.perf('fqfn');
        end  
        function f = fdg_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petLocation('path'), sprintf('%sFDG%s%s', this.sessionFolder, this.tag, ip.Results.tag));
        end
        function f = fdg_fqfp(this, varargin)
            [pth,fp] = myfileparts(this.fdg_fqfn(varargin{:}));
            f = fullfile(pth, fp);
        end
        function f = ho_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petLocation('path'), sprintf('%sho%i%s%s', this.sessionFolder, this.snumber, this.tag, ip.Results.tag));
        end
        function g = mpr_fqfn(this)
            g = fullfile(this.fslLocation('path'), this.studyData_.mpr_fn(this));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = mpr_fqfp(this)
            [pth,fp] = myfileparts(this.mpr_fqfn);
            g = fullfile(pth, fp);
        end   
        function f = oc_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petLocation('path'), sprintf('%soc%i%s%s', this.sessionFolder, this.snumber, this.tag, ip.Results.tag));
        end
        function f = oo_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petLocation('path'), sprintf('%soo%i%s%s', this.sessionFolder, this.snumber, this.tag, ip.Results.tag));
        end 
        function g = orig_fqfn(this)
            g = fullfile(this.mriLocation('path'), 'orig.mgz');
        end
        function g = pet_fqfns(this)
            fqfns = { this.fdg_fqfn this.ho_fqfn this.oc_fqfn this.oo_fqfn };
            g = {};
            for f = 1:length(fqfns)
                if (2 == exist(fqfns{f}, 'file'))
                    g = [g fqfns{f}];
                end
            end
        end
        function g = T1_fqfn(this)
            g = fullfile(this.mriLocation('path'), 'T1.mgz');
        end 
        function g = tof_fqfn(this)
            g = fullfile(this.petLocation('path'), 'fdg', 'pet_proc', this.studyData_.tof_fn(this.tag));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = toffov_fqfn(this)
            g = fullfile(this.petLocation('path'), 'fdg', 'pet_proc', this.studyData_.toffov_fn(this.tag));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = umap_fqfn(this)
            g = fullfile(this.petLocation('path'), 'umap.4dfp.img');
        end     
        function g = umap_fqfp(this)
            [pth,fp] = myfileparts(this.umap_fqfn);
            g = fullfile(pth, fp);
        end
        function g = wmparc_fqfn(this)
            g = fullfile(this.mriLocation('path'), 'wmparc.mgz');
        end    	  
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

