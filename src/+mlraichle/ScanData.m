classdef ScanData < mlsiemens.ScanData
	%% SCANDATA  

	%  $Revision$
 	%  was created 11-Jun-2017 12:57:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
 		tube
        timeDrawn
        timeCounted
        Ge68
        massSample
        apertureCorrGe68
        decayApertureCorrGe68
        
        cyclotronSyringeDose
        cyclotronCapDose
        cyclotronNetDoseTime
        cyclotronNetDose
        phantomNetVolume
        phantomDecayCorrSpecificActivity  
        wellCountTimeDrawn
        wellCountTimeCounted
        wellCountGe68
        wellCountMassSample
        wellCountApertureCorrGe68
        wellCountDecayApertureCorrGe68
        wellCountDecayCorrSpecificActivity
        aifCountCatheterType
        aifCountLoadedCounts
        aifCountDecayCorrSpecificActivity
        scannerStartTime              
        scannerDecayCorrSpecificActivity
 	end

	methods 
		  
 		function this = ScanData(varargin)
 			%% SCANDATA
 			%  Usage:  this = ScanData()

 			this = this@mlsiemens.ScanData(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'manualData', [], @(x) ~isempty(x));
            parse(ip, varargin{:});
            
            if (isempty(this.manualData_))
                this.manualData_ = mlsiemens.XlsxObjScanData( ...
                    'filename', this.sessionData.CCIRRadMeasurements, ...
                    'tracer', this.sessionData.tracer, ...
                    'snumber', this.sesssionData.snumber);
            end
            if (isempty(this.scannerData_))
                this.scannerData_ = BiographMMR( ...
                    this.sessionData.tracerRevision('typ', 'niftid'), ...
                    'sessionData', this.sessionData, ...
                    'consoleClockOffset', -duration(0,0,7), ...
                    'doseAdminDatetime', this.doseAdminDatetimeHO); % TODO:  use sessionData to collect ancillary info.
                this.scannerData_.time0 = 0;
                switch (this.sessionData.tracer)
                    case {'HO' 'OO'}
                        this.scannerData_.timeDuration = 60;
                    case {'OC'}
                        this.scannerData_.timeDuration = 180;
                    otherwise
                end
                this.scannerData_.dt = 1;
            end            
            if (isempty(this.aifData_))
                this.aifData_ = Twilite( ...
                    'scannerData', scanner, ...
                    'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                    'invEfficiency', 0.5*147.95, ...
                    'aifTimeShift', -20);
            end
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

