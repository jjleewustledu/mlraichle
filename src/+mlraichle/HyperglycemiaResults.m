classdef HyperglycemiaResults < mlglucose.AbstractSolvedResults
	%% HYPERGLYCEMIARESULTS composites mlhemodynamics.HemodynamicsDirector and mlglucose.GlucoseKineticsDirector,
    %  providing separable construction and get-product methods.  HemodynamicsDirector is configured with:
    %      mloxygen.OxygenBuilder,
    %      mlpet.IScannerDataBuilder, 
    %      mlpet.IAifDataBuilder, 
    %      mlraichle.BlindedData, 
    %      mloxygen.OxygenModel.
    %  GlucoseKineticsDirector is configured with:
    %      mlglucose.GlucoseKineticsBuilder,
    %      mlpet.IScannerDataBuilder, 
    %      mlpet.IAifDataBuilder, 
    %      mlraichle.BlindedData, 
    %      mlglucose.F18DeoxyGlucoseKineticsBuilder.
    %  The ctor specifies run-time-specific configurations for session data, solver, ROIs.   
    %  HyperglycemiaResults is the client of a builder design pattern.  It creates results needed for publications.   

	%  $Revision$
 	%  was created 04-Dec-2017 12:16:42 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
    
	methods 
        
        %%
		  
        function this = constructSelfTest(this, varargin)
            ip = inputParser;
            addOptional(ip, 'variety', 'glucose', @ischar);
            parse(ip, varargin{:});
            
            this.useSynthetic = true;
            switch (ip.Results.variety)
                case 'oxygen'
                    this = this.constructOxygenMetrics;
                case 'glucose'
                    this = this.constructGlucoseMetrics;
                case 'mutual'
                    this = this.constructMutualMetrics;
                otherwise
                    error('mlraichle:unsupportedSwitchCase', ...
                        'constructSelfTest.ip.Results.variety->%s', ip.Results.variety);
            end
        end
        function this = constructOxygenMetrics(this)
            this.oxygenDirector_ = this.oxygenDirector_.constructCbf;
            this.oxygenDirector_ = this.oxygenDirector_.constructCbv;
            this.oxygenDirector_ = this.oxygenDirector_.constructOef;
            this.oxygenDirector_ = this.oxygenDirector_.constructPhysiological;
        end
        function this = constructGlucoseMetrics(this)
            this.glucoseDirector_ = this.glucoseDirector_.constructRates;
            this.glucoseDirector_ = this.glucoseDirector_.constructPhysiological;
        end
        function this = constructMutualMetrics(this)
            this.glucoseDirector_.oxygenDirector = this.oxygenDirector_;
            this = this.constructGlucoseMetrics;
            this.oxygenDirector_ = this.glucoseDirector_.this.oxygenDirector;
        end
        function prd  = getOxygenMetrics(this)
            prd = this.oxygenDirector_.product;
        end
        function prd  = getGlucoseMetrics(this)
            prd = this.glucoseDirector_.product;
        end
        
 		function this = HyperglycemiaResults(varargin)
 			%% HYPERGLYCEMIARESULTS
 			%  @param sessionData is an mlraichle.SessionData
 			%  @param solver is an mlkinetics.IKineticsSolver
 			%  @param roisBuilder is an mlrois.IRoisBuilder
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'));
            addParameter(ip, 'solver',      @(x) isa(x, 'mlkinetics.IKineticsSolver'));
            addParameter(ip, 'roisBuilder', @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessd = ipr.sessionData;
            solver = ipr.solver;
            
            import mlsiemens.* mloxygen.*;
            sessd.tracer = {'HO' 'OC' 'OO'};
            calb   = CalibrationBuilder('sessionData', sessd);
            blindd = mlraichle.BlindedData('sessionData', sessd);
            scanb  = BiographMMRBuilder('sessionData', sessd, ...
                'roisBuilder', ipr.roisBuilder, ...
                'calibrationBuilder', calb, ...
                'blindedData', blindd);
            twilb  = mlswisstrace.TwiliteBuilder('sessionData', sessd, ...
                'dtNyquist', this.DT_NYQUIST, ...
                'calibrationBuilder', calb);
            oxy = OxygenModel( ...
                'scannerBuilder', scanb, 'aifBuilder', twilb, 'blindedData', blindd, ...
                'solverClass', class(solver), ...
                'sessionData', sessd, ...
                'dtNyquist', this.DT_NYQUIST); % solver as argument is awkward
            solver.model = oxy;
            this.oxygenDirector_ = OxygenDirector( ...
                OxygenBuilder('solver', solver));
            
            import mlglucose.*;
            sessd.tracer = 'FDG';
            calb   = CalibrationBuilder('sessionData', sessd);
            blindd = mlraichle.BlindedData('sessionData', sessd);
            scanb  = BiographMMRBuilder('sessionData', sessd, ...
                'roisBuilder', ipr.roisBuilder, ...
                'calibrationBuilder', calb, ...
                'blindedData', blindd);
            wellb  = mlcapintec.CapracBuilder('sessionData', sessd, ...
                'dtNyquist', this.DT_NYQUIST, ...
                'calibrationBuilder', calb);
            fdg    = F18DeoxyGlucoseModel( ...
                'scannerBuilder', scanb, 'aifBuilder', wellb, 'blindedData', blindd, ...
                'solverClass', class(solver), ...
                'sessionData', sessd, ...
                'dtNyquist', this.DT_NYQUIST); % solver as argument is awkward
            solver.model = fdg;
            this.glucoseDirector_ = GlucoseKineticsDirector( ...
                F18DeoxyGlucoseKineticsBuilder('solver', solver));
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

