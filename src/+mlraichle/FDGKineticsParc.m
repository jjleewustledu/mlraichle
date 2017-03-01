classdef FDGKineticsParc < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSPARC  

	%  $Revision$
 	%  was created 17-Feb-2017 07:41:24
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties (Constant)
        
        PARCS = {'caudate' 'putamen' 'pallidus' 'thalamus' 'cerebellarWhite' 'cerebellarCortex' ...
                 'brainstem' 'ventralDC' 'amygdala' 'white' 'hippocampus' ...
                 'yeo1' 'yeo2' 'yeo3' 'yeo4' 'yeo5' 'yeo6' 'yeo7'}; % N=18 
                     
        %% aparc+aseg
        
 		caudate = [11 50] % [L R]
        putamen = [12 51]
        pallidus = [13 52]
        thalamus = [10 49]
        cerebellarWhite = [7 46]
        cerebellarCortex = [8 47]
        brainstem = [16 16]
        ventralDC = [28 60] % ventral diencephalon
        amygdala  = [18 54]
        white = [2 41]
        hippocampus = [17 53]
        
        %% yeo
        
        yeo1 = 1
        yeo2 = 2
        yeo3 = 3
        yeo4 = 4
        yeo5 = 5
        yeo6 = 6
        yeo7 = 7
 	end

	methods 		  
 		function this = FDGKineticsParc(varargin)
 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
 		end
 	end 

    methods (Static)
        function jobs = godoChpc
            import mlraichle.*;
            pwd0  = pushd(fullfile(getenv('PPG'), 'jjlee', ''));
            dth   = mlsystem.DirTool('HYGLY*');
            PARCS = FDGKineticsParc.PARCS;
            jobs  = {};
            for d = 1:length(dth.dns)
                obj.sessf = dth.dns{d};
                for v = 1:2
                    obj.v = v;
                    FDGKineticsParc.pushDataToChpc(obj);
                    for p = 1:length(PARCS)
                        obj.parc = PARCS{p};
                        j = c.batch(@mlraichle.FDGKineticsWholebrain.godo2, 1, {obj});
                        jobs = [jobs j]; %#ok<AGROW>
                    end
                end
            end
            save('mlraichle_FDGKineticsParc_godoChpc_jobs', 'jobs');
            popd(pwd0);
        end
        function pushDataToChpc(obj)
        end
        function summary = godo2(obj)
            try
                import mlraichle.*;
                studyd = StudyData;
                assert(strcmp(studyd.subjectsFolder, 'jjlee'));
                vloc = fullfile(studyd.subjectsDir, obj.sessf, sprintf('V%i', obj.v), '');
                assert(isdir(vloc));
                sessd = SessionData('studyData', studyd, 'sessionPath', fileparts(vloc));
                sessd.vnumber = obj.v;
                sessd.attenuationCorrected = true;

                [m,sessd] = FDGKineticsParc.godoMasks(obj);
                sessd.selectedMask = ''; %% KLUDGE
                pwd0 = pushd(vloc);
                summary.(m.fileprefix) = FDGKineticsParc.doBayes(sessd, m);
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        function [summary,these] = godo(obj)
            try
                sessf = obj.sessf;
                v = obj.v;

                import mlraichle.*;
                studyd = StudyData;
                assert(strcmp(studyd.subjectsFolder, 'jjlee'));
                vloc = fullfile(studyd.subjectsDir, sessf, sprintf('V%i', v), '');
                assert(isdir(vloc));
                sessd = SessionData('studyData', studyd, 'sessionPath', fileparts(vloc));
                sessd.vnumber = v;
                sessd.attenuationCorrected = true;
                
                these = cell(1, length(FDGKineticsParc.PARCS));
                for p = 1:length(FDGKineticsParc.PARCS)
                    obj.parc = FDGKineticsParc.PARCS{p};
                    [m,sessd] = FDGKineticsParc.godoMasks(obj);
                    sessd.selectedMask = ''; %% KLUDGE
                    pwd0 = pushd(vloc);
                    [these{p},summary.(m.fileprefix)] = FDGKineticsParc.doBayes(sessd, m);
                    popd(pwd0);
                end
            catch ME
                handwarning(ME);
            end
        end
        function [m,sessd,ct4rb] = godoMasks(obj)
            import mlraichle.*;
            [sessd,ct4rb] = FDGKineticsWholebrain.godoMasks(obj);            
            pwd0 = pushd(sessd.vLocation); 
            if (strcmp(obj.parc(1), 'y'))
                m = FDGKineticsParc.yeoMask(sessd, obj.parc);
            else
                m = FDGKineticsParc.aparcAseg(sessd, ct4rb, obj.parc);
            end
            popd(pwd0);
        end
        function [this,summary]  = doBayes(sessd, mask)
            tic
            
            assert(isa(sessd, 'mlraichle.SessionData'));
            import mlpet.* mlraichle.*;
            this = FDGKineticsParc(sessd, 'mask', mask);
            this.showAnnealing = false;
            this.showBeta      = false;
            this.showPlots     = false;
            this               = this.estimateParameters;
            %this.plot;
            
            save('this_mlraichle_FDGKineticsParc_doBayes', 'this');              
            lg = mlpipeline.Logger(sprintf('FDGKineticsParc_godo_%s_V%i_%s', sessd.sessionFolder, sessd.vnumber, mask.fileprefix));
            kmin = this.kmin;
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            lg.add('\n%s is working in %s\n', mfilename, sessd.vLocation);
            lg.add('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(kmin));
            lg.add('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));
            lg.add('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(100*this.v1*kmin(1)));
            lg.add('CMRglu/[glu] = V_B chi / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str((this.v1/0.0105)*k1k3overk2k3));
            lg.add('mask.count -> %i\n', mask.count);
            lg.add('\n');
            lg.save;          
            
            summary.bestFitParams = this.bestFitParams;
            summary.meanParams = this.meanParams;
            summary.stdParams  = this.stdParams;
            summary.kmin = kmin;
            summary.chi = k1k3overk2k3;
            summary.Kd = 100*this.v1*kmin(1);
            summary.CMR = (this.v1/0.0105)*k1k3overk2k3;
            summary.maskCount = mask.count;
            
            toc
        end
        
        function aa = aparcAseg(sessd, ct4rb, parc)
            if (~lexist('aparcAseg_op_fdg.4dfp.ifh', 'file'))
                aa = sessd.aparcAseg('typ', 'mgz');
                aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
                aa = mybasename(aa);
                sessd.nifti_4dfp_4(aa);
                aa = ct4rb.t4img_4dfp(sessd.brainmask('typ','fp'), aa, 'opts', '-n');
                aa = mlfourd.ImagingContext([aa '.4dfp.ifh']);
                nn = aa.numericalNiftid;
                aa.saveas(['aparcAseg_' ct4rb.resolveTag '.4dfp.ifh']);
            else                
                aa = mlfourd.ImagingContext('aparcAseg_op_fdg.4dfp.ifh');
                nn = aa.numericalNiftid;
            end
            
            ids = mlraichle.FDGKineticsParc.(parc);
            nn  = (nn == ids(1)) + (nn == ids(2));
            nn  = nn.binarized;
            nn.fileprefix = [nn.fileprefix '_' parc];
            aa  = mlfourd.ImagingContext(nn);
        end
        function ym = yeoMask(sessd, parc)
            %% YEOMASK creates masks in memory only
                       
            import mlraichle.*;
            [mat_mni,ct4rb_mni,bmNii] = FDGKineticsParc.resolveMNI152(sessd);
            y                         = FDGKineticsParc.resolveYeo7(sessd, mat_mni, ct4rb_mni, bmNii); 
            nn                        = y.numericalNiftid;
            
            id = FDGKineticsParc.(parc);
            nn = (nn == id);
            nn = nn.binarized;
            nn.fileprefix = [nn.fileprefix '_' parc];
            ym = mlfourd.ImagingContext(nn);
        end
        function [mat,ct4rb,bmr2Nii] = resolveMNI152(sessd)
            fv = mlfourdfp.FourdfpVisitor;
            bmNii = fv.ensureSafeOp('brainmaskr2_op_fdg.nii.gz');
            bm = mybasename(bmNii);
            if (~lexist(bmNii, 'file'))
                sessd.mri_convert(sessd.brainmask('typ','mgz'), bmNii);
            end
            if (~lexist_4dfp(bm))
                sessd.nifti_4dfp_4(bm);
            end
                     
            fdgBrain = fv.ensureSafeOn([sessd.tracerResolvedSumt1('typ','fp') '_brain']); % created by FDGKineticsWholebrain.godoMasks?
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgBrain mybasename(bmNii)}, ...
                'resolveTag', 'op_fdg');            
            mni = fullfile(getenv('PPG'), 'jjlee2', 'FSL_MNI152_FreeSurferConformed_1mm.nii.gz');
            mniResolved = 'MNI152_op_fdg.nii.gz';
            bmr2Nii = [bm 'r2_op_fdg.nii.gz'];
            mat = [mybasename(mniResolved) '.mat'];
            if (lexist(mat, 'file') && ...
                lexist_4dfp(mybasename(bmr2Nii)) && ...
                lexist_4dfp(mybasename(mniResolved)))
                return
            end
            
            ct4rb.resolve;     
            
            sessd.nifti_4dfp_n(mybasename(bmr2Nii));
            mlbash(sprintf('flirt -in %s -ref %s -out %s -omat %s -cost normmi -dof 12', ...
                mni, bmr2Nii, mniResolved, mat)); 
            sessd.nifti_4dfp_4(mybasename(bmr2Nii));
            sessd.nifti_4dfp_4(mybasename(mniResolved));           
        end
        function y = resolveYeo7(~, mat, ~, bmr2Nii)
            ymni = fullfile(getenv('PPG'), 'jjlee2', 'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii.gz');
            yNii = 'Yeo7_op_fdg.nii.gz';
            
            mlbash(sprintf('flirt -in %s -ref %s -applyxfm -init %s -out %s', ymni, bmr2Nii, mat, yNii));  
            
            %sessd.nifti_4dfp_4(mybasename(yNii));            
            %y = ct4rb.t4img_4dfp(mybasename(bmNii), mybasename(yNii), 'opts', '-n');
            
            y = mlfourd.ImagingContext(yNii);
            y.fourdfp;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

