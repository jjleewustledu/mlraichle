classdef F18DeoxyGlucoseKinetics < mlkinetics.AbstractF18DeoxyGlucoseKinetics
	%% F18DEOXYGLUCOSEKINETICS  
    
	%  $Revision$
 	%  was created 21-Jan-2016 16:55:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
 	
    %% SAMPLE, REASONABLE OUTPUT
    %  
    %%

	properties                
        LC = 0.64 % Powers PNAS 2007
        notes = ''
        xLabel = 'times/s'
        yLabel = 'activity / (Bq / cc)'
        
        capracEfficiency = 1 % 171.2/248.6
    end
    
    methods (Static)        
        function this = simulateMcmc(Aa, fu, k1, k2, k3, k4, t, u0, v1, mapParams)
            import mlraichle.*;
            qpet = F18DeoxyGlucoseKinetics.qpet(Aa, fu, k1, k2, k3, k4, t, v1);
            qpet = F18DeoxyGlucoseKinetics.pchip(t, qpet, t, u0);
            dta_ = struct('times', t, 'specificActivity', Aa);
            tsc_ = struct('times', t, 'specificActivity', qpet);
            this = F18DeoxyGlucoseKinetics(sessd, 'hct', 40, 'dta', dta_, 'tsc', tsc_);
            this.mapParams = mapParams;
            [this,lg] = this.doBayes;
            fprintf('%s\n', char(lg));
        end
    end
    
	methods
 		function this = F18DeoxyGlucoseKinetics(varargin)
 			%% F18DEOXYGLUCOSEKINETICS
 			%  Usage:  this = F18DeoxyGlucoseKinetics() 			
 			
 			this = this@mlkinetics.AbstractF18DeoxyGlucoseKinetics(varargin{:});
        end
        
        function this = prepareTsc(this)
            this.sessionData.tracer = 'FDG';
            pic = mlpet.PETImagingContext( ...
                [this.sessionData.fdgACRevision('typ','fqfp') '_on_resolved.4dfp.ifh']);
            mmr = mlsiemens.BiographMMR(pic.niftid, ...
                'sessionData', this.sessionData);
            num = mlfourd.NumericalNIfTId(mmr.component);
            msk = mlfourd.MaskingNIfTId(this.mask.niftid);
            num = num.masked(msk);
            num = num.volumeSummed;
            num.img = num.img/msk.count;
            num.img = ensureRowVector(num.img);
            mmr.img = num.img;
            mmr.fileprefix = [mmr.fileprefix '_tsc'];
            this.tsc_ = mmr;
        end
        function this = prepareDta(this)
            dta = mlpet.Caprac('scannerData', this.tsc, 'efficiencyFactor', this.capracEfficiency);
            dta.specificActivity = mlraichle.F18DeoxyGlucoseKinetics.wb2plasma(dta.specificActivity, this.hct, dta.times);
            this.dta_ = dta;
        end        
        function this = simulateItsMcmc(this)
            this = mlraichle.F18DeoxyGlucoseKinetics.simulateMcmc( ...
                   this.dtaNyquist.specificActivity, ...
                   this.fu, this.k1, this.k2, this.k3, this.k4, ...
                   this.dtaNyquist.times, this.u0, this.v1, this.mapParams);
        end

 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

