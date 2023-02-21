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
        LC = 0.64 % Powers, et al., JCBFM 31(5) 1223-1228, 2011.
        %LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
        notes = ''
        xLabel = 'times/s'
        yLabel = 'activity/(Bq/mL)'
        
        capracEfficiency = 1 % 171.2/248.6
    end
    
    methods (Static)
        function that = constructKinetics(varargin)
            %% GOCONSTRUCTKINETICS
            %  @param optional 'roisBuild' is a 'mlrois.IRoisBuilder'.
            %  @returns 'that' which is 'mlraichle.FDGKineticsWholebrain' or 'mlraichle.FDGKineticsParc'.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', [], @(x) isa(x, 'mlrois.IRoisBuilder'));
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            import mlraichle.*;
            if (isa(ip.Results.rois, 'mlrois.Wholebrain'))
                that = FDGKineticsWholebrain.constructKinetics('sessionData', ip.Results.sessionData);
                return
            end            
            that = FDGKineticsParc.constructKinetics('sessionData', ip.Results.sessionData);
        end
        function this = simulateMcmc(Aa, fu, k1, k2, k3, k4, t, u0, v1, mapParams)
            import mlraichle.*;
            qpet = qFDG(Aa, fu, k1, k2, k3, k4, t, v1);
            qpet = F18DeoxyGlucoseKinetics.pchip(t, qpet, t, u0);
            dta_ = struct('times', t, 'specificActivity', Aa);
            tsc_ = struct('times', t, 'specificActivity', qpet);
            this = F18DeoxyGlucoseKinetics(sessd, 'dta', dta_, 'tsc', tsc_);
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
        
        function this = prepareScannerData(this)
            mand = mlsiemens.XlsxObjScanData('sessionData', this.sessionData);
            this.sessionData.tracer = 'FDG';
            pic = mlpet.PETImagingContext(this.sessionData.tracerResolvedFinal);
            mmr = mlsiemens.BiographMMR0( ...
                pic.niftid, ...
                'sessionData', this.sessionData, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('[18F]DG'), ...
                'manualData', mand);
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
        function this = prepareAifData(this)
            mand = mlsiemens.XlsxObjScanData('sessionData', this.sessionData);
            dta = mlcapintec.Caprac( ...
                'fqfilename', this.sessionData.CCIRRadMeasurements, ...
                'sessionData', this.sessionData, ...
                'scannerData', this.tsc, ...
                'invEfficiency', this.capracEfficiency, ...
                'isotope', '18F', ...
                'manualData', mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('[18F]DG'));
            dta = dta.correctedActivities(0);
            this.dta_ = dta;
        end        
        function this = simulateItsMcmc(this)
            this = mlraichle.F18DeoxyGlucoseKinetics.simulateMcmc( ...
                   this.arterialNyquist.specificActivity, ...
                   this.fu, this.k1, this.k2, this.k3, this.k4, ...
                   this.arterialNyquist.times, this.u0, this.v1, this.mapParams);
        end

 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

