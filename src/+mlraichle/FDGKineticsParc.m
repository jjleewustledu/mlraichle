classdef FDGKineticsParc < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSPARC  

	%  $Revision$
 	%  was created 17-Feb-2017 07:41:24
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties (Constant)
        
        %% aparc+aseg
        
 		caudate = [11 50] % [L R]
        putamen = [12 51]
        pallidus = [13 52]
        thalamus = [10 49]
        cerebWhite = [7 46]
        cerebCortex = [8 47]
        brainstem = [16 16]
        ventralDC = [28 60]
        amygdala  = [18 54]
        hippo = [17 53]       
        yeoOffset = 100
 	end

	methods 
		  
 		function this = FDGKineticsParc(varargin)
 			%% FDGKINETICSPARC
 			%  Usage:  this = FDGKineticsParc()

 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
 		end
 	end 

    methods (Static)
        function this = godo(sessfold, v)
            import mlraichle.*;
            studyd = StudyData;
            assert(strcmp(studyd.subjectsFolder, 'jjlee'));
            vloc = fullfile(studyd.subjectsDir, sessfold, sprintf('V%i', v), '');
            assert(isdir(vloc));
            
            sessd = SessionData('studyData', studyd, 'sessionPath', fileparts(vloc));
            sessd.vnumber = v;
            sessd.attenuationCorrected = true;
            sessd.selectedMask = FDGKineticsParc.parcMask(sessd).fqfilename;
            this = FDGKineticsParc.runMask(sessd);
        end
        function this = runMask(sessd)
            tic
            assert(isa(sessd, 'mlraichle.SessionData'));
            cd(sessd.vLocation);
            import mlpet.* mlraichle.*;
            this = FDGKineticsParc(sessd);
            this.showAnnealing = true;
            this.showBeta      = true;
            this.showPlots     = true;
            this               = this.estimateParameters;
            this.plot;
            
            kmin = this.kmin;
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            fprintf('\n%s is working in %s\n', mfilename, sessd.sessionPath);
            fprintf('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(kmin));
            fprintf('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));
            fprintf('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(100*this.v1*kmin(1)));
            fprintf('CMRglu/[glu] = V_B chi / mL min^{-1} (100g)^{-1} -> %s\n', mat2str((this.v1/0.0105)*k1k3overk2k3));
            fprintf('\n');
            save('this_mlraichle_FDGKineticsParc_runWholebrain', 'this')
            toc
        end
        
        function pm = parcMask(sessd, parc)
            assert(ischar(parc));
            cd(sessd.vLocation);
            
            import mlraichle.*;
            [~,mskt] = FDGKineticsWholebrain.mskt(sessd);
            [~,ct4rb_bmb] = FDGKineticsWholebrain.brainmaskBinarized(sessd, mskt);
            aa = FDGKineticsParc.resolveAparcAseg(sessd, ct4rb_bmb, FDGKineticsParc.(parc));
            [mat_mni,ct4rb_mni] = FDGKineticsParc.resolveMNI152(sessd);
            y = FDGKineticsParc.resolveYeo7(sessd, mat_mni, ct4rb_mni);
            
            aa.numericalNiftid;
            y.numericalNiftid;            
            pm = aa + y;
            pm = pm.binarized;
            pm.view;
        end        
        function raa = resolveAparcAseg(sessd, ct4rb, parc)
            cd(sessd.vLocation);
            
            raa_fn = sprintf('aparc_aseg_%s.4dfp.ifh', sessd.resolveTag);
            if (lexist(raa_fn))
                return
            end
            aa_fp = sessd.aparcAseg('typ','fp');
            sessd.mri_convert(sessd.aparcAseg('typ','mgz'), [aa_fp '.nii']);
            sessd.nifti_4dfp_4(aa_fp);
            raa = ct4rb.t4img_4dfp('brainmask', aa_fp, 'opts', '-n');
            raa = raa.numericalNiftid;
            raa.img = double(raa.img == parc(1)) + double(raa.img == parc(2));
            raa = raa.binarized;
            raa = mlfourd.ImagingContext(raa);
            raa.filename = raa_fn;
            ras.save;
            raa.view;
        end
        function [mat,ct4rb] = resolveMNI152(sessd)   
            cd(sessd.vLocation);            
            
            brainmask = 'brainmask.nii';
            if (~lexist(brainmask, 'file'))
                sessd.mri_convert(sessd.brainmask('typ','mgz'), brainmask);
            end
            mni = fullfile(getenv('PPG'), 'jjlee2', 'FSL_MNI152_FreeSurferConformed_1mm.nii');
            mniOnBrain = 'MNI152OnBrain.nii.gz';
            mlbash(sprintf('flirt -in %s -ref %s -out %s -omat %s.mat -cost normmi -dof 12', ...
                mni, brainmask, mniOnBrain, mybasename(mniOnBrain)));            
            
            fv = mlfourdfp.FourdfpVisitor;            
            fdgBrain = fv.ensureSafeOn([sessd.tracerResolvedSumt1('typ','fp') '_brain']);
            sessd.nifti_4dfp_4(brainmask);      
            sessd.nifti_4dfp_4(mniOnBrain);
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgBrain mybasename(brainmask) mybasename(mniOnBrain)}, ...
                'resolveTag', 'op_fdg');
            ct4rb.resolve;
            
            mat = [mybasename(mniOnBrain) '.mat'];
        end
        function y = yeo7(sessd, mat, ct4rb)
            cd(sessd.vLocation);
            
            y = sprintf('Yeo7_%s.4dfp.ifh', sessd.resolveTag);
            if (lexist(y, 'file'))
                return
            end
            ymni = fullfile(getenv('PPG'), 'jjlee2', 'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii');
            brainmask = 'brainmask.nii';
            ynii = 'Yeo7.nii';
            mlbash(sprintf('flirt -in %s -ref %s -applyxfm -init %s -out %s', ymni, brainmask, mat, ynii));
            
            mniOnBrain = 'MNI152OnBrain';
            sessd.nifti_4dfp_4(mniOnBrain);
            y = ct4rb.t4img_4dfp(mniOnBrain, mybasename(ynii), 'opts', '-n');
            y = mlfourd.ImagingContext(y);
            y.view;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

