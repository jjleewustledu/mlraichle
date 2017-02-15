classdef F18DeoxyGlucoseKinetics < mlkinetics.AbstractKinetics & mlkinetics.F18
	%% F18DEOXYGLUCOSEKINETICS  

	%  $Revision$
 	%  was created 21-Jan-2016 16:55:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
        fu = 1.8903 % FUDGE stdev.s -> 0.4089
        % Joanne Markham used the notation K_1 = V_B*k_{21}, rate from compartment 1 to 2.
        % Mean values from Powers xlsx "Final Normals WB PET PVC & ETS"
        k1 = 3.946/60
        k2 = 0.3093/60
        k3 = 0.1862/60
        k4 = 0 % 0.01382/60
        u0 = 4.038 % for tscCounts
        v1 = 0.0190
        
        sk1 = 1.254/60
        sk2 = 0.4505/60
        sk3 = 0.1093/60
        sk4 = 0.004525/60
        
        sessionData
        Ca     
        xLabel = 'times/s'
        yLabel = 'activity'
        notes
        
        dta
        dtaNyquist
        dtaOnTsc
        tsc
        tscNyquist
    end
    
    properties (Dependent)
        baseTitle
        detailedTitle
        mapParams 
        parameters
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            if (isempty(this.sessionData))
                bt = sprintf('%s %s', class(this), pwd);
                return
            end
            bt = sprintf('%s %s', class(this), this.sessionData.sessionFolder);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nfu %g, k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g\n%S', ...
                         this.baseTitle, ...
                         this.fu, this.k1, this.k2, this.k3, this.k4, this.u0, this.v1, this.notes);
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            N = 5;
            
            % From Powers xlsx "Final Normals WB PET PVC & ETS"
            m('fu') = struct('fixed', 1, 'min', 1e-2,                              'mean', this.fu, 'max', 1e2);  
            m('k1') = struct('fixed', 0, 'min', max(1.4951/60    - N*this.sk1, 0), 'mean', this.k1, 'max',   6.6234/60   + N*this.sk1);
            m('k2') = struct('fixed', 0, 'min', max(0.04517/60   - N*this.sk2, 0), 'mean', this.k2, 'max',   1.7332/60   + N*this.sk2);
            m('k3') = struct('fixed', 0, 'min', max(0.05827/60   - N*this.sk3, 0), 'mean', this.k3, 'max',   0.41084/60  + N*this.sk3);
            m('k4') = struct('fixed', 1, 'min', max(0.0040048/60 - N*this.sk4, 0), 'mean', this.k4, 'max',   0.017819/60 + N*this.sk4);
            m('u0') = struct('fixed', 0, 'min', 0,                                 'mean', this.u0, 'max', 100);  
            m('v1') = struct('fixed', 1, 'min', 0.01,                              'mean', this.v1, 'max',   0.1);  
        end
        function p  = get.parameters(this)
            p   = [this.finalParams('fu'), this.finalParams('k1'), this.finalParams('k2'), ...
                   this.finalParams('k3'), this.finalParams('k4'), this.finalParams('u0'), this.finalParams('v1')]; 
        end
    end
    
    methods (Static)
        function [this,kmin,k1k3overk2k3] = runWholebrain(sessd)
            tic
            cd(sessd.sessionPath);
            import mlpet.* mlraichle.*;            
            this = F18DeoxyGlucoseKinetics(sessd);
            this.v1            = sessd.v1;
            this.k1            = sessd.k1;
            this.k2            = sessd.k2;
            this.k3            = sessd.k3;
            this.k4            = sessd.k4;
            this.showAnnealing = true;
            this.showBeta      = true;
            this.showPlots     = true;
            this               = this.estimateParameters;
            this.plot;
            
            kmin         = 60*[this.k1 this.k2 this.k3 this.k4];
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            fprintf('\n%s is working in %s\n', mfilename, sessd.sessionPath);
            fprintf('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(kmin));
            fprintf('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));
            fprintf('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(100*this.v1*kmin(1)));
            fprintf('CMRglu/[glu] = V_B chi / mL min^{-1} (100g)^{-1} -> %s\n', mat2str((this.v1/0.0105)*k1k3overk2k3));
            fprintf('\n');
            toc
        end
        function [outputs,studyDat,sessDats] = loopChpc(N)
            assert(isnumeric(N));
            studyDat = mlraichle.StudyDataSingleton.instance; 
            iter = studyDat.createIteratorForSessionData;            
            outputs = cell(1,N);            
            sessDats = cell(1,N);
            n = 0;
            while (iter.hasNext && n < N)
                try
                    n = n + 1;
                    sessDats{n} = iter.next;
                    fprintf('%s:  n->%i, %s\n', mfilename, n, sessDats{n}.sessionPath);
                catch ME
                    handwarning(ME);
                end
            end
                    
            parfor p = 1:N 
                try
                    [outputs{p}.fdgk,outputs{p}.kmin,outputs{p}.k1k3overk2k3] = mlraichle.F18DeoxyGlucoseKinetics.runPowers(sessDats{p});
                    saveFigures(fullfile(sessDats{p}.sessionPath, sprintf('fig_%s', datestr(now,30)), ''));
                    %studyDat = mlpipeline.StudyDataSingletons.instance('powers');
                    %studyDat.saveWorkspace(sessDats{p}.sessionPath);
                catch ME
                    handwarning(ME);
                end
            end
        end
        function [outputs,studyDat,sessDats] = loopSessionsLocally(N)
            assert(isnumeric(N));
            studyDat = mlraichle.StudyDataSingleton.instance;            
            iter = studyDat.createIteratorForSessionData;            
            outputs = cell(1,N);            
            sessDats = cell(1,N);
            n = 0;
            while (iter.hasNext && n < N)
                try
                    n = n + 1;
                    sessDats{n} = iter.next;
                    fprintf('%s:  n->%i, %s\n', mfilename, n, sessDats{n}.sessionPath);
                catch ME
                    handwarning(ME);
                end
            end
                    
            for p = 1:N  
                try
                    %studyDat.diaryOn(sessDats{p}.sessionPath);
                    [outputs{p}.fdgk,outputs{p}.kmin,outputs{p}.k1k3overk2k3] = mlraichle.F18DeoxyGlucoseKinetics.runPowers(sessDats{p});
                    saveFigures(fullfile(sessDats{p}.sessionPath, sprintf('fig_%s', datestr(now,30)), ''));
                    %studyDat = mlpipeline.StudyDataSingletons.instance('powers');
                    %studyDat.saveWorkspace(sessDats{p}.sessionPath);
                    %studyDat.diaryOff;
                catch ME
                    handwarning(ME);
                end
            end
        end
        function alpha_ = a(k2, k3, k4)
            k234   = k2 + k3 + k4;
            alpha_ = k234 - sqrt(k234^2 - 4*k2*k4);
            alpha_ = alpha_/2;
        end
        function beta_  = b(k2, k3, k4)
            k234  = k2 + k3 + k4;
            beta_ = k234 + sqrt(k234^2 - 4*k2*k4);
            beta_ = beta_/2;
        end
        function q      = q2(Ca, k1, a, b, k4, t)
            scale = k1/(b - a);
            q = scale * conv((k4 - a)*exp(-a*t) + (b - k4)*exp(-b*t), Ca);
            q = q(1:length(t));
        end
        function q      = q3(Ca, k1, a, b, k3, t)
            scale = k3*k1/(b - a);
            q = scale * conv(exp(-a*t) - exp(-b*t), Ca);
            q = q(1:length(t));
        end
        function q      = qpet(Ca, fu, k1, k2, k3, k4, t, v1)
            import mlraichle.*;
            Ca = fu*v1*Ca;
            a  = F18DeoxyGlucoseKinetics.a(k2, k3, k4);
            b  = F18DeoxyGlucoseKinetics.b(k2, k3, k4);
            q  = F18DeoxyGlucoseKinetics.q2(Ca, k1, a, b, k4, t) + ...
                 F18DeoxyGlucoseKinetics.q3(Ca, k1, a, b, k3, t) + ...
                 Ca;
        end
        function this   = simulateMcmc(Ca, fu, k1, k2, k3, k4, t, u0, v1, mapParams)
            import mlraichle.*;
            qpet = F18DeoxyGlucoseKinetics.qpet(Ca, fu, k1, k2, k3, k4, t, v1);
            qpet = F18DeoxyGlucoseKinetics.pchip(t, qpet, t, u0);
            dta_ = struct('times', t, 'specificActivity', Ca);
            tsc_ = struct('times', t, 'specificActivity', qpet);
            this = F18DeoxyGlucoseKinetics(dta_, tsc_);
            this.showAnnealing = true;
            this.showBeta = true;
            this.showPlots = true;
            this = this.estimateParameters(mapParams) %#ok<NOPRT>
            this.plot;
            
            kmin         = 60*[this.k1 this.k2 this.k3 this.k4];
            k1k3overk2k3 = kmin(1)*kmin(3)/(kmin(2) + kmin(3));
            fprintf('\n%s is working in %s\n', mfilename, sessDat.sessionPath);
            fprintf('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(kmin));
            fprintf('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(k1k3overk2k3));
            fprintf('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(100*this.v1*kmin(1)));
            fprintf('CMRglu/[glu] = V_B chi / mL min^{-1} (100g)^{-1} -> %s\n', mat2str((this.v1/0.0105)*k1k3overk2k3));
            fprintf('\n');
        end
        function conc   = pchip(t, conc, t_, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t_ - Dt);
            %  Dt > 0 will slide conc(t) towards lower values of t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            %  @param t    is the initial t    sampling
            %  @param conc is the initial conc sampling
            %  @param t_   is the final        sampling
            %  @param Dt   is the shift of t_
            
            tspan = t(end) - t(1);
            tinc  = t(2) - t(1);
            t     = [(t - tspan - tinc) t];   % prepend times
            conc  = [zeros(size(conc)) conc]; % prepend zeros
            conc  = pchip(t, conc, t_ - Dt); % interpolate onto t shifted by Dt; Dt > 0 shifts to right
        end
    end
    
	methods
 		function this = F18DeoxyGlucoseKinetics(varargin)
 			%% F18DEOXYGLUCOSEKINETICS
 			%  Usage:  this = F18DeoxyGlucoseKinetics() 			
 			
 			this = this@mlkinetics.AbstractKinetics();
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addRequired(ip, 'dta', @(x) isa(x, 'mlpet.DTA'));
            addRequired(ip, 'tsc', @(x) isa(x, 'mlpet.TSC'));
            parse(ip, varargin{:});
            
            this.dta              = ip.Results.dta;
            this.tsc              = ip.Results.tsc;
            this.independentData  = {this.tsc.times};
            this.dependentData    = {this.tsc.specificActivity};
            [t,dtaBecq1,tscBecq1] = this.interpolateAll( ...
                this.dta.times, this.dta.specificActivity, this.tsc.times, this.tsc.specificActivity);
            this.dtaNyquist  = struct('times', t, 'specificActivity', dtaBecq1);
            this.tscNyquist  = struct('times', t, 'specificActivity', tscBecq1);
            this.dtaOnTsc         = struct('times', this.tsc.times, ...
                                           'specificActivity', pchip(this.dta.times, this.dta.specificActivity, this.tsc.times));
            
            this.expectedBestFitParams_ = ...
                [this.fu this.k1 this.k2 this.k3 this.k4 this.u0 this.v1]';
        end
        
        function this = simulateItsMcmc(this)
            this = mlraichle.F18DeoxyGlucoseKinetics.simulateMcmc( ...
                   this.dtaNyquist.specificActivity, this.fu, this.k1, this.k2, this.k3, this.k4, this.dtaNyquist.times, this.u0, this.v1, this.mapParams);
        end
        function a    = itsA(this)
            a = mlraichle.F18DeoxyGlucoseKinetics.a(this.k2, this.k3, this.k4);
        end
        function b    = itsB(this)
            b = mlraichle.F18DeoxyGlucoseKinetics.b(this.k2, this.k3, this.k4);
        end
        function q2   = itsQ2(this)
            q2 = mlraichle.F18DeoxyGlucoseKinetics.q2( ...
                this.dtaNyquist.specificActivity, this.k1, this.itsA, this.itsB, this.k4, this.tscNyquist.times);
        end
        function q3   = itsQ3(this)
            q3 = mlraichle.F18DeoxyGlucoseKinetics.q3( ...
                this.dtaNyquist.specificActivity, this.k1, this.itsA, this.itsB, this.k3, this.tscNyquist.times);
        end
        function qpet = itsQpet(this)
            import mlraichle.*;            
            tNyquist = this.tscNyquist.times;
            qNyquist = F18DeoxyGlucoseKinetics.qpet( ...
                this.dtaNyquist.specificActivity, this.fu, this.k1, this.k2, this.k3, this.k4, tNyquist, this.v1);
            qpet     = this.pchip(tNyquist, qNyquist, this.tsc.times, this.u0);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            this = this.runMcmc(ip.Results.mapParams, 'keysToVerify', {'fu' 'k1' 'k2' 'k3' 'k4' 'u0' 'v1'});
        end
        function ed   = estimateDataFast(this, fu, k1, k2, k3, k4, u0, v1)
            import mlraichle.*;            
            tNyquist = this.tscNyquist.times;
            qNyquist = F18DeoxyGlucoseKinetics.qpet( ...
                this.dtaNyquist.specificActivity, fu, k1, k2, k3, k4, tNyquist, v1);
            ed{1}    = this.pchip(tNyquist, qNyquist, this.tsc.times, u0);
        end
        function ps   = adjustParams(this, ps)
            theParams = this.theParameters;
            if (ps(theParams.paramsIndices('k4')) > ps(theParams.paramsIndices('k3')))
                tmp                               = ps(theParams.paramsIndices('k3'));
                ps(theParams.paramsIndices('k3')) = ps(theParams.paramsIndices('k4'));
                ps(theParams.paramsIndices('k4')) = tmp;
            end
        end
        
        function plot(this, varargin)
            figure;
            max_dta   = max(this.dta.specificActivity);
            max_data1 = max([max(this.tsc.specificActivity) max(this.itsQpet)]);
            plot(this.dta.times, this.dta.specificActivity/max_dta, ':o',  ...
                 this.times{1},  this.itsQpet       /max_data1, ...
                 this.tsc.times, this.tsc.specificActivity/max_data1, ':s', varargin{:});
            legend('data DTA', 'Bayesian TSC', 'data TSC');  
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('%s\nrescaled by %g, %g', this.yLabel,  max_dta, max_data1));
        end
        function plotParVars(this, par, vars)
            assert(lstrfind(par, properties(this)));
            assert(isnumeric(vars));
            switch (par)
                case 'k1'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.k2 this.k3 this.k4 this.u0 this.v1}; 
                    end
                case 'k2'
                    for v = 1:length(vars)
                        args{v} = { this.k1 vars(v) this.k3 this.k4 this.u0 this.v1}; 
                    end
                case 'k3'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 vars(v) this.k4 this.u0  this.v1}; 
                    end
                case 'k4'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 this.k3 vars(v) this.u0 this.v1}; 
                    end
                case 'u0'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 this.k3 this.k4 vars(v) this.v1};
                    end
                case 'v1'
                    for v = 1:length(vars)
                        args{v} = { this.k1 this.k2 this.k3 this.k4 this.u0 vars(v)}; 
                    end
            end
            this.plotParArgs(par, args, vars);
        end
 	end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlraichle.F18DeoxyGlucoseKinetics')));
            assert(iscell(args));
            assert(isnumeric(vars));
            figure
            hold on
            plot(this.dta.times, this.dta.specificActivity, ':o', ...
                 this.tsc.times, this.tsc.specificActivity, ':s');
            for v = 1:length(args)
                argsv = args{v};
                qpet  = mlraichle.F18DeoxyGlucoseKinetics.qpet( ...
                    this.dtaNyquist.specificActivity, argsv{1}, argsv{2}, argsv{3}, argsv{4}, this.tscNyquist.times, argsv{6});
                qpet  = this.pchip(this.tscNyquist.times, qpet, this.tscNyquist.times, argsv{5});
                plot(this.tscNyquist.times, qpet);
            end
            title(sprintf('k1 %g, k2 %g, k3 %g, k4 %g, u0 %g, v1 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            legend(['AIF' ...
                    cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false) ...
                    'WB']);
            xlabel('time / s');
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

