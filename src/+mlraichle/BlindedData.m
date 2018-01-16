classdef BlindedData < mlglucose.BlindedData
	%% BLINDEDDATA  

	%  $Revision$
 	%  was created 05-Dec-2017 21:11:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		% CBC
        
        % CO-oximetry
        
 	end

	methods 
		  
 		function this = BlindedData(varargin)
 			%% BLINDEDDATA
 			%  @params named sessionData is an mlraichle.SessionData.

 			this = thismlglucose.BlindedData;
            ip = inputParser;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

