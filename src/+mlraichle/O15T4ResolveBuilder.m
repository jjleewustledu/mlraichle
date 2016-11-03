classdef O15T4ResolveBuilder < mlfourdfp.T4ResolveBuilder
	%% O15T4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 27-Oct-2016 22:21:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods		  
 		function this = O15T4ResolveBuilder(varargin)
 			%% O15T4RESOLVEBUILDER
 			%  Usage:  this = O15T4ResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
 		end
        function this = locallyStage15O(this)
            this.prepare15ONACLocation;         
            this.build15ONAC;
            this.prepareMR;
            this.scp15O;
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

