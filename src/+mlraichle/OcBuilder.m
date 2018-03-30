classdef OcBuilder < mlpet.TracerKineticsBuilder
	%% OCBUILDER  

	%  $Revision$
 	%  was created 30-May-2017 16:52:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = OcBuilder(varargin)
 			%% OCBUILDER
 			%  Usage:  this = OcBuilder()

 			this = this@mlpet.TracerKineticsBuilder(varargin{:});
            this.sessionData_.tracer = 'OC';
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

