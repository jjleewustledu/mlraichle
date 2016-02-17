classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 01:51:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties (Dependent)
        aparcA2009sAseg_fqfn
        ep2d_fqfn
        mpr_fqfn
        orig_fqfn
        pet_fqfns
        petfov_fqfn
        tof_fqfn
        toffov_fqfn
        T1_fqfn
        wmparc_fqfn
    end
    
    methods %% GET 
        function g = get.aparcA2009sAseg_fqfn(this)
            g = fullfile(this.mriPath, 'aparc.a2009s+aseg.mgz');
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.ep2d_fqfn(this)
            g = fullfile(this.fslPath, this.studyData_.ep2d_fn(this));
            this.ensureNIFTI_GZ(g);
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.mpr_fqfn(this)
            g = fullfile(this.fslPath, this.studyData_.mpr_fn(this));
            this.ensureNIFTI_GZ(g);
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
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
            g = fullfile(this.petPath, this.studyData_.petfov_fn(this.suffix));
            this.ensureNIFTI_GZ(g);
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.tof_fqfn(this)
            g = fullfile(this.petPath, 'fdg', 'pet_proc', this.studyData_.tof_fn(this.suffix));
            this.ensureNIFTI_GZ(g);
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.toffov_fqfn(this)
            g = fullfile(this.petPath, 'fdg', 'pet_proc', this.studyData_.toffov_fn(this.suffix));
            this.ensureNIFTI_GZ(g);
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.T1_fqfn(this)
            g = fullfile(this.mriPath, 'T1.mgz');
        end
        function g = get.wmparc_fqfn(this)
            g = fullfile(this.mriPath, 'wmparc.mgz');
        end
    end

	methods         
        function f = fdg_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%sfdg%s%s', this.sessionFolder, this.suffix, ip.Results.suff));
        end
        function f = ho_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%sho%i%s%s', this.sessionFolder, this.snumber, this.suffix, ip.Results.suff));
        end
        function f = oc_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%soc%i%s%s', this.sessionFolder, this.snumber, this.suffix, ip.Results.suff));
        end
        function f = oo_fqfn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            
            f = this.fullfile(this.petPath, sprintf('%soo%i%s%s', this.sessionFolder, this.snumber, this.suffix, ip.Results.suff));
        end
        
        function g = aparcA2009sAseg(this)
            g = mlmr.MRImagingContext(this.aparcA2009sAseg_fqfn);
        end
        function g = ep2d(this)
            g = this.flipAndCropImaging(mlmr.MRImagingContext(this.ep2d_fqfn));
        end
        function g = fdg(this)
            import mlpet.*;
            if (lexist(this.fdg_fqfn('_flip2_crop_mcf')))
                g = PETImagingContext(this.fdg_fqfn('_flip2_crop_mcf'));
                return
            end
            g = this.flipAndCropImaging(PETImagingContext(this.fdg_fqfn));
        end
        function g = ho(this)
            import mlpet.*;
            if (lexist(this.fdg_fqfn('_flip2_crop_mcf')))
                g = PETImagingContext(this.ho_fqfn('_flip2_crop_mcf'));
                return
            end
            g = this.flipAndCropImaging(PETImagingContext(this.ho_fqfn));
        end
        function g = mpr(this)
            g = this.flipAndCropImaging(mlmr.MRImagingContext(this.mpr_fqfn));
        end
        function g = oc(this)            
            import mlpet.*;
            if (lexist(this.oc_fqfn('_flip2_crop')))
                g = PETImagingContext(this.oc_fqfn('_flip2_crop'));
                return
            end
            g = this.flipAndCropImaging(PETImagingContext(this.oc_fqfn));
        end
        function g = oo(this)
            import mlpet.*;
            if (lexist(this.fdg_fqfn('_flip2_crop_mcf')))
                g = PETImagingContext(this.oo_fqfn('_flip2_crop_mcf'));
                return
            end
            g = this.flipAndCropImaging(PETImagingContext(this.oo_fqfn));
        end
        function g = orig(this)
            g = mlmr.MRImagingContext(this.orig_fqfn);
        end
        function g = petAtlas(this)
            g = mlpet.PETImagingContext(this.pet_fqfns);
            g = g.atlas;
        end
        function g = petfov(this)
            g = mlfourd.ImagingContext(this.petfov_fqfn);
        end
        function g = tof(this)
            g = mlmr.MRImagingContext(this.tof_fqfn);
        end
        function g = toffov(this)
            g = mlfourd.ImagingContext(this.toffov_fqfn);
        end
        function g = T1(this)
            g = mlmr.MRImagingContext(this.T1_fqfn);
        end
        function g = wmparc(this)
            g = mlmr.MRImagingContext(this.wmparc_fqfn);
        end
		  
 		function this = SessionData(varargin)
 			%% SESSIONDATA
 			%  Usage:  this = SessionData()

 			this = this@mlpipeline.SessionData(varargin{:});
        end
%         function disp(this)
%             disp@mlpipeline.SessionData(this);
%             fprintf('    aparcA2009sAseg_fqfn: ''%s''\n', this.aparcA2009sAseg_fqfn);
%             fprintf('               ep2d_fqfn: ''%s''\n', this.ep2d_fqfn);
%             fprintf('                fdg_fqfn: ''%s''\n', this.fdg_fqfn);
%             fprintf('                 ho_fqfn: ''%s''\n', this.ho_fqfn);
%             fprintf('                mpr_fqfn: ''%s''\n', this.mpr_fqfn);
%             fprintf('                 oc_fqfn: ''%s''\n', this.oc_fqfn);
%             fprintf('                 oo_fqfn: ''%s''\n', this.oo_fqfn);
%             fprintf('               orig_fqfn: ''%s''\n', this.orig_fqfn);
%             fprintf('               pet_fqfns: ''%s''\n', cell2str(this.pet_fqfns, 'AsRow', true));
%             fprintf('             petfov_fqfn: ''%s''\n', this.petfov_fqfn);
%             fprintf('                tof_fqfn: ''%s''\n', this.tof_fqfn);
%             fprintf('             toffov_fqfn: ''%s''\n', this.toffov_fqfn);
%             fprintf('                 T1_fqfn: ''%s''\n', this.T1_fqfn);
%             fprintf('             wmparc_fqfn: ''%s''\n', this.wmparc_fqfn);
%             fprintf('    [disp of mlfourd.ImagingContext objects suppressed]\n\n');
%         end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

