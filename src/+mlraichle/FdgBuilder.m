classdef FdgBuilder < mlfourdfp.AbstractTracerResolveBuilder
	%% FDGBUILDER  

	%  $Revision$
 	%  was created 11-Dec-2016 22:13:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

    methods (Static)
        function tf = completed(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            this = mlraichle.FdgBuilder('sessionData', sessd);
            tf = lexist(this.completedTouchFile, 'file');
        end
    end
    
	methods 
		  
 		function this = FdgBuilder(varargin)
 			%% FdgBuilder
 			%  Usage:  this = FdgBuilder()

 			this = this@mlfourdfp.AbstractTracerResolveBuilder(varargin{:});
        end
        
        function resolveMpr(this)
            
        end
        function printSessionData(this)
            mlraichle.FdgBuilder.printv('FdgBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

