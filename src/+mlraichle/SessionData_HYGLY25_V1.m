classdef SessionData_HYGLY25_V1 < mlraichle.SessionData
	%% SESSIONDATA_HYGLY25_V1  

	%  $Revision$
 	%  was created 29-Apr-2018
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab R2018a for MACI64.
    
    methods
 		function this = SessionData_HYGLY25_V1(varargin)
 			this = this@mlraichle.SessionData(varargin{:});
            
            this.taus_FDG_NAC_ = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60];
            % length -> 57
            this.taus_FDG_AC_ = [10,10,10,10,10,10,10,10,10,10,10,10,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60];
            % length -> 65
        end
    end
        
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

