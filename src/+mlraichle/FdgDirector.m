classdef FdgDirector < mlraichle.TracerDirector
	%% FDGDIRECTOR  

	%  $Revision$
 	%  was created 26-Dec-2016 12:49:55
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        fdgBuilder
    end
    
    properties (Dependent)
        framesPartitions
    end
    
    methods %% GET
        function g = get.framesPartitions(this)
            g = this.fdgBuilder.framesPartitions;
        end
    end
    
	methods 
		  
 		function this = FdgDirector(varargin)
 			%% FDGDIRECTOR
 			%  Usage:  this = FdgDirector()
            
        end
        
        function this = buildResolvedACFrames(this)
            assert(this.e7Tools.acCompleted);            
            for p = 1:length(this.framesPartitions)
                this.frames = this.framesPartitions{p};
                this.t4imgsACFrames;
                this.pasteACFrames;
                this.sumACFrames;  
            end
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

