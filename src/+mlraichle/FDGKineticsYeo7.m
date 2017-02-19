classdef FDGKineticsYeo7 < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSYEO7  

	%  $Revision$
 	%  was created 17-Feb-2017 07:20:38
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = FDGKineticsYeo7(varargin)
 			%% FDGKINETICSYEO7
 			%  Usage:  this = FDGKineticsYeo7()

 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

