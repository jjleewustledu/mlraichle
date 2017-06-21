classdef XlsxObjScanData 
	%% XLSXOBJSCANDATA  

	%  $Revision$
 	%  was created 11-Jun-2017 15:36:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        clockDurationOffsets
        dose
        doseAdminDatetime        
        
        capracHeader
        fdg
        oo
        tracerAdmin
        clocks
        cyclotron
        phantom
        capracCalibration
        twilite
        mmr
        pmod
        timingData
    end
    
    methods (Static)
        function dt = datetime(varargin)
            for v = 1:length(varargin)
                if (ischar(varargin{v}))
                    try
                        varargin{v} = datetime(varargin{v}, 'InputFormat', 'HH:mm:ss', 'TimeZone', 'local');
                    catch ME
                        handwarning(ME);
                        varargin{v} = datetime(varargin{v}, 'InputFormat', 'HH:mm', 'TimeZone', 'local');
                    end
                end
                dt = datetime(varargin{v}, 'ConvertFrom', 'excel1904', 'TimeZone', 'local');
                dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
                dt = mlraichle.XlsxObjScanData.offsetDate(dt, 4, 0, 1);
            end
        end
        function d  = getDate(dt)
            if (~isa(dt, 'datetime'))
                dt = mlraichle.XlsxObjScanData.datetime(dt);
            end
            d.Year  = dt.Year;
            d.Month = dt.Month;
            d.Day   = dt.Day;
        end
        function dt = offsetDate(dt, Y,M,D)
            dt.Year  = dt.Year + Y;
            dt.Month = dt.Month + M;
            dt.Day   = dt.Day + D;
            dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
        function dt = setDate(dt, d)
            if (~isa(dt, 'datetime'))
                dt = mlraichle.XlsxObjScanData.datetime(dt);
            end
            dt.Year  = d.Year;
            dt.Month = d.Month;
            dt.Day   = d.Day;
            dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.clockDurationOffsets(this)
            c = this.clocks{:,'TimeOffsetWrtNTS____s'};
            s = sign(c);
            c = this.datetime(abs(c));            
            c.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            d = this.datetime(0);
            d.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            g = s.*duration(c - d);
        end    
        
        function g = get.capracHeader(this)
            g = this.capracHeader_;
        end
        function g = get.fdg(this)
            g = this.fdg_;
        end
        function g = get.oo(this)
            g = this.oo_;
        end
        function g = get.tracerAdmin(this)
            g = this.tracerAdmin_;
        end
        function g = get.clocks(this)
            g = this.clocks_;
        end
        function g = get.cyclotron(this)
            g = this.cyclotron_;
        end
        function g = get.phantom(this)
            g = this.phantom_;
        end
        function g = get.capracCalibration(this)
            g = this.capracCalibration_;
        end
        function g = get.twilite(this)
            g = this.twilite_;
        end
        function g = get.mmr(this)
            g = this.mmr_;
        end
        function g = get.pmod(this)
            g = this.pmod_;
        end
        function g = get.timingData(this)
            g = this.timingData_;
        end
        
        %%
        
        function dt = datetimes(this, varargin)
            dt = this.fdg.TIMEDRAWN_Hh_mm_ss;
            dt = dt(this.fdgValid_);
            dt = dt - this.clockDurationOffsets(5);
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            warning('off', 'MATLAB:table:ModifiedVarnames');            
            this.capracHeader_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Table 1', 'FileType', 'spreadsheet');            
            this.fdg_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true); 
            this.oo_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true); 
            this.tracerAdmin_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true); 
            this.clocks_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.cyclotron_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.phantom_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.capracCalibration_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.twilite_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-1-', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.mmr_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-11', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.pmod_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-12', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            warning('on', 'MATLAB:table:ModifiedVarnames');
            
            % only the dates in tradmin are assumed correct;
            % spreadsheets auto-fill datetime cells with the date of data entry
            % which is typically not the date of measurement
            
            this.timingData_.datetime0 = this.datetime(this.tracerAdmin_{1, 'ADMINistrationTime_Hh_mm_ss'});
            this.fdg_.TIMEDRAWN_Hh_mm_ss = ...
                this.replaceDate( ...
                    this.datetime(this.fdg_.TIMEDRAWN_Hh_mm_ss));
            this.oo_.TIMEDRAWN_Hh_mm_ss = ...
                this.replaceDate( ...
                    this.datetime(this.oo_.TIMEDRAWN_Hh_mm_ss));
            this.fdgValid_ = ~isnat(this.fdg_.TIMEDRAWN_Hh_mm_ss) & ...
                                 strcmp(this.fdg_.TRACER, '[18F]DG');
            this.ooValid_ = ~isnat(this.oo_.TIMEDRAWN_Hh_mm_ss) & ...
                                 strcmp(this.oo_.TRACER, '[18F]DG');
        end
 		function this = XlsxObjScanData(varargin)
 			%% XLSXOBJSCANDATA
 			%  Usage:  this = XlsxObjScanData()

 			ip = inputParser;
            addParameter(ip, 'filename', '', @(x) lexist(x, 'file'));
            addParameter(ip, 'tracer', '', @ischar);
            addParameter(ip, 'snumber', nan, @isnumeric);
            parse(ip, varargin{:});            
            
            this.timingData_ = mldata.TimingData;
 			this = this.readtable(ip.Results.filename); 
            this.timingData_ = this.updatedTimingData;
            
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        capracHeader_
        fdg_
        oo_
        tracerAdmin_
        clocks_
        cyclotron_
        phantom_
        capracCalibration_
        twilite_
        mmr_
        pmod_
        timingData_
        fdgValid_
        ooValid_
    end
    
    methods (Access = private)
        function dt = replaceDate(this, dt)
            dt0 = this.timingData_.datetime0;
            dt = this.setDate(dt, dt0);
        end
        function t  = tableCaprac2times(this)
            t = seconds(this.datetimes - this.datetimes(1));
            t = ensureRowVector(t);
        end
        function td = updatedTimingData(this)
            td           = this.timingData_;
            td.times     = this.tableCaprac2times;
            td.datetime0 = this.setDate(td.datetime0, this.getDate(this.datetimes(1)));
            td.dt        = min(td.taus);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

