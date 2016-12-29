classdef FdgDirector 
	%% FDGDIRECTOR  

	%  $Revision$
 	%  was created 26-Dec-2016 12:49:55
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        fdgBuilder
 		parCluster
 	end

	methods 
		  
 		function this = FdgDirector(varargin)
 			%% FDGDIRECTOR
 			%  Usage:  this = FdgDirector()

 			this.parCluster = mlraichle.ParCluster;
        end
        
        function resolve(this, varargin)
            %% RESOLVE
            %  @param revisions is numeric, e.g., 1, 2, [1 2].
            
            ip = inputParser;
            addParameter(ip, 'revisions', 1, @isnumeric);
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlraichle.SessionData'));
            parse(ip, varargin{:});            
            
            sessd = ip.Results.sessionData;
            for r = 1:length(ip.Results.revisions)
                sessd.rnumber = r;
                this.fdgBuilder = mlraichle.FdgBuilder('sessionData', sessd);
                this.fdgBuilder.resolve;
            end
        end
        
        function pushDataToCluster(this, varargin)
            this.parCluster.pushDir();
        end
        function resolveOnCluster(this, varargin)
            this.parCluster.resolve;
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

