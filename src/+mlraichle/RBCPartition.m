classdef RBCPartition < mlkinetics.AbstractKinetics
	%% RBCPartition models fig. 8 of Phelps, Ann. Neurol., 1979 
    %  Tomographic measurement of local cerebral glucose metabolic rate in humans with (F‐18)2‐fluoro‐2‐deoxy‐D‐glucose: Validation of method
    %  with rbcOverPlasma = a0 + a1 t + a2(1 - exp(-t/tau)), time in min.  [18F]FDG only.
    
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.

	properties (Constant)
        a0 = 0.814104   % FINAL STATS param  a0 mean  0.814192	 std 0.004405
        a1 = 0.000680   % FINAL STATS param  a1 mean  0.001042	 std 0.000636
        a2 = 0.103307   % FINAL STATS param  a2 mean  0.157897	 std 0.110695
        tau = 50.052431 % FINAL STATS param tau mean  116.239401	 std 51.979195
    end

    properties        
        sessionData1
        xLabel = 'times/min'
        yLabel = 'RBC / plasma'
        notes
        sdpar
        
        tData = [0.551 1.444 2.082 2.858 2.01 1.248 0.559 0.755 1.074 1.654 1.973 2.481 2.611 3.192 3.961 3.772 4.867 4.867 6.942 9.792 12.084 14.848 19.786 25.129 29.684 40.119 49.846 59.311 65.98 69.421 79.62 99.048 109.949 119.793 139.749 145.454 159.177 179.486 191.654 200.437 205.729 219.901 245.03 238.684 272.48 258.255 279.179 287.906 285.555 298.016]
        rbcData = [0.852 0.852 0.838 0.787 0.79 0.795 0.799 0.812 0.812 0.812 0.812 0.807 0.811 0.821 0.808 0.838 0.826 0.845 0.845 0.853 0.861 0.87 0.915 0.875 0.908 0.869 0.892 0.865 0.939 0.909 0.946 0.999 0.942 1.015 0.912 0.971 1.062 1.002 1.066 0.98 1.03 1.075 1.063 1.139 1.079 1.152 1.029 1.105 1.149 1.208]
    end
    
    properties (Dependent)
        baseTitle1
        detailedTitle
        mapParams 
        parameters
    end
    
    methods %% GET
        function bt = get.baseTitle1(this)
            if (isempty(this.sessionData1))
                bt = sprintf('%s %s', class(this), pwd);
                return
            end
            bt = class(this);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\na0 %g, a1 %g, a2 %g, tau %g', ...
                         this.baseTitle, ...
                         this.a0, this.a1, this.a2, this.tau);
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            m('a0')  = struct('fixed', 0, 'min', 0, 'mean', this.a0,  'max', 1.208);  
            m('a1')  = struct('fixed', 0, 'min', 0, 'mean', this.a1,  'max', 1.208/298);
            m('a2')  = struct('fixed', 0, 'min', 0, 'mean', this.a2,  'max', 1.208);
            m('tau') = struct('fixed', 0, 'min', 3, 'mean', this.tau, 'max', 298);
        end
        function p  = get.parameters(this)
            p   = [this.finalParams('a0'), this.finalParams('a1'), this.finalParams('a2'), this.finalParams('tau')]; 
        end
    end
    
    methods (Static)
        function Cwb  = plasma2wb(Cp, hct, t, units)
            arguments
                Cp  % must be understood by mlfourd.ImagingContext2
                hct double {mustBeScalarOrEmpty}
                t double = []
                units {mustBeTextScalar} = "s" % h, m, s
            end
            Cp_ = mlfourd.ImagingContext2(Cp);
            if (hct > 1)
                hct = hct/100;
            end
            if isempty(t)
                if isfield(Cp_.json_metadata, "timesMid")
                    t = asrow(Cp_.json_metadata.timesMid);
                else
                    t = 0:length(Cp_.imagingFormat.img)-1;
                end
            end
            lambda_t = mlraichle.RBCPartition.rbcOverPlasma(t, units);
            if iscolumn(Cp_)
                lambda_t = ascolumn(lambda_t);
            end
            Cwb = Cp_.*(1 + hct*(lambda_t - 1));
            if isnumeric(Cp)
                Cwb = double(Cwb);
            end
        end  
        function rop = rbcOverPlasma(t, units)
            arguments
                t double {mustBeNonempty}
                units {mustBeTextScalar} = "s" % h, m, s
            end

            a0 = mlraichle.RBCPartition.a0;
            a1 = mlraichle.RBCPartition.a1;
            a2 = mlraichle.RBCPartition.a2;
            tau = mlraichle.RBCPartition.tau;
            switch units
                case "h"
                    t = 60*t;
                case "m"
                case "s"
                    t = t/60;
                otherwise
                    error("mlraichle:ValueError", "units->%s", units)
            end
            rop = mlraichle.RBCPartition.rbcOverPlasma_5param(a0, a1, a2, tau, t);
        end
        function rop = rbcOverPlasma_5param(a0, a1, a2, tau, t)
            rop = a0 + a1*t + a2*(1 - exp(-t/tau));
        end
        function Cp  = wb2plasma(Cwb, hct, t, units)
            arguments
                Cwb  % must be understood by mlfourd.ImagingContext2
                hct double {mustBeScalarOrEmpty}
                t double = []
                units {mustBeTextScalar} = "s" % h, m, s
            end
            Cwb_ = mlfourd.ImagingContext2(Cwb);
            if (hct > 1)
                hct = hct/100;
            end
            if isempty(t)
                if isfield(Cwb_.json_metadata, "timesMid")
                    t = asrow(Cwb_.json_metadata.timesMid);
                else
                    t = 0:length(Cwb_.imagingFormat.img)-1;
                end
            end
            lambda_t = mlraichle.RBCPartition.rbcOverPlasma(t, units);
            if iscolumn(Cwb_)
                lambda_t = ascolumn(lambda_t);
            end
            Cp = Cwb_./(1 + hct*(lambda_t - 1));
            if isnumeric(Cwb)
                Cp = double(Cp);
            end
        end
    end
    
	methods
 		function this = RBCPartition()
 			%% RBCPartition
 			%  Usage:  this = RBCPartition() 			
 			
 			this = this@mlkinetics.AbstractKinetics();
            
            [this.tData, I] = sort(this.tData);
            this.rbcData = this.rbcData(I);
            %[~,idxHour] = max(this.tData > 60);
            %this.tData = this.tData(1:idxHour);
            %this.rbcData = this.rbcData(1:idxHour);
            
            %this.independentData = {ensureRowVector(this.tData)};
            %this.dependentData   = {ensureRowVector(this.rbcData)};
            
            this.showPlots = true;
            this.showAnnealing = true;
            this.showBeta = true;
            %this.expectedBestFitParams = ...
            %    [this.a0 this.a1 this.a2 this.tau]';
        end
        
        function rop = itsRbcOverPlasma(this)
            import mlraichle.*;            
            rop = RBCPartition.rbcOverPlasma_5param(this.a0, this.a1, this.a2, this.tau, this.tData);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            this = this.runMcmc(ip.Results.mapParams, 'keysToVerify', {'a0' 'a1' 'a2' 'tau'});
            this.sdpar = this.annealingSdpar;
        end
        function ed   = estimateDataFast(this, a0, a1, a2, tau)
            import mlraichle.*;            
            ed{1} = RBCPartition.rbcOverPlasma_5param(a0, a1, a2, tau, this.tData);
        end        
        function plot(this, varargin)
            figure;
            plot(this.tData, this.rbcData, '-o',  ...
                 this.tData, this.itsRbcOverPlasma, varargin{:});
            legend('rbcData', 'Bayesian rbcOverPlasma');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
        function prepareScannerData(this)
        end
        function prepareAifData(this)
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

