classdef SynthSessionData < mlraichle.SessionData
	%% SYNTHSESSIONDATA  

	%  $Revision$
 	%  was created 06-Dec-2016 19:31:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = SynthSessionData(varargin)
 			%% SYNTHSESSIONDATA
 			%  Usage:  this = SynthSessionData()

 			this = this@mlraichle.SessionData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

