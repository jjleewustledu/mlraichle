classdef FDGKineticsWholebrain < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSWHOLEBRAIN  

	%  $Revision$
 	%  was created 17-Feb-2017 07:19:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties (Constant)
        REUSE_APARCASEG = true
 		REUSE_BRAINMASK = true
 	end

	methods 
		  
 		function this = FDGKineticsWholebrain(varargin)
 			%% FDGKINETICSWHOLEBRAIN
 			%  Usage:  this = FDGKineticsWholebrain()

 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
 		end
    end 

    methods (Static)
        function j = godoChpc
            pwd0 = pushd(fullfile(getenv('PPG'), 'jjlee', ''));
            load('hyglys.mat');
            c = parcluster;
            for h = 1:8
                j = c.batch(@mlraichle.FDGKineticsWholebrain.godo, 1, {hyglys{h}}); %#ok<USENS>
            end
            popd(pwd0);
        end
        function [summary,this] = godo(obj)
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
                
                sessd = FDGKineticsWholebrain.godoMasks(obj);

                pwd0 = pushd(vloc);
                [this,summary] = FDGKineticsWholebrain.doBayes(sessd);
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        function [sessd,ct4rb] = godoMasks(obj)
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

                pwd0 = pushd(vloc);
                [~,msktn] = FDGKineticsWholebrain.mskt(sessd);
                [~,ct4rb] = FDGKineticsWholebrain.brainmaskBinarized(sessd, msktn);                
                aa = FDGKineticsWholebrain.aparcAsegBinarized(sessd, ct4rb);
                sessd.selectedMask = [aa.fqfp '.4dfp.ifh'];
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        function [this,summary] = doBayes(sessd)
            tic
            assert(isa(sessd, 'mlraichle.SessionData'));
            cd(sessd.vLocation);
            import mlpet.* mlraichle.*;
            this = FDGKineticsWholebrain(sessd);
            this.showAnnealing = true;
            this.showBeta      = true;
            this.showPlots     = false;
            this               = this.estimateParameters;
            this.plot;            
            save('this_mlraichle_FDGKineticsWholebrain_doBayes', 'this');   
            
            kmin = this.kmin;
            summary.bestFitParams = this.bestFitParams;
            summary.meanParams = this.meanParams;
            summary.stdParams  = this.stdParams;
            summary.kmin = kmin;
            summary.chi = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            summary.Kd = 100*this.v1*kmin(1);
            summary.CMR = (this.v1/0.0105)*summary.chi;
            summary.free = summary.CMR/(100*kmin(3));            
            
            lg = mlpipeline.Logger(sprintf('FDGKineticsWholebrain_godo_%s_V%i', sessd.sessionFolder, sessd.vnumber));
            lg.add('\n%s is working in %s\n', mfilename, sessd.vLocation);
            lg.add('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(summary.kmin));
            lg.add('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(summary.chi));
            lg.add('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(summary.Kd));
            lg.add('CMRglu/[glu] = V_B chi / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(summary.CMR));
            lg.add('free glu/[glu] = CMRglu/(100 k3) -> %s\n', mat2str(summary.free));
            lg.add('\n');
            lg.save;
            
            toc
        end        
        function [m,n] = mskt(sessd)
            import mlfourdfp.*;
            f = [sessd.tracerResolved1('typ','fqfp') '_sumt'];
            f1 = mybasename(FourdfpVisitor.ensureSafeOn(f));
            if (lexist([f1 '_mskt.4dfp.ifh'], 'file') && lexist([f1 '_msktNorm.4dfp.ifh'], 'file'))
                m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
                n = mlfourd.ImagingContext([f1 '_msktNorm.4dfp.ifh']);
                return
            end
            
            lns_4dfp(f, f1);
            
            ct4rb = CompositeT4ResolveBuilder('sessionData', sessd);
            ct4rb.msktgenImg(f1);          
            m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
            n = m.numericalNiftid;
            n.img = n.img/n.dipmax;
            n.fileprefix = [f1 '_msktNorm'];
            n.filesuffix = '.4dfp.ifh';
            n.save;
            n = mlfourd.ImagingContext(n);
        end
        function [b,ct4rb] = brainmaskBinarized(sessd, msktNorm)
            fdgSumt = mlpet.PETImagingContext(sessd.tracerResolvedSumt1('typ','fqfn'));
            if (~lexist([sessd.tracerResolvedSumt1('typ','fp') '_brain.4dfp.ifh'], 'file'))
                fnii = fdgSumt.numericalNiftid;
                msktNorm = mlfourd.ImagingContext(msktNorm);
                mnii = msktNorm.numericalNiftid;
                fnii = fnii.*mnii;
                fdgSumt = mlpet.PETImagingContext(fnii);
                fdgSumt.filepath = pwd;
                fdgSumt.fileprefix = [sessd.tracerResolvedSumt1('typ','fp') '_brain'];
                fdgSumt.filesuffix = '.4dfp.ifh';
                fdgSumt.save;
            end
            
            brainmask = mlfourd.ImagingContext(sessd.brainmask);
            if (~lexist('brainmask.4dfp.ifh', 'file'))
                brainmask.fourdfp;
                brainmask.filepath = pwd;
                brainmask.save;
                if (lexist('brainmask.nii')); gzip('brainmask.nii'); end
            end
            
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgSumt.fileprefix brainmask.fileprefix});
            if (mlraichle.FDGKineticsWholebrain.REUSE_BRAINMASK && ...
                lexist(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh'], 'file'))
                b = mlpet.PETImagingContext(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
                return
            end
            ct4rb = ct4rb.resolve;
            b = ct4rb.product{2};
            b.numericalNiftid;
            b.saveas(['brainmask_' ct4rb.resolveTag '.4dfp.ifh']);
            b = b.binarizeBlended;
            b.saveas(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
        end
        function aa = aparcAsegBinarized(sessd, ct4rb)
            if (mlraichle.FDGKineticsWholebrain.REUSE_APARCASEG && ...
                lexist('aparcAsegBinarized_op_fdg.4dfp.ifh', 'file'))
                aa = mlpet.PETImagingContext('aparcAsegBinarized_op_fdg.4dfp.ifh');
                return
            end
            
            aa = sessd.aparcAseg('typ', 'mgz');
            aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
            aa = mybasename(aa);
            sessd.nifti_4dfp_4(aa);
            aa = ct4rb.t4img_4dfp( ...
                sessd.brainmask('typ','fp'), aa, 'opts', '-n');
            aa = mlpet.PETImagingContext([aa '.4dfp.ifh']);
            nn = aa.numericalNiftid;
            nn.saveas(['aparcAseg_' ct4rb.resolveTag '.4dfp.ifh']);
            nn = nn.binarized; % set threshold to intensity floor
            nn.saveas(['aparcAsegBinarized_' ct4rb.resolveTag '.4dfp.ifh']);
            aa = mlfourd.ImagingContext(nn);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

