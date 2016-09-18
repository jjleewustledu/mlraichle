classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties (Dependent)
        T1_fqfn
        aparcA2009sAseg_fqfn
        brain_fqfn
        ct_fqfn
        ct_fqfp
        ep2d_fqfn
        mpr_fqfn
        mpr_fqfp
        orig_fqfn
        pet_fqfns
        petfov_fqfn
        tof_fqfn
        toffov_fqfn
        umap_fqfn
        umap_fqfp
        wmparc_fqfn
        
        petBlur
    end
    
    methods %% GET 
        function g = get.T1_fqfn(this)
            g = fullfile(this.mriPath, 'T1.mgz');
        end
        function g = get.aparcA2009sAseg_fqfn(this)
            g = fullfile(this.mriPath, 'aparc.a2009s+aseg.mgz');
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.brain_fqfn(this)
            g = fullfile(this.mriPath, 'brain.mgz');
        end
        function g = get.ct_fqfn(this)
            g = fullfile(this.petPath, 'ct.4dfp.img');
        end
        function g = get.ct_fqfp(this)
            [pth,fp] = myfileparts(this.ct_fqfn);
            g = fullfile(pth, fp);
        end
        function g = get.ep2d_fqfn(this)
            g = fullfile(this.fslPath, this.studyData_.ep2d_fn(this));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.mpr_fqfn(this)
            g = fullfile(this.fslPath, this.studyData_.mpr_fn(this));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.mpr_fqfp(this)
            [pth,fp] = myfileparts(this.mpr_fqfn);
            g = fullfile(pth, fp);
        end
        function g = get.orig_fqfn(this)
            g = fullfile(this.mriPath, 'orig.mgz');
        end
        function g = get.pet_fqfns(this)
            fqfns = { this.fdg_fqfn this.ho_fqfn this.oc_fqfn this.oo_fqfn };
            g = {};
            for f = 1:length(fqfns)
                if (2 == exist(fqfns{f}, 'file'))
                    g = [g fqfns{f}];
                end
            end
        end
        function g = get.petfov_fqfn(this)
            g = fullfile(this.petPath, this.studyData_.petfov_fn(this.tag));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.tof_fqfn(this)
            g = fullfile(this.petPath, 'fdg', 'pet_proc', this.studyData_.tof_fn(this.tag));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.toffov_fqfn(this)
            g = fullfile(this.petPath, 'fdg', 'pet_proc', this.studyData_.toffov_fn(this.tag));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.umap_fqfn(this)
            g = fullfile(this.petPath, 'umap.4dfp.img');
        end
        function g = get.umap_fqfp(this)
            [pth,fp] = myfileparts(this.umap_fqfn);
            g = fullfile(pth, fp);
        end
        function g = get.wmparc_fqfn(this)
            g = fullfile(this.mriPath, 'wmparc.mgz');
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
            %         'studyData'   is a mlpipeline.StudyDataSingleton
            %         'sessionPath' is a path to the session data
            %         'rnumber'     is numeric
            %         'snumber'     is numeric
            %         'tracer'      is char
            %         'vnumber'     is numeric
            %         'tag'         is appended to the fileprefix

 			this = this@mlpipeline.SessionData(varargin{:});
        end
        
        %% IMRData
        
        function loc  = freesurferLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(getenv('PPG'), 'freesurfer', ...
                sprintf('%s_V%i', this.sessionLocation('folder'), this.vnumber)), ...
                'CNDA*', 'DATA', ...
                sprintf('%s*', this.sessionLocation('folder')), ...
                '');
        end
        function loc  = fslLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(thisvLocation('path'), 'fsl', ''));
        end
        function loc  = mriLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.freesurferLocation('path'), 'mri', ''));
        end
        
        function obj  = adc(~) %#ok<STOUT>
        end
        function obj  = aparcA2009sAseg(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.mriLocation('path'), 'aparc.a2009s+aseg.mgz'));
        end
        function obj  = asl(~) %#ok<STOUT>
        end
        function obj  = atlas(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(getenv('REFDIR'), 'TRIO_Y_NDC.4dfp.img'));
        end
        function obj  = bold(~) %#ok<STOUT>
        end
        function obj  = brain(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.mriLocation('path'), 'brain.mgz'));
        end
        function obj  = dwi(~) %#ok<STOUT>
        end
        function obj  = ep2d(~) %#ok<STOUT>
        end
        function obj  = fieldmap(~) %#ok<STOUT>
        end
        function obj  = localizer(~) %#ok<STOUT>
        end
        function obj  = mpr(this, typ)
            obj = this.mprage(typ);
        end
        function obj  = mprage(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.vLocation('path'), 'mpr.4dfp.img'));
        end
        function obj  = orig(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.mriLocation('path'), 'orig.mgz'));
        end
        function obj  = t1(this, typ)
            obj = this.mpr(typ);
        end
        function obj  = t2(~) %#ok<STOUT>
        end
        function obj  = tof(~) %#ok<STOUT>
        end
        function obj  = wmparc(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.mriLocation('path'), 'wmparc.mgz'));
        end
                
        %% IPETData
        
        function loc = fdgACLocation(this, typ)
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
        function loc = fdgNACLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.vLocation('path'), ...
                sprintf('FDG_V%i-NAC', this.vnumber), ''));
        end        
        function loc  = hdrinfoLocation(this, typ)
            loc = this.studyData_.locationType(typ, ...
                fullfile(this.vLocation('path'), 'hdr_backup', ''));
        end
        function loc  = petLocation(this, typ)
            loc = this.vLocation(typ);
        end
        
        function obj  = ct(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.vLocation('path'), 'ct.4dfp.img'));
        end
        function obj  = ctMasked(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.vLocation('path'), 'ctMasked.4dfp.img'));
        end
        function obj  = fdg(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.vLocation('path'), 'fdg.4dfp.img'));
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
        function obj  = fdgNACResolved(this, typ, varargin)            
            ip = inputParser;
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            parse(ip, varargin{:});
            
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgNACLocation('path'), ...
                sprintf('fdgv%ir%i_resolved.4dfp.img', this.vnumber, ip.Results.rnumber)));
        end
        function obj  = gluc(~) %#ok<STOUT>
        end
        function obj  = ho(~) %#ok<STOUT>
        end
        function obj  = oc(~) %#ok<STOUT>
        end
        function obj  = oo(~) %#ok<STOUT>
        end
        function obj  = tr(~) %#ok<STOUT>
        end        
        function obj  = umapSiemens(this, typ)
            obj = this.studyData_.imagingType(typ, ...
                fullfile(this.fdgNACLocation('path'), ...
                sprintf('FDG_V%i-LM-00-umap.v', this.vnumber)));
        end      
        
        function p = petPointSpread(~)
            %% PETPOINTSPREAD
            %  The fwhh at 1cm from axis was measured by:
            %  Delso, Fuerst Jackoby, et al.  Performance Measurements of the Siemens mMR Integrated Whole-Body PET/MR
            %  Scanner.  J Nucl Med 2011; 52:1?9.
            
            p = [4.3 4.3 4.3];
        end
    end
    
    %% DEPRECATED, HIDDEN
    
    methods (Hidden)
        function f = fdg_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%sFDG%s%s', this.sessionFolder, this.tag, ip.Results.tag));
        end
        function f = fdg_fqfp(this, varargin)
            [pth,fp] = myfileparts(this.fdg_fqfn(varargin{:}));
            f = fullfile(pth, fp);
        end
        function f = fdgSumtBlurred_fqfn(this, varargin)
            f = [this.fdgSumtBlurred_fqfp(varargin{:}) '.4dfp.img'];
        end
        function f = fdgSumtBlurred_fqfp(this, varargin)
            f = sprintf('%s_sumt_b%i', this.fdg_fqfp(varargin{:}), floor(10*max(this.petBlur)));
        end
        function f = ho_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%sho%i%s%s', this.sessionFolder, this.snumber, this.tag, ip.Results.tag));
        end
        function f = oc_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%soc%i%s%s', this.sessionFolder, this.snumber, this.tag, ip.Results.tag));
        end
        function f = oo_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%soo%i%s%s', this.sessionFolder, this.snumber, this.tag, ip.Results.tag));
        end        	  
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

