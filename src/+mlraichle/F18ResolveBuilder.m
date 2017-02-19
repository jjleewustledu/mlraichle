classdef F18ResolveBuilder < mlfourdfp.AbstractTracerResolveBuilder
	%% F18RESOLVEBUILDER  

	%  $Revision$
 	%  was created 11-Dec-2016 22:13:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

    methods (Static)
        function tf    = completed(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            this = mlraichle.F18ResolveBuilder('sessionData', sessd);
            tf = lexist(this.completedTouchFile, 'file');
        end
    end
    
	methods 
		  
 		function this = F18ResolveBuilder(varargin)
 			%% F18RESOLVEBUILDER
 			%  Usage:  this = F18ResolveBuilder()

 			this = this@mlfourdfp.AbstractTracerResolveBuilder(varargin{:});
 		end
        function printSessionData(this)
            mlraichle.F18ResolveBuilder.printv('F18ResolveBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

