classdef TracerDirector < mlpet.TracerDirector
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 27-Sep-2017 02:38:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	methods (Static)
        
        %% factory methods        
        
        function this  = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));              
            this = this.instanceConstructResolved;
        end 
        function this  = constructResolvedRemotely(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instanceConstructResolvedRemotely( ...
                @mlraichle.SessionData, @mlraichle.TracerDirector.constructResolved);
        end 
        function this  = pullFromRemote(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instancePullFromRemote;
        end 
        function out   = cleanRemote(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this.instanceCleanRemote;
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
    end
    
    methods
        
        %%
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  Usage:  this = TracerDirector()

 			this = this@mlpet.TracerDirector(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

