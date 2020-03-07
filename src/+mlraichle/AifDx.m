classdef AifDx 
	%% AIFDX  

	%  $Revision$
 	%  was created 16-Aug-2018 17:42:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods (Static)
        function tbl = aiftbl(subjid, ~)
            tbl = readtable(fullfile( ...
                mlraichle.StudyRegistry.instance.subjectsDir, ...
                upper(subjid), ...
                'Vall', ...
                'mlsiemens_Herscovitch1985_constructTracerState_aif_fdgr1.csv'));
            t   = tbl.times(1:end);
            s   = tbl.specificActivity(1:end); % Bq/mL
            tbl = table(t, s, 'VariableNames', {'times' 'specificActivity'});
        end
        function tbl = tactbl(subjid, ~)
            tbl = readtable(fullfile( ...
                mlraichle.StudyRegistry.instance.subjectsDir, ...
                upper(subjid), ...
                'Vall', ...
                'mlsiemens_Herscovitch1985_plotScannerWholebrain_fdgr1_fdgr1.csv'));
            t   = tbl.times(end-19:end);
            s   = tbl.specificActivity(end-19:end); % Bq/mL
            tbl = table(t, s, 'VariableNames', {'times' 'specificActivity'});
        end
        function s = SUV(tbl, dose, wt, varargin)
            %  @param tbl has Vars in times/s, specificActivity/(Bq/mL)
            %  @param dose in Bq
            %  @param wt in kg
            %  @param newTimes in s is optional
            %  @return [kBq/mL]/([kBq]/[g])
            
            ip = inputParser;
            addOptional(ip, 'newTimes', [], @isnumeric);
            parse(ip, varargin{:});
            tbl.specificActivity = tbl.specificActivity/1000; % kBq
            wt = 1000*wt; % g
            dose = dose/1000; % kBq
            
            if (isempty(ip.Results.newTimes))
                T = tbl.times(end) - tbl.times(1);
                s = trapz(tbl.times, tbl.specificActivity) / T;
                s = s*wt/dose;
            else
                new_times_ = ip.Results.newTimes;
                new_specificActivity_ = pchip(tbl.times, tbl.specificActivity, new_times_);
                T = new_times_(end) - new_times_(1);
                s = trapz(new_times_, new_specificActivity_) / T;
                s = s*wt/dose;
            end
        end
    end
    
    methods
        function op = orderedPair(this)
            %  @return [kBq/mL]/([kBq]/[g])
            
            import mlraichle.AifDx.*;
            op = [SUV(this.aiftbl_, this.dose_, this.wt_, this.tactbl_.times) ...
                  SUV(this.tactbl_, this.dose_, this.wt_)];
        end
        function plot(this)
            plot(this.aiftbl_.times, this.aiftbl_.specificActivity, this.tactbl_.times, this.tactbl_.specificActivity);
            title(sprintf('%s V%i', this.subjid_, this.v_));
            xlabel('time / s');
            ylabel('specific activity / (Bq/mL)');
        end
        
 		function this = AifDx(varargin)
 			%% AIFDX
 			%  @param subjid.
 			%  @param v is numeric.
 			%  @param dose is mCi; stored as Bq.
 			%  @param wt is kg.

            ip = inputParser;
            addRequired(ip, 'subjid', @ischar);
            addRequired(ip, 'v', @isnumeric);
            addRequired(ip, 'dose', @isnumeric);
            addRequired(ip, 'wt', @isnumeric);
            parse(ip, varargin{:});
            
            this.subjid_ = ip.Results.subjid;
            this.v_      = ip.Results.v;
            this.dose_   = 37e6*ip.Results.dose; % Bq
            this.wt_     = ip.Results.wt; % kg
            this.aiftbl_ = this.aiftbl(this.subjid_, this.v_);
            this.tactbl_ = this.tactbl(this.subjid_, this.v_);
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        subjid_
        v_
        dose_
        wt_        
        aiftbl_
        tactbl_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

