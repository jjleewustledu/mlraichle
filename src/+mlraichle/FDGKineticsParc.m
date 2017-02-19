classdef FDGKineticsParc < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSPARC  

	%  $Revision$
 	%  was created 17-Feb-2017 07:41:24
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        
        %% aparc+aseg
        
 		caudate = [11 50] % [L R]
        putamen = [12 51]
        pallidus = [13 52]
        thalamus = [10 49]
        cerebWhite = [7 46]
        cerebCortex = [8 47]
        brainstem = 16
        ventralDC = [28 60]
        amygdala  = [18 54]
        hippo = [17 53]        
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
            ic = FDGKineticsParc.parcMask(sessd);
            sessd.selectedMask = ic.fqfilename;
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
        
        function mskt = parcMask(sessd)
            cd(sessd.vLocation);
            
            import mlraichle.*;
            [~,mskt] = FDGKineticsWholebrain.mskt(sessd);
            [~,ct4rb_bmb] = FDGKineticsWholebrain.brainmaskBinarized(sessd, mskt);
            FDGKineticsParc.resolveAparcAseg(sessd);
            [ct4rb_mni] = FDGKineticsParc.resolveMNI152(sessd);
            FDGKineticsParc.resolveYeo7(sessd);
        end       
        
        function ct4rb = resolveMNI152(this)            
        end
        function aa = resolveAparcAseg(sessd, ct4rb)
            cd(sessd.vLocation);
            
            aa = sprintf('aparc_aseg_%s.4dfp.ifh', sessd.resolveTag);
            if (lexist(aa))
                return
            end            
            sessd.mri_convert(sessd.aparcAseg('typ','mgz'), sessd.aparcAseg('typ','nii'));
            sessd.nifti_4dfp_4(sessd.aparcAseg('typ','nii'), aa);
            ct4rb.t4img_4dfp('brainmask', mybasename(aa));            
            aa = mlfourd.ImagingContext(aa);
        end
        function b = brain(sessd)
            cd(sessd.vLocation);
            
        end
        function y = yeo7(sessd)
            cd(sessd.vLocation);
            
            y = 'Yeo7.4dfp.ifh';
            if (lexist(y, 'file'))
                return
            end
            
            brain = 'brain.nii';
            if (~lexist(brain, 'file'))
                sessd.mri_convert(fullfile(sessd.mriLocation, 'brain.mgz'), brain);
            end
            MNI152 = fullfile(getenv('PPG'), 'jjlee2', 'FSL_MNI152_FreeSurferConformed_1mm.nii');
            MNI152OnBrain = 'MNI152OnBrain.nii.gz';
            mlbash(sprintf('flirt -in %s -ref %s -out %s -omat %s.mat -cost normmi -dof 12', ...
                MNI152, brain, MNI152OnBrain, mybasename(MNI152OnBrain)));
            
            Yeo = fullfile(getenv('PPG'), 'jjlee2', 'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii');
            sessd.nifti_4dfp_4(Yeo, y);
            sessd.nifti_4dfp_4(brain);      
            sessd.nifti_4dfp_4(MNI152OnBrain);
            fdgBrain = mlraichle.FDGKineticsParc.fdgBrain(sessd);
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, 'theImages', {mybasename(fdgBrain) mybasename(brain4) mybasename(MNI152OnBrain4)}, 'resolveTag', 'op_fdg');
            ct4rb.resolve;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

