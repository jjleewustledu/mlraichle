classdef O15CResolveBuilder < mlfourdfp.MMRResolveBuilder
	%% O15CRESOLVEBUILDER  

	%  $Revision$
 	%  was created 22-Nov-2016 21:45:53
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties 		
        recoverNACFolder = false 
 	end

	methods
 		function this = O15CResolveBuilder(varargin)
 			%% O15CRESOLVEBUILDER
 			%  Usage:  this = O15CResolveBuilder()

 			this = this@mlfourdfp.MMRResolveBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

