classdef MockSession < handle & mlraichle.Session
	%% MOCKSESSION  

	%  $Revision$
 	%  was created 18-Oct-2018 18:16:12 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (SetAccess = private)
        snumber = 1
 	end

	methods 
        function dt = datetime(~)
            dt = datetime(2018, 10, 05, 10, 22, 06, 847, 'TimeZone', 'America/Chicago'); % study time in MR DICOMs
        end
		  
 		function this = MockSession(varargin)
 			%% MOCKSESSION
 			%  @param .

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'subject', '', @(x) ischar(x) || isa(x, 'mlraichle.Subject'));
            addParameter(ip, 'sessionDetails', []);
            parse(ip, varargin{:});
            this.subject_ = ip.Results.subject;
            this.sessionDetails_ = ip.Results.sessionDetails;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

