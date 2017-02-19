classdef FDGKineticsWholebrain < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSWHOLEBRAIN  

	%  $Revision$
 	%  was created 17-Feb-2017 07:19:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = FDGKineticsWholebrain(varargin)
 			%% FDGKINETICSWHOLEBRAIN
 			%  Usage:  this = FDGKineticsWholebrain()

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
            [~,ic] = FDGKineticsWholebrain.mskt(sessd);
            sessd.selectedMask = ic.fqfn;
            this = FDGKineticsWholebrain.run(sessd);
        end
        function this = run(sessd)
            tic
            assert(isa(sessd, 'mlraichle.SessionData'));
            cd(sessd.vLocation);
            import mlpet.* mlraichle.*;
            this = FDGKineticsWholebrain(sessd);
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
            save('this_mlraichle_FDGKineticsWholebrain_runWholebrain', 'this')
            toc
        end
        
        function [m,n] = mskt(sessd)
            import mlfourdfp.*;
            f = [sessd.tracerResolved1('typ','fqfp') '_sumt'];
            f1 = mybasename(FourdfpVisitor.ensureSafeOn(f));
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
            fnii = fdgSumt.numericalNiftid;
            msktNorm = mlfourd.ImagingContext(msktNorm);
            mnii = msktNorm.numericalNiftid;
            fnii = fnii.*mnii;
            fdgSumt = mlpet.PETImagingContext(fnii);
            fdgSumt.filepath = pwd;
            fdgSumt.fileprefix = [sessd.tracerResolvedSumt1('typ','fp') '_brain'];
            fdgSumt.filesuffix = '.4dfp.ifh';
            fdgSumt.save;
            
            brainmask = mlfourd.ImagingContext(sessd.brainmask);
            brainmask.fourdfp;
            brainmask.filepath = pwd;
            brainmask.save;
            
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, 'theImages', {fdgSumt.fileprefix brainmask.fileprefix});
            ct4rb = ct4rb.resolve;
            b = ct4rb.product{2};
            b.numericalNiftid;
            b = b.binarizeBlended;
            b.saveas(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

