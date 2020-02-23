classdef MockScan < handle & mlraichle.Scan
	%% MOCKSCAN is intended for use by mlraichle.Test_DeviceKit.
    %  https://cnda.wustl.edu/app/action/DisplayItemAction/search_element/xnat%3AmrSessionData/search_field/xnat%3AmrSessionData.ID/search_value/CNDA_E262767/popup/false/project/CCIR_00559

	%  $Revision$
 	%  was created 18-Oct-2018 17:07:51 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (SetAccess = private)
        tracer = 'FDG'
 	end

	methods
        function dt = datetime(~)
            dt = datetime(2018, 10, 05, 15, 39, 03, 0, 'TimeZone', 'America/Chicago'); % calibration phantom
        end
		  
 		function this = MockScan(varargin)
 			%% MOCKSCAN
 			%  @param .
 			           
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'session', '', @(x) ischar(x) || isa(x, 'mlraichle.Session'));
            addParameter(ip, 'scanDetails', []);
            parse(ip, varargin{:});
            this.session_ = ip.Results.session;
            this.scanDetails_ = ip.Results.scanDetails;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

