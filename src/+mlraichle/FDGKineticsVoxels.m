classdef FDGKineticsVoxels < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSVOXELS  

	%  $Revision$
 	%  was created 17-Feb-2017 07:22:19
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = FDGKineticsVoxels(varargin)
 			%% FDGKINETICSVOXELS
 			%  Usage:  this = FDGKineticsVoxels()

 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

